# StarkNet-Open-Oracle

## Setup  
Install Protostar. Clone the repository. Use python 3.7.

```bash
python -m venv env
source env/bin/activate
pip install -r requirements.txt
```

Testing contracts (local contract deployment with protostar cool features takes some time)

```
protostar test tests/
```

Use `protostar test --disable-hint-validation tests/` if using hints in the main Contract. 

## Using the client to publish signed prices  

First you need to compile the contract to get its abi.  
```bash
protostar build
```

Fill the necessary environment variables in `client/.env(fill_and_rename_to.env` and rename the file to `.env`  
You will need your account private key as an integer, your account contract address, and optionally coinbase api key with “view” permission if you want to fetch signed prices from Coinbase.  
Okex doesn't require any api keys to fetch its signed prices.  

Edit the function `main()` in client/client.py so you can choose your assets (only BTC, ETH and DAI are supported for now), and if you want to fetch prices either from   
-okex (use `c.publish_open_oracle_entries_okex`)  
-coinbase (use `c.publish_open_oracle_entries_coinbase`)  
-both (use `publish_open_oracle_entries_all_publishers`).  

```python
async def main():
    c = OpenOracleClient()
    await c.publish_open_oracle_entries_okex(assets=['btc', 'eth'])
```

Finally, don't forget to activate the virtual env and just run `python client/client.py`. 

All updates will happen in one transaction. 
