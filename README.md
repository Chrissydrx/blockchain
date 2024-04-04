# Dev environment for ethereum

This repository contains a private ethereum network. The repository is based on this [Medium Article](https://medium.com/scb-digital/running-a-private-ethereum-blockchain-using-docker-589c8e6a4fe8).

## Setup

1. You need docker, curl and jq installed on your machine.
2. Run `cp .env.example .env` and replace the values with your own. Make sure to use not the values overlapping with the ethereum network.
3. Run `docker-compose up -d` to start the private ethereum network.
4. Copy the binary code of the smart contract you want to deploy in the binary_code.txt file.
5. Run `./deploy_contract.sh` to deploy the smart contract.
6. You can stop the blockchain with `docker-compose stop` (This also prevents the state of the network).

## Helpful commands

### See current block number

```zsh
curl --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "eth_blockNumber",
    "params": []
}'
```

### Unlock the main account

```zsh
curl --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "method": "personal_unlockAccount",
    "params": ["MAIN_ACCOUNT_ADDRESS", "PASSWORD", 300],
    "id": 1
}'
```

### Execute a smart contract

```zsh
curl --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "method": "eth_sendTransaction",
    "params": [{
        "from": "MAIN_ACCOUNT_ADDRESS",
        "to": "SMART_CONTRACT_ADDRESS",
        "data": "SMART_CONTRACT_METHOD_HASH"
    }],
    "id": 1
}'
```

### Call a smart contract

```zsh
curl --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "method": "eth_call",
    "params": [{
        "to": "SMART_CONTRACT_ADDRESS",
        "data": "SMART_CONTRACT_METHOD_HASH"
    }, "latest"],
    "id": 1
}'
```

#### Example call for the given example

```zsh
curl --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "method": "eth_call",
    "params": [{
        "to": "0xccfec4da708d765af724fda290596995e20d72b7",
        "data": "0xf8a8fd6d"
    }, "latest"],
    "id": 1
}'
```
