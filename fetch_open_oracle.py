import time
from abc import ABC, abstractmethod

#  from empiric.core.const import NETWORK, ORACLE_CONTROLLER_ADDRESS
from starknet_py.contract import Contract
from starknet_py.net import AccountClient
from starknet_py.net.client_models import Call
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.models import StarknetChainId
from starknet_py.net.networks import MAINNET, TESTNET
from starknet_py.net.signer.stark_curve_signer import KeyPair, StarkCurveSigner
from starkware.starknet.public.abi import get_selector_from_name

import requests


def to_uint(a):
    """Takes in value, returns uint256-ish tuple."""
    return (a & ((1 << 128) - 1), a >> 128)


def remove_0x_if_present(eth_hex_data: str) -> str:
    if eth_hex_data[0:2].upper() == '0X':
        return eth_hex_data[2:]
    else:
        return eth_hex_data


def prepare_contract_call_args(oracle_message_hex: str, oracle_signature_hex: str, eth_wallet_address: str) -> dict:
    message_bytes = bytes.fromhex(remove_0x_if_present(oracle_message_hex))
    signature_bytes = bytes.fromhex(remove_0x_if_present(oracle_signature_hex))

    timestamp_little_endian = int.from_bytes(message_bytes[56:64], 'little')
    price_little_endian = int.from_bytes(message_bytes[120:128], 'little')
    ticker_len_little_endian = int.from_bytes(message_bytes[216:224], 'little')
    ticker_little_endian = int.from_bytes(message_bytes[224:232], 'little')

    signature_r_big = int.from_bytes(signature_bytes[0:32], 'big')
    signature_s_big = int.from_bytes(signature_bytes[32:64], 'big')
    signature_v_big = int.from_bytes(signature_bytes[64:96], 'big')

    signature_r_uint256 = to_uint(signature_r_big)
    signature_s_uint256 = to_uint(signature_s_big)

    eth_address_big = int(remove_0x_if_present(eth_wallet_address), 16)

    if signature_v_big == 27 or signature_v_big == 28:
        signature_v_big -= 27  # See https://github.com/starkware-libs/cairo-lang/blob/13cef109cd811474de114925ee61fd5ac84a25eb/src/starkware/cairo/common/cairo_secp/signature.cairo#L173-L174

    contract_call_args = {'t_little': timestamp_little_endian, 'p_little': price_little_endian,
                          'ticker_len_little': ticker_len_little_endian, 'ticker_name_little': ticker_little_endian,
                          'r_low': signature_r_uint256[0], 'r_high': signature_r_uint256[1],
                          's_low': signature_s_uint256[0], 's_high': signature_s_uint256[1],
                          'v': signature_v_big, 'eth_address': eth_address_big}
    return contract_call_args


r = requests.get('https://www.okx.com/api/v5/market/open-oracle')
r_dict = r.json()['data'][0]
messages = r_dict['messages']
signatures = r_dict['signatures']

m_btc = messages[0]
s_btc = signatures[0]
okx_wallet_address = '85615b076615317c80f14cbad6501eec031cd51c'  # from api docs


print(prepare_contract_call_args(m_btc, s_btc, okx_wallet_address))


class EmpiricAccountClient(AccountClient):
    async def _get_nonce(self) -> int:
        return int(time.time())


class EmpiricBaseClient(ABC):
    def __init__(
        self,
        account_private_key,
        account_contract_address,
        network=None,
        oracle_controller_address=None,
    ):
        if network is None:
            network = NETWORK
        if oracle_controller_address is None:
            oracle_controller_address = ORACLE_CONTROLLER_ADDRESS

        if network == TESTNET:
            chain_id = StarknetChainId.TESTNET
        elif network == MAINNET:
            chain_id = StarknetChainId.MAINNET
        else:
            raise NotImplementedError(
                "Empiric.BaseClient: Network not recognized, unknown Chain ID"
            )

        self.network = network
        self.chain_id = chain_id
        self.oracle_controller_address = oracle_controller_address
        self.oracle_controller_contract = None
        self.account_contract_address = account_contract_address
        self.account_contract = None

        assert type(
            account_private_key) == int, "Account private key must be integer"
        self.account_private_key = account_private_key

        self.signer = StarkCurveSigner(
            self.account_contract_address,
            KeyPair.from_private_key(self.account_private_key),
            self.chain_id,
        )

        self.client = GatewayClient(self.network)
        self.account_client = AccountClient(
            self.account_contract_address, self.client, self.signer
        )

    @abstractmethod
    async def _fetch_contracts(self):
        pass

    async def _fetch_base_contracts(self):
        if self.oracle_controller_contract is None:
            self.oracle_controller_contract = await Contract.from_address(
                self.oracle_controller_address,
                self.client,
            )

        if self.account_contract is None:
            self.account_contract = await Contract.from_address(
                self.account_contract_address, self.client
            )

    async def get_balance(self):
        return await self.account_client.get_balance()

    async def send_transaction(self, to_contract, selector_name, calldata):
        selector = get_selector_from_name(selector_name)
        return await self.send_transactions([Call(to_contract, selector, calldata)])

    async def send_transactions(self, calls):
        return hex((await self.account_client.execute(calls, auto_estimate=True)).hash)
