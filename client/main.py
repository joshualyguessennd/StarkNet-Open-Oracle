import asyncio
from client import OpenOracleClient
import os
from dotenv import load_dotenv


load_dotenv("client/.env")
account_private_key = int(os.getenv("ACCOUNT_PRIVATE_KEY"), 0)
account_contract_address = int(os.getenv("ACCOUNT_CONTRACT_ADDRESS"), 0)


OPEN_ORACLE_ADDRESS = (
    "0x00bc0106bed3f1dfa7d2badec00d11b1c0ee6ee47e0946f52d927dde6ab079a0"
)


async def main():
    c = OpenOracleClient(
        open_oracle_address=OPEN_ORACLE_ADDRESS,
        account_contract_address=account_contract_address,
        account_private_key=account_private_key,
    )

    result = await c.publish_open_oracle_entries_all_publishers(assets=["btc", "eth"])
    print(f"Published Open Oracle data with tx: {result}")


if __name__ == "__main__":

    asyncio.run(main())
