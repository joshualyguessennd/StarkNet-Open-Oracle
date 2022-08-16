# StarkNet-Open-Oracle

## Setup  
Install Protostar. Clone the repository. Use python 3.7.

```bash
python -m venv env
source env/bin/activate
pip install -r requirements.txt
```

Testing contracts (local contract deployment with protostar cool features takes some time so be patient)

```
protostar test tests/
```

Use `protostar test --disable-hint-validation tests/` if using hints in the main Contract. 

## Using the client to publish signed prices  

First you need to compile the contract to get its abi. It will be stored in `build/OpenOraclePublisher_abi.json`

```bash
protostar build
```

Then fill the necessary environment variables in `client/.env(fill_and_rename_to.env` and rename the file to `.env`. You will need:  
- your account private key as an integer  
- your account contract address  
- optionally, Coinbase API keys with “view” permission if you want to fetch signed prices from Coinbase.    
Note that Okex doesn't require any API keys to fetch its signed prices.  

After that edit the function `main()` in `client/client.py` so you can choose your assets (only BTC, ETH and DAI are supported for now), and if you want to fetch prices either from:     
- okex (use `c.publish_open_oracle_entries_okex`)  
- coinbase (use `c.publish_open_oracle_entries_coinbase`)  
- both (use `c.publish_open_oracle_entries_all_publishers`).  

```python
async def main():
    c = OpenOracleClient()
    await c.publish_open_oracle_entries_okex(assets=['btc', 'eth'])
```

Finally, don't forget to activate the virtual env and just run `python client/client.py`. 

All updates will happen in one transaction. 

## Contract deployment and current address

To deploy the contract, just use protostar like this :

```bash
protostar build
protostar deploy build/OpenOraclePublisher.json --network alpha-goerli
```

The current version of the contract is deployed here : https://goerli.voyager.online/contract/0x0623022bd8d44cfa85b5cf47b796ad6857771c98ca17468f5d8f66dacde366aa and the contract address is stored in `client/client.py`



