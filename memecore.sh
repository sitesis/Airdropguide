#!/bin/bash

# Set variables
GENESIS_URL="https://github.com/choir94/Airdropguide/raw/main/gnesis.json"
GENESIS_FILE="./genesis.json"
NODE_DIR="./nodes/node1"
GETH_BUILD_DIR="./build/bin"
NETWORK_ID="43521"
BOOTNODES="enode://d511b4562fbf87ccf864bf8bf0536632594d5838fc2223cecdb35b30c3b281172c96201a8f9835164b1d8ec1e4d6b7542af917fab7aca891654dae50ce515bc0@18.138.235.45:30303,enode://9b5ae242c202d74db9ba8406d2e225f97bb79487eedba576f20fcf8d770488d6e5d0110b45bcaf01b107d4a429b6cfcb7dea4e07f8dbc9816e8409b0b147036e@18.143.193.46:30303"
PORT="30303"
HTTP_PORT="8545"
WS_PORT="8546"

# Step 1: Install dependencies (Go and C Compiler)
echo "Checking and installing dependencies: Go and C Compiler..."
if ! command -v go &> /dev/null; then
    echo "Go is not installed. Installing Go..."
    sudo apt update
    sudo apt install -y golang-go
else
    echo "Go is already installed."
fi

if ! dpkg -l | grep -q build-essential; then
    echo "C Compiler (build-essential) is not installed. Installing..."
    sudo apt install -y build-essential
else
    echo "C Compiler (build-essential) is already installed."
fi

# Step 2: Clone and Build Geth Source
echo "Cloning and building Geth from source..."
if ! git clone https://github.com/ethereum/go-ethereum.git; then
    echo "Error cloning Geth repository. Exiting..."
    exit 1
fi
cd go-ethereum || { echo "Failed to enter go-ethereum directory. Exiting..."; exit 1; }

echo "Building Geth..."
if ! make geth; then
    echo "Error building Geth. Exiting..."
    exit 1
fi

# Step 3: Download Genesis File
echo "Downloading genesis.json from GitHub..."
if ! curl -L $GENESIS_URL -o $GENESIS_FILE; then
    echo "Error downloading genesis file. Exiting..."
    exit 1
fi

# Step 4: Initialize Geth Database
echo "Initializing Geth database..."
if ! $GETH_BUILD_DIR/geth init --datadir $NODE_DIR $GENESIS_FILE; then
    echo "Error initializing Geth database. Exiting..."
    exit 1
fi

# Step 5: Create or Import Account (Optional for RPC node)
echo "Do you want to create a new account? (y/n)"
read -r create_account

if [ "$create_account" == "y" ]; then
    echo "Creating new account..."
    if ! $GETH_BUILD_DIR/geth --datadir $NODE_DIR account new; then
        echo "Error creating account. Exiting..."
        exit 1
    fi
else
    echo "Importing existing account..."
    echo "Enter the path to your private key (e.g., ./privateKey.txt):"
    read -r private_key_path

    if [ ! -f "$private_key_path" ]; then
        echo "Private key file not found. Exiting..."
        exit 1
    fi

    if ! $GETH_BUILD_DIR/geth account import --datadir $NODE_DIR "$private_key_path"; then
        echo "Error importing account. Exiting..."
        exit 1
    fi
fi

# Step 6: Start the Node (Validator or RPC)
echo "Do you want to run a Validator node or RPC node? (Enter 'validator' or 'rpc')"
read -r node_type

if [ "$node_type" == "rpc" ]; then
    echo "Starting RPC node..."
    $GETH_BUILD_DIR/geth \
        --networkid $NETWORK_ID \
        --gcmode archive \
        --datadir $NODE_DIR \
        --bootnodes $BOOTNODES \
        --port $PORT \
        --http.api eth,net,web3 \
        --http \
        --http.port $HTTP_PORT \
        --http.addr 0.0.0.0 \
        --http.vhosts "*" \
        --ws \
        --ws.port $WS_PORT \
        --ws.addr 0.0.0.0 \
        --ws.api eth,net,web3 &> rpc_node.log &

    echo "RPC node started in the background. Logs can be found in rpc_node.log."

elif [ "$node_type" == "validator" ]; then
    echo "Starting Validator node..."
    echo "Enter your validator account address:"
    read -r validator_address
    echo "Enter your validator account password file path:"
    read -r validator_password_file

    if [ ! -f "$validator_password_file" ]; then
        echo "Password file not found. Exiting..."
        exit 1
    fi

    $GETH_BUILD_DIR/geth \
        --mine --miner.etherbase=$validator_address \
        --unlock $validator_address \
        --password "$validator_password_file" \
        --networkid $NETWORK_ID \
        --gcmode archive \
        --datadir $NODE_DIR \
        --bootnodes $BOOTNODES \
        --port $PORT \
        --http.api eth,net,web3 \
        --http \
        --http.port $HTTP_PORT \
        --http.addr 0.0.0.0 \
        --http.vhosts "*" \
        --ws \
        --ws.port $WS_PORT \
        --ws.addr 0.0.0.0 \
        --ws.api eth,net,web3 &> validator_node.log &

    echo "Validator node started in the background. Logs can be found in validator_node.log."

else
    echo "Invalid input. Please choose either 'rpc' or 'validator'."
    exit 1
fi

echo "Node setup completed."
