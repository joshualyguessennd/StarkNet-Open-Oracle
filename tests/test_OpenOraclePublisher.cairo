%lang starknet
from contracts.OpenOraclePublisher import OpenOracleEntry, Entry, IOracleController
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.cairo_builtins import BitwiseBuiltin

@external
func __setup__():
    %{ context.contract_a_address = deploy_contract("./contracts/OpenOraclePublisher.cairo").contract_address %}
    return ()
end

@contract_interface
namespace OpenOraclePublisher:
    func publish_entry(entry : OpenOracleEntry):
    end
    func update_empiric_oracle_controller_address(new_contract_address : felt):
    end
    func get_admin_address() -> (admin_address : felt):
    end
    func get_empiric_oracle_controller_address() -> (address : felt):
    end
end

@external
func test_publish_entry_fail_if_untrusted_signer{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals
    tempvar contract_address
    %{ ids.contract_address = context.contract_a_address %}

    local entry : OpenOracleEntry
    assert entry.t_little = 0
    assert entry.p_little = 0
    assert entry.ticker_len_little = 0
    assert entry.ticker_name_little = 0
    assert entry.r_low = 0
    assert entry.r_high = 0
    assert entry.s_low = 0
    assert entry.s_high = 0
    assert entry.v = 0
    assert entry.eth_address = 0

    %{ expect_revert(error_message="does not come from OpenOracle trusted signers") %}

    OpenOraclePublisher.publish_entry(contract_address=contract_address, entry=entry)

    return ()
end

@external
func test_publish_entry_fail_if_unspported_asset{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals
    tempvar contract_address
    %{ ids.contract_address = context.contract_a_address %}

    local entry : OpenOracleEntry
    assert entry.t_little = 0
    assert entry.p_little = 0
    assert entry.ticker_len_little = 0
    assert entry.ticker_name_little = 0
    assert entry.r_low = 0
    assert entry.r_high = 0
    assert entry.s_low = 0
    assert entry.s_high = 0
    assert entry.v = 0
    assert entry.eth_address = 761466874539515783303110363281120649054760260892

    %{ expect_revert(error_message="ticker name is not supported") %}
    OpenOraclePublisher.publish_entry(contract_address=contract_address, entry=entry)

    return ()
end

@external
func test_publish_entry_fail_if_wrong_message_or_signature{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals
    tempvar contract_address
    %{ ids.contract_address = context.contract_a_address %}
    local entry : OpenOracleEntry

    assert entry.t_little = 0
    assert entry.p_little = 0
    assert entry.ticker_len_little = 0
    assert entry.ticker_name_little = 'CTB'
    assert entry.r_low = 0
    assert entry.r_high = 0
    assert entry.s_low = 0
    assert entry.s_high = 0
    assert entry.v = 0
    assert entry.eth_address = 761466874539515783303110363281120649054760260892

    %{ expect_revert(error_message="Signature verification for the OpenOracleEntry provided failed") %}
    OpenOraclePublisher.publish_entry(contract_address=contract_address, entry=entry)

    return ()
end

@external
func test_update_empiric_oracle_controller_address_fail_if_not_admin{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals
    tempvar contract_address
    %{ ids.contract_address = context.contract_a_address %}
    %{ expect_revert(error_message="Called by non-admin contract") %}

    OpenOraclePublisher.update_empiric_oracle_controller_address(contract_address, 123456)

    return ()
end

@external
func test_update_empiric_oracle_controller_address_works_if_admin{
    syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
}():
    alloc_locals
    tempvar contract_address
    %{ ids.contract_address = context.contract_a_address %}
    let (local admin_address) = OpenOraclePublisher.get_admin_address(contract_address)
    %{ stop_prank = start_prank(ids.admin_address, target_contract_address=ids.contract_address) %}

    OpenOraclePublisher.update_empiric_oracle_controller_address(contract_address, 123456)
    let (
        local new_oracle_controller_address
    ) = OpenOraclePublisher.get_empiric_oracle_controller_address(contract_address)

    assert new_oracle_controller_address = 123456
    return ()
end

# Basic test to copy and paste
#
# @external
# func test{
#     syscall_ptr : felt*, range_check_ptr, pedersen_ptr : HashBuiltin*, bitwise_ptr : BitwiseBuiltin*
# }():
#     alloc_locals
#     tempvar contract_address
#     %{ ids.contract_address = context.contract_a_address %}

# return ()
# end
