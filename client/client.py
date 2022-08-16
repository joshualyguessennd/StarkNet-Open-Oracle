import json
import os
import asyncio
from starkware.starknet.public.abi import get_selector_from_name
from starknet_py.net.signer.stark_curve_signer import KeyPair, StarkCurveSigner
from starknet_py.net.networks import MAINNET, TESTNET
from starknet_py.net.models import StarknetChainId
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.client_models import Call
from starknet_py.net import AccountClient
from starknet_py.contract import Contract
from starknet_py.net.networks import TESTNET
from dotenv import load_dotenv
from client_tools import fetch_coinbase, fetch_okex, prepare_contract_call_args


load_dotenv()

OPEN_ORACLE_ADDRESS = '0x01e02f5a90dd2071287160b5b3ee60e6c5b12f4be91c4e4caf424172efc53f1b'
NETWORK = TESTNET


class OpenOracleClient(object):
    def __init__(
        self,
        account_private_key=int(os.getenv('ACCOUNT_PRIVATE_KEY')),
        account_contract_address=os.getenv('ACCOUNT_CONTRACT_ADDRESS'),
        open_oracle_address=OPEN_ORACLE_ADDRESS,
        network=NETWORK
    ):
        if network == TESTNET:
            self.chain_id = StarknetChainId.TESTNET
        elif network == MAINNET:
            self.chain_id = StarknetChainId.MAINNET
        else:
            raise NotImplementedError(
                "Empiric.BaseClient: Network not recognized, unknown Chain ID"
            )
        self.network = network
        self.client = GatewayClient(self.network)

        # Account contract and signer
        self.account_contract_address = account_contract_address
        self.account_contract = None
        self.account_private_key = account_private_key
        self.signer = StarkCurveSigner(self.account_contract_address, KeyPair.from_private_key(
            self.account_private_key), self.chain_id)
        self.account_client = AccountClient(
            self.account_contract_address, self.client, self.signer)
        assert type(
            account_private_key) == int, "Account private key must be integer"

        # OpenOracle contract
        open_oracle_abi = open('build/OpenOraclePublisher_abi.json', 'r')
        self.open_oracle_contract = Contract(
            address=open_oracle_address, abi=json.load(open_oracle_abi), client=self.client)
        open_oracle_abi.close()

    async def _fetch_base_contracts(self):
        if self.account_contract is None:
            self.account_contract = await Contract.from_address(
                self.account_contract_address, self.client
            )

    async def get_balance(self):
        return await self.account_client.get_balance()

    async def send_transaction(self, to_contract, selector_name, calldata) -> hex:
        selector = get_selector_from_name(selector_name)
        return await self.send_transactions([Call(to_contract, selector, calldata)])

    async def send_transactions(self, calls) -> hex:
        return hex((await self.account_client.execute(calls, auto_estimate=True)).hash)

    async def publish_open_oracle_entries_okex(self, assets=['btc', 'eth', 'dai']) -> hex:
        okx_oracle_data = fetch_okex(assets=assets)
        calls = [self.open_oracle_contract.functions["publish_entry"].prepare(
            prepare_contract_call_args(*oracle_data)) for oracle_data in okx_oracle_data]

        return await self.send_transactions(calls=calls)

    async def publish_open_oracle_entries_coinbase(self, assets=['btc', 'eth', 'dai']) -> hex:
        coinbase_oracle_data = fetch_coinbase(assets=assets)
        calls = [self.open_oracle_contract.functions["publish_entry"].prepare(
            prepare_contract_call_args(*oracle_data)) for oracle_data in coinbase_oracle_data]

        return await self.send_transactions(calls=calls)

    async def publish_open_oracle_entries_all_publishers(self, assets=['btc', 'eth', 'dai']) -> hex:
        okx_oracle_data = fetch_okex(assets=assets)
        coinbase_oracle_data = fetch_coinbase(assets=assets)
        all_data = okx_oracle_data + coinbase_oracle_data

        calls = [self.open_oracle_contract.functions["publish_entry"].prepare(
            prepare_contract_call_args(*oracle_data)) for oracle_data in all_data]
        return await self.send_transactions(calls=calls)


async def main():
    c = OpenOracleClient()
    await c.publish_open_oracle_entries_okex(assets=['btc'])


if __name__ == "__main__":

    asyncio.run(main())
