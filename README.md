# StarkNet-Open-Oracle

### What is the open oracle standard ? 
Compound Finance [announced](https://medium.com/compound-finance/announcing-compound-open-oracle-development-cff36f06aad3) in august 2019 on the Open Oracle standard. 

It allows a *Reporter* (typically a trusted source like an exchange) to sign a message containing price data in a standardized way with a private key.   

A *Publisher* can then use this signed message to put the price data on-chain.

Using the *Reporter's* public key to verify the message's signature, there is no need to trust the *Publisher* for correctly reporting the data from the *Reporter*.


In April 2020, [Coinbase started providing an Open Oracle compatible signed price feed](https://blog.coinbase.com/introducing-the-coinbase-price-oracle-6d1ee22c7068) so that anyone can publish their data on chain.
They were [followed by Okx](https://www.okx.com/academy/en/okex-enhances-support-for-defi-growth-with-its-secure-price-feed-okex-oracle) the same year. 


This repository ports the on-chain [verification contracts](https://github.com/compound-finance/open-oracle/blob/0e148fdb0e8cbe4d412548490609679621ab2325/contracts/OpenOracleData.sol#L40-L43) of the standard from Ethereum over to StarkNet. 


## Setup for development  
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
Note that OKX doesn't require any API keys to fetch its signed prices.  

After that edit the function `main()` in `client/main.py` so you can choose your assets, and if you want to fetch prices either from:     
- okx (use `c.publish_open_oracle_entries_okx`)  
- coinbase (use `c.publish_open_oracle_entries_coinbase`)  
- both (use `c.publish_open_oracle_entries_all_reporters`).  

Supported assets are :
- BTC, ETH, DAI, ZRX, BAT, KNC, LINK, COMP (for both Coinbase and Okx)  
- XTZ, REP, UNI, GRT, SNX. (for Coinbase only)

```python
async def main():
    c = OpenOracleClient()
    await c.publish_open_oracle_entries_all_reporters(assets=['btc', 'eth'])
```

#### Run locally 
Make sure you have activated the virtual env and just run `python client/main.py`. 

All updates will happen in one transaction. 

#### Build and use a Docker container

```bash
docker build -t python-open-oracle-client .
docker run --env-file client/.env  python-open-oracle-client
```

## Contract deployment and current address

To deploy the contract, just use protostar like this :

```bash
protostar build
protostar deploy build/OpenOraclePublisher.json --network alpha-goerli
```

The current version of the contract is deployed here : https://goerli.voyager.online/contract/0x02de2fd1695a30436230a036d27b8f5b506d1882e0ff61acd418a5348ecb106c

The contract address is also stored in the variable `OPEN_ORACLE_ADDRESS` in `client/main.py`.
