%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from contracts.library import verify_oracle_message, word_reverse_endian_64

struct OpenOracleEntry:
    member t_little : felt
    member p_little : felt
    member ticker_len_little : felt
    member ticker_name_little : felt
    member r_low : felt
    member r_high : felt
    member s_low : felt
    member s_high : felt
    member v : felt
    member eth_address : felt
end

struct Entry:
    member key : felt  # UTF-8 encoded lowercased string, e.g. "eth/usd"
    member value : felt
    member timestamp : felt
    member source : felt
    member publisher : felt
end

@contract_interface
namespace IOracleController:
    func publish_entry(entry : Entry):
    end
end

@storage_var
func trusted_signers_addresses(index : felt) -> (eth_address : felt):
end

@storage_var
func trusted_signers_names_by_address(eth_address : felt) -> (trusted_signer_name : felt):
end

@storage_var
func ticker_name_little_to_empiric_key(ticker_name : felt) -> (key : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    trusted_signers_addresses.write(index=0, value=761466874539515783303110363281120649054760260892)
    trusted_signers_addresses.write(
        index=1, value=1443903124408663179676923566941061880487545664188
    )

    trusted_signers_names_by_address.write(
        eth_address=761466874539515783303110363281120649054760260892, value='Okex'
    )
    trusted_signers_names_by_address.write(
        eth_address=1443903124408663179676923566941061880487545664188, value='Coinbase'
    )

    ticker_name_little_to_empiric_key.write(ticker_name=4412482, value='btc/usd')  # BTC
    ticker_name_little_to_empiric_key.write(ticker_name=4740165, value='eth/usd')  # ETH
    ticker_name_little_to_empiric_key.write(ticker_name=4800836, value='dai/usd')  # DAI

    return ()
end

@view
func get_signer_address_at_index{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    index : felt
) -> (eth_address : felt):
    let (eth_address) = trusted_signers_addresses.read(index)
    return (eth_address)
end

@external
func publish_entry{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*
}(entry : OpenOracleEntry):
    alloc_locals
    let proposed_eth_address = entry.eth_address
    let (publisher_name) = trusted_signers_names_by_address.read(eth_address=proposed_eth_address)

    with_attr error_message(
            "The Ethereum address that supposedly signed this message does not come from OpenOracle trusted signers"):
        if publisher_name == 0:
            # If the address is not known in the contract storage, just fail with an impossible assert statement.
            assert 0 = 1
        end
    end

    let ticker_name_little = entry.ticker_name_little
    let (key) = ticker_name_little_to_empiric_key.read(ticker_name_little)

    with_attr error_message("This ticker name is not supported by Empiric Network"):
        if key == 0:
            assert 0 = 1
        end
    end

    with_attr error_message("Signature verification for the OpenOracleEntry provided failed"):
        verify_oracle_message(
            entry.t_little,
            entry.p_little,
            entry.ticker_len_little,
            entry.ticker_name_little,
            entry.r_low,
            entry.r_high,
            entry.s_low,
            entry.s_high,
            entry.v,
            entry.eth_address,
        )
    end

    let (price) = word_reverse_endian_64(entry.p_little)
    let (timestamp) = word_reverse_endian_64(entry.t_little)

    local oracle_controller_entry : Entry

    assert oracle_controller_entry.key = key
    assert oracle_controller_entry.value = price
    assert oracle_controller_entry.timestamp = timestamp
    assert oracle_controller_entry.source = 'OpenOracle'
    assert oracle_controller_entry.publisher = publisher_name

    # Todo : call publish_entry of OracleController here

    IOracleController.publish_entry(contract_address=123, entry=oracle_controller_entry)

    return ()
end
