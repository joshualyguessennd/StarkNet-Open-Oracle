import asyncio
from client import OpenOracleClient
import os
from dotenv import load_dotenv


load_dotenv("client/.env")
account_private_key = int(os.getenv("ACCOUNT_PRIVATE_KEY"))
account_contract_address = os.getenv("ACCOUNT_CONTRACT_ADDRESS")


OPEN_ORACLE_ADDRESS = (
    "0x02de2fd1695a30436230a036d27b8f5b506d1882e0ff61acd418a5348ecb106c"
)


async def main():
    c = OpenOracleClient(
        open_oracle_address=OPEN_ORACLE_ADDRESS,
        account_contract_address=account_contract_address,
        account_private_key=account_private_key,
    )

    await c.publish_open_oracle_entries_all_publishers(assets=["btc", "eth"])


if __name__ == "__main__":

    asyncio.run(main())
