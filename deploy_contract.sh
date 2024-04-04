#!/bin/bash

# Load the .env file to get variables
if [ -f .env ]; then
    export $(cat .env | xargs)
else 
    echo ".env file not found!"
    exit 1
fi

# Step 1: Check if the blockchain is ready
response=$(curl --silent --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "eth_blockNumber",
    "params": []
}')

blockNumber=$(echo $response | jq -r '.result')
if [ "$blockNumber" == "0x0" ]; then
    echo "The blockchain is not ready. Try again later."
    exit 1
fi

# Step 2: Get the main account address
response=$(curl --silent --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "eth_accounts",
    "params": []
}')

mainAccount=$(echo $response | jq -r '.result[0]')
if [ -z "$mainAccount" ]; then
    echo "No account found."
    exit 1
fi

# Step 3: Unlock the main account
response=$(curl --silent --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw "{
    \"jsonrpc\": \"2.0\",
    \"method\": \"personal_unlockAccount\",
    \"params\": [\"$mainAccount\", \"$ACCOUNT_PASSWORD\", 300],
    \"id\": 1
}")

unlockResult=$(echo $response | jq -r '.result')
if [ "$unlockResult" != "true" ]; then
    echo "Failed to unlock account."
    exit 1
fi

# Step 4: Deploy the smart contract
binaryCode=$(cat binary_code.txt)
# Check if the binary code starts with "0x"
if [[ $binaryCode != 0x* ]]; then
    binaryCode="0x$binaryCode"
fi

response=$(curl --silent --location --request POST 'localhost:8545' \
--header 'Content-Type: application/json' \
--data-raw "{
    \"method\": \"personal_sendTransaction\",
    \"id\": 1,
    \"jsonrpc\": \"2.0\",
    \"params\":
        [{
            \"from\": \"$mainAccount\", \"data\": \"$binaryCode\"}, \"$ACCOUNT_PASSWORD\"]
}")

transactionHash=$(echo $response | jq -r '.result')
if [ -z "$transactionHash" ]; then
    echo "Failed to deploy the smart contract."
    exit 1
fi

# Step 5: Get the smart contract id
startTime=$(date +%s)
timeout=120 # 2 minutes in seconds
contractId=""

while [ -z "$contractId" ]; do
    response=$(curl --silent --location --request POST 'localhost:8545' \
    --header 'Content-Type: application/json' \
    --data-raw "{
        \"jsonrpc\":\"2.0\",
        \"method\":\"eth_getTransactionReceipt\",
        \"params\":[\"$transactionHash\"],
        \"id\":1
    }")

    contractId=$(echo $response | jq -r '.result.contractAddress // empty')

    # Break the loop if contractId is not empty
    if [[ -n "$contractId" ]]; then
        break
    fi

    currentTime=$(date +%s)
    elapsed=$((currentTime - startTime))

    if [ $elapsed -ge $timeout ]; then
        echo "Failed to get the smart contract ID within 2 minutes."
        exit 1
    fi

    # Wait for 1 second before trying again
    sleep 1
done

echo "Smart contract deployed successfully with ID: $contractId"
