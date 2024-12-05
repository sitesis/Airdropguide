#!/bin/bash

# Define variables
DOCKER_IMAGE="ghcr.io/zenchain-protocol/zenchain-testnet:latest"
CONTAINER_NAME="zenchain"
CHAIN_DATA_DIR="./chain-data"
DEFAULT_RPC_PORT=9944
BOOTNODE="/dns4/node-7242611732906999808-0.p2p.onfinality.io/tcp/26266/p2p/12D3KooWLAH3GejHmmchsvJpwDYkvacrBeAQbJrip5oZSymx5yrE"
CHAIN="zenchain_testnet"

# Prompt user for node name
read -p "Enter your desired node name: " NODE_NAME
if [[ -z "$NODE_NAME" || ! "$NODE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
  echo "Invalid node name. Please use letters, numbers, dashes, or underscores only."
  exit 1
fi

# Prompt user for RPC port
read -p "Enter the RPC port (default: $DEFAULT_RPC_PORT): " CUSTOM_RPC_PORT
RPC_PORT=${CUSTOM_RPC_PORT:-$DEFAULT_RPC_PORT}
RPC_ENDPOINT="http://localhost:$RPC_PORT"

# Check if Docker is installed
if ! command -v docker &>/dev/null; then
  echo "Docker is not installed. Please install Docker and try again."
  exit 1
fi

# Check if jq is installed, if not, install it
if ! command -v jq &>/dev/null; then
  echo "jq is not installed. Installing jq..."
  if [ -f /etc/debian_version ]; then
    sudo apt update && sudo apt install jq -y
  elif [ -f /etc/redhat-release ]; then
    sudo yum install jq -y
  else
    echo "Unsupported OS. Please install jq manually."
    exit 1
  fi
fi

# Create chain data directory if not exists
mkdir -p $CHAIN_DATA_DIR

# Pull the latest Docker image
echo "Pulling the ZenChain Docker image..."
docker pull $DOCKER_IMAGE

# Stop and remove any existing container with the same name
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
  echo "Cleaning up existing container..."
  docker stop $CONTAINER_NAME && docker rm $CONTAINER_NAME
fi

# Run the ZenChain validator node
echo "Starting the ZenChain validator node..."
docker run -d \
  --name $CONTAINER_NAME \
  -p $RPC_PORT:$RPC_PORT \
  -v $CHAIN_DATA_DIR:/chain-data \
  $DOCKER_IMAGE \
  ./usr/bin/zenchain-node \
  --base-path=/chain-data \
  --rpc-cors=all \
  --unsafe-rpc-external \
  --validator \
  --name=$NODE_NAME \
  --bootnodes=$BOOTNODE \
  --chain=$CHAIN

# Wait for the node to initialize
echo "Waiting for the node to initialize..."
sleep 20

# Generate session keys using JSON-RPC
echo "Generating session keys..."
SESSION_KEYS=$(curl -s -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"author_rotateKeys","params":[],"id":1}' \
  $RPC_ENDPOINT | jq -r '.result')

if [ -z "$SESSION_KEYS" ] || [ "$SESSION_KEYS" == "null" ]; then
  echo "Failed to generate session keys. Ensure the node is running and accessible at $RPC_ENDPOINT."
  exit 1
fi

echo "Session keys generated: $SESSION_KEYS"

# Display instructions for setting session keys
echo "To set the session keys, use the following command on your Ethereum account:"
echo "Submit a transaction to the KeyManager contract with the setKeys function:"
echo "Ethereum Address: 0x0000000000000000000000000000000000000802"
echo "Session Keys: $SESSION_KEYS"
echo "Refer to the ZenChain documentation for guidance: https://wiki.polkadot.network/docs/maintain-guides-how-to-validate-polkadot#generating-the-session-keys"

# Final message
echo "ZenChain validator node setup complete. Ensure you have staked the required ZCX and submitted a request to validate."
echo "To view logs, use: docker logs -f $CONTAINER_NAME"
