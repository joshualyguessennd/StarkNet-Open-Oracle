import asyncio
from client import OpenOracleClient
import os
import time
from dotenv import load_dotenv
from starknet_py.net.client_errors import ClientError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

load_dotenv("client/.env")
account_private_key = int(os.getenv("ACCOUNT_PRIVATE_KEY"), 0)
account_contract_address = int(os.getenv("ACCOUNT_CONTRACT_ADDRESS"), 0)


OPEN_ORACLE_ADDRESS = (
    "0x00bc0106bed3f1dfa7d2badec00d11b1c0ee6ee47e0946f52d927dde6ab079a0"
)


async def main():
    c: OpenOracleClient
    c = OpenOracleClient(
        open_oracle_address=OPEN_ORACLE_ADDRESS,
        account_contract_address=account_contract_address,
        account_private_key=account_private_key,
    )

    assets = ["btc", "eth"]

    for attempt in range(3):
        try:
            results = await c.publish_open_oracle_entries_all_publishers_sequential(
                assets
            )
        except ClientError as e:
            logger.warning(f"Client error {e} at {attempt} attempt, retrying")
            time.sleep(10)

        else:
            break

    for k in results:
        print(f"Published latest Open Oracle {k} data with tx: {results[k]}")


if __name__ == "__main__":

    asyncio.run(main())
