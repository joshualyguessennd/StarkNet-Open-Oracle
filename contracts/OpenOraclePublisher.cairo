%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin, HashBuiltin
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import get_caller_address

from contracts.library import verify_oracle_message, word_reverse_endian_64, OpenOracleEntry, Entry

@contract_interface
namespace IOracleController:
    func publish_entry(entry : Entry):
    end
    func get_decimals(key : felt) -> (decimals : felt):
    end
    func get_admin_address() -> (admin_address : felt):
    end
end

@storage_var
func empiric_oracle_controller_address() -> (address : felt):
end
@storage_var
func empiric_admin_address() -> (address : felt):
end
@storage_var
func trusted_signers_addresses(index : felt) -> (eth_address : felt):
end
@storage_var
func trusted_signers_addresses_len() -> (len : felt):
end
@storage_var
func trusted_signers_names_by_address(eth_address : felt) -> (trusted_signer_name : felt):
end
@storage_var
func ticker_name_little_to_empiric_key(ticker_name : felt) -> (key : felt):
end
@storage_var
func decimals_cache(oracle_address, key) -> (decimals : felt):
end

@view
func get_all_trusted_signers_addresses{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (trusted_eth_addresses_len : felt, trusted_eth_addresses : felt*):
    alloc_locals
    let (local len) = trusted_signers_addresses_len.read()
    let (trusted_eth_addresses : felt*) = alloc()

    get_all_trusted_signers_loop(trusted_eth_addresses, 0, len)

    return (len, trusted_eth_addresses)
end

func get_all_trusted_signers_loop{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(array : felt*, index : felt, max : felt):
    if index == max:
        return ()
    end
    let (eth_address) = trusted_signers_addresses.read(index)
    assert [array] = eth_address

    get_all_trusted_signers_loop(array + 1, index + 1, max)
    return ()
end

@view
func get_empiric_oracle_controller_address{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}() -> (address : felt):
    let (oracle_controller_address) = empiric_oracle_controller_address.read()
    return (oracle_controller_address)
end
@view
func get_admin_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    admin_address : felt
):
    let (admin_address) = empiric_admin_address.read()
    return (admin_address)
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    trusted_signers_addresses.write(index=0, value=761466874539515783303110363281120649054760260892)
    trusted_signers_addresses.write(
        index=1, value=1443903124408663179676923566941061880487545664188
    )

    trusted_signers_addresses_len.write(2)

    trusted_signers_names_by_address.write(
        eth_address=761466874539515783303110363281120649054760260892, value='Okex'
    )
    trusted_signers_names_by_address.write(
        eth_address=1443903124408663179676923566941061880487545664188, value='Coinbase'
    )

    ticker_name_little_to_empiric_key.write(ticker_name=4412482, value='btc/usd')  # BTC
    ticker_name_little_to_empiric_key.write(ticker_name=4740165, value='eth/usd')  # ETH
    ticker_name_little_to_empiric_key.write(ticker_name=4800836, value='dai/usd')  # DAI

    empiric_oracle_controller_address.write(
        value=0x012fadd18ec1a23a160cc46981400160fbf4a7a5eed156c4669e39807265bcd4
    )

    # let (admin_address) = IOracleController.get_admin_address(
    #     contract_address=0x012fadd18ec1a23a160cc46981400160fbf4a7a5eed156c4669e39807265bcd4
    # )
    # empiric_admin_address.write(value=admin_address)

    empiric_admin_address.write(
        value=0x0704cc0f2749637a0345d108ac9cd597bb33ccf7f477978d52e236830812cd98
    )
    return ()
end

func only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (caller_address) = get_caller_address()
    let (admin_address) = empiric_admin_address.read()
    with_attr error_message("Admin: Called by non-admin contract"):
        assert caller_address = admin_address
    end
    return ()
end

# Only empiric admin can call this function to update Oracle Controller address if it has changed.
@external
func update_empiric_oracle_controller_address{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(new_contract_address : felt):
    only_admin()
    empiric_oracle_controller_address.write(new_contract_address)
    return ()
end

# Anyone can call this function to make sure the admin of the Oracle Controller and the admin of this contract are synced.
@external
func update_admin_address{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (oracle_controller_address) = empiric_oracle_controller_address.read()
    let (admin_address) = IOracleController.get_admin_address(
        contract_address=oracle_controller_address
    )
    empiric_admin_address.write(admin_address)
    return ()
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

    let (decimals) = get_or_update_from_decimals_cache(key=key)
    let (multiplier) = pow(10, decimals - 6)
    let price = price * multiplier

    local oracle_controller_entry : Entry

    assert oracle_controller_entry.key = key
    assert oracle_controller_entry.value = price
    assert oracle_controller_entry.timestamp = timestamp
    assert oracle_controller_entry.source = 'OpenOracle'
    assert oracle_controller_entry.publisher = publisher_name

    let (controller_address) = empiric_oracle_controller_address.read()

    IOracleController.publish_entry(
        contract_address=controller_address, entry=oracle_controller_entry
    )

    return ()
end

func get_or_update_from_decimals_cache{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(key : felt) -> (decimals : felt):
    let (oracle_controller_address) = empiric_oracle_controller_address.read()
    let (decimals) = decimals_cache.read(oracle_controller_address, key)
    if decimals == 0:
        let (controller_address) = empiric_oracle_controller_address.read()
        let (new_decimals) = IOracleController.get_decimals(
            contract_address=controller_address, key=key
        )
        decimals_cache.write(oracle_address=oracle_controller_address, key=key, value=new_decimals)
        return (new_decimals)
    end
    return (decimals)
end
