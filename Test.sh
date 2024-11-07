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

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies: Go and C Compiler..."
    sudo apt update
    sudo apt install -y golang-go build-essential
}

# Function to build Geth from source
build_geth() {
    echo "Cloning and building Geth from source..."
    git clone https://github.com/ethereum/go-ethereum.git
    cd go-ethereum
    make geth
}

# Function to download genesis.json
download_genesis() {
    echo "Downloading genesis.json from GitHub..."
    curl -L $GENESIS_URL -o $GENESIS_FILE
}

# Function to initialize the Geth database
initialize_geth() {
    echo "Initializing Geth database..."
    $GETH_BUILD_DIR/geth init --datadir $NODE_DIR $GENESIS_FILE
}

# Function to create or import account
create_or_import_account() {
    echo "Do you want to create a new account? (y/n)"
    read create_account

    if [ "$create_account" == "y" ]; then
        echo "Creating new account..."
        $GETH_BUILD_DIR/geth --datadir $NODE_DIR account new
    else
        echo "Importing existing account..."
        echo "Enter the path to your private key (e.g., ./privateKey.txt):"
        read private_key_path
        $GETH_BUILD_DIR/geth account import --datadir $NODE_DIR $private_key_path
    fi
}

# Function to start the node
start_node() {
    echo "Do you want to run a Validator node or RPC node? (Enter 'validator' or 'rpc')"
    read node_type

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
            --ws.api eth,net,web3
    elif [ "$node_type" == "validator" ]; then
        echo "Starting Validator node..."
        echo "Enter your validator account address:"
        read validator_address
        echo "Enter your validator account password file path:"
        read validator_password_file
        $GETH_BUILD_DIR/geth \
            --mine --miner.etherbase=$validator_address \
            --unlock $validator_address \
            --password $validator_password_file \
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
            --ws.api eth,net,web3
    else
        echo "Invalid input. Please choose either 'rpc' or 'validator'."
        exit 1
    fi
}

# Main menu
while true; do
    echo "Choose an option:"
    echo "1. Install dependencies"
    echo "2. Build Geth"
    echo "3. Download genesis.json"
    echo "4. Initialize Geth database"
    echo "5. Create or import account"
    echo "6. Start Node"
    echo "7. Exit"
    read choice

    case $choice in
        1) install_dependencies ;;
        2) build_geth ;;
        3) download_genesis ;;
        4) initialize_geth ;;
        5) create_or_import_account ;;
        6) start_node ;;
        7) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please choose a valid option." ;;
    esac
done
