%lang starknet

@contract_interface
namespace IOpenOraclePublisher:
    func get_all_public_keys() -> (public_keys_len : felt, public_keys : felt*):
    end

    func get_empiric_oracle_controller_address() -> (address : felt):
    end

    func get_empiric_admin_address() -> (admin_address : felt):
    end

    func update_empiric_oracle_controller_address(new_contract_address : felt):
    end

    func update_empiric_admin_address():
    end

    func publish_entry(entry : OpenOracleEntry):
    end
end
