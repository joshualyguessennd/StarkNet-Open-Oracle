import json
from starknet_py.contract import Contract
from typing import Union
from client_tools import fetch_coinbase, fetch_okx, prepare_contract_call_args
from empiric.core.base_client import EmpiricBaseClient, EmpiricAccountClient
from empiric.core.types import HEX_STR


class OpenOracleClient(EmpiricBaseClient):
    def __init__(
        self,
        open_oracle_address: HEX_STR,
        account_contract_address: Union[int, HEX_STR],
        account_private_key: int,
    ):
        super().__init__(
            account_private_key=account_private_key,
            account_contract_address=account_contract_address,
        )

        # Overwrite account_client with timestamp-based nonce
        self.account_client = EmpiricAccountClient(
            self.account_contract_address, self.client, self.signer
        )
        # OpenOracle contract
        open_oracle_abi = open("build/OpenOraclePublisher_abi.json", "r")
        self.open_oracle_contract = Contract(
            address=open_oracle_address,
            abi=json.load(open_oracle_abi),
            client=self.client,
        )
        open_oracle_abi.close()

    async def _fetch_contracts(self):
        pass

    async def publish_open_oracle_entries_okx(
        self, assets=["btc", "eth", "dai"]
    ) -> hex:
        okx_oracle_data = fetch_okx(assets=assets)
        calls = [
            self.open_oracle_contract.functions["publish_entry"].prepare(
                prepare_contract_call_args(*oracle_data)
            )
            for oracle_data in okx_oracle_data
        ]

        return await self.send_transactions(calls=calls)

    async def publish_open_oracle_entries_okx_sequential(self, assets=["btc", "eth"]):
        okx_oracle_data = fetch_okx(assets=assets)
        calls = [
            self.open_oracle_contract.functions["publish_entry"].prepare(
                prepare_contract_call_args(*oracle_data)
            )
            for oracle_data in okx_oracle_data
        ]
        results = {
            "OKX:"
            + asset_call[0].upper(): await self.send_transactions(calls=[asset_call[1]])
            for asset_call in zip(assets, calls)
        }
        return results

    async def publish_open_oracle_entries_coinbase(
        self, assets=["btc", "eth", "dai"]
    ) -> hex:
        coinbase_oracle_data = fetch_coinbase(assets=assets)
        calls = [
            self.open_oracle_contract.functions["publish_entry"].prepare(
                prepare_contract_call_args(*oracle_data)
            )
            for oracle_data in coinbase_oracle_data
        ]

        return await self.send_transactions(calls=calls)

    async def publish_open_oracle_entries_coinbase_sequential(
        self, assets=["btc", "eth"]
    ):
        coinbase_oracle_data = fetch_coinbase(assets=assets)
        calls = [
            self.open_oracle_contract.functions["publish_entry"].prepare(
                prepare_contract_call_args(*oracle_data)
            )
            for oracle_data in coinbase_oracle_data
        ]
        results = {
            "Coinbase:"
            + asset_call[0].upper(): await self.send_transactions(calls=[asset_call[1]])
            for asset_call in zip(assets, calls)
        }
        return results

    async def publish_open_oracle_entries_all_publishers(
        self, assets=["btc", "eth", "dai"]
    ) -> hex:
        okx_oracle_data = fetch_okx(assets=assets)
        coinbase_oracle_data = fetch_coinbase(assets=assets)
        all_data = okx_oracle_data + coinbase_oracle_data

        calls = [
            self.open_oracle_contract.functions["publish_entry"].prepare(
                prepare_contract_call_args(*oracle_data)
            )
            for oracle_data in all_data
        ]
        return await self.send_transactions(calls=calls)

    async def publish_open_oracle_entries_all_publishers_sequential(
        self, assets=["btc", "eth", "dai"]
    ) -> hex:
        results_okx = await self.publish_open_oracle_entries_okx_sequential(assets)
        results_cb = await self.publish_open_oracle_entries_coinbase_sequential(assets)
        results = {**results_okx, **results_cb}
        return results
