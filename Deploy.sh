#!/bin/bash

# Define colors
BLUE='\033[0;34m'
WHITE='\033[0;97m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

# Install logo script
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5  # Pause for 5 seconds to display logo

install_dependencies() {
    CONTRACT_NAME="AirdropNode"

    # Initialize Git if not already done
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}Initializing Git repository...${RESET}"
        git init
    fi

    # Install Foundry if not already installed using the updated Foundry.sh URL
    if ! command -v forge &> /dev/null; then
        echo -e "${YELLOW}Foundry is not installed. Installing now...${RESET}"
        source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh)
    fi

    # Install OpenZeppelin Contracts if not already installed
    if [ ! -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; then
        echo -e "${YELLOW}Installing OpenZeppelin Contracts...${RESET}"
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
    else
        echo -e "${WHITE}OpenZeppelin Contracts already installed.${RESET}"
    fi
}

input_required_details() {
    echo -e "${YELLOW}-----------------------------------${RESET}"

    # Remove existing .env if it exists
    if [ -f "$SCRIPT_DIR/token_deployment/.env" ]; then
        rm "$SCRIPT_DIR/token_deployment/.env"
    fi

    # Prompt for token name input
    echo -e "${YELLOW}Enter Token Name (default: AirdropNode):${RESET}"
    read TOKEN_NAME
    TOKEN_NAME="${TOKEN_NAME:-AirdropNode}"

    # Prompt for token symbol input
    echo -e "${YELLOW}Enter Token Symbol (default: NODE):${RESET}"
    read TOKEN_SYMBOL
    TOKEN_SYMBOL="${TOKEN_SYMBOL:-NODE}"

    # Prompt for the number of contracts to deploy
    echo -e "${YELLOW}Enter number of contract addresses to deploy (default: 1):${RESET}"
    read NUM_CONTRACTS
    NUM_CONTRACTS="${NUM_CONTRACTS:-1}"

    # Prompt for private key input
    echo -e "${YELLOW}Enter your Private Key:${RESET}"
    read PRIVATE_KEY

    # Prompt for RPC URL input
    echo -e "${YELLOW}Enter the RPC URL:${RESET}"
    read RPC_URL

    # Prompt for explorer scan URL input
    echo -e "${YELLOW}Enter the Explorer Scan URL (e.g., https://testnet.explorer.hemi.xyz/):${RESET}"
    read EXPLORER_URL

    # Create .env file with provided details
    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
NUM_CONTRACTS="$NUM_CONTRACTS"
RPC_URL="$RPC_URL"
EXPLORER_URL="$EXPLORER_URL"
EOL

    # Source the .env file
    source "$SCRIPT_DIR/token_deployment/.env"

    # Update foundry.toml with the provided RPC URL
    cat <<EOL > "$SCRIPT_DIR/foundry.toml"
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
rpc_url = "$RPC_URL"
EOL

    echo "Updated files with your given data."
}

flatten_contract() {
    echo -e "${YELLOW}Flattening the contract...${RESET}"

    # Flatten the contract into a single file
    forge flatten src/AirdropNode.sol > src/AirdropNodeFlattened.sol

    echo -e "${WHITE}Flattened contract saved to src/AirdropNodeFlattened.sol${RESET}"
}

deploy_contract() {
    echo -e "${YELLOW}-----------------------------------${RESET}"
    # Source the .env file again for the latest environment variables
    source "$SCRIPT_DIR/token_deployment/.env"

    # Create the contract source directory if it doesn't exist
    mkdir -p "$SCRIPT_DIR/src"

    # Write the contract code to a file
    cat <<EOL > "$SCRIPT_DIR/src/AirdropNode.sol"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNode is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, 1000 * (10 ** decimals())); // Default supply of 1000 tokens
    }
}
EOL

    # Compile the contract
    echo "Compiling contract..."
    forge build

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Contract compilation failed.${RESET}"
        exit 1
    fi

    # Deploy the contract based on the number of contracts
    for i in $(seq 1 "$NUM_CONTRACTS"); do
        echo "Deploying contract $i of $NUM_CONTRACTS..."

        DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/AirdropNode.sol:AirdropNode" \
            --rpc-url "$RPC_URL" \
            --private-key "$PRIVATE_KEY")

        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Deployment of contract $i failed.${RESET}"
            continue
        fi

        # Extract and display the deployed contract address
        CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
        echo -e "${YELLOW}Contract $i deployed successfully at address: $CONTRACT_ADDRESS${RESET}"

        # Generate and display the user-provided Explorer URL for the contract
        EXPLORER_URL="$EXPLORER_URL/address/$CONTRACT_ADDRESS"
        echo -e "${WHITE}You can view your contract at: $EXPLORER_URL${RESET}"
    done
}

# Main execution flow
install_dependencies
input_required_details
flatten_contract
deploy_contract

# Final Telegram invitation
echo -e "${YELLOW}-----------------------------------${RESET}"
echo -e "${BLUE}Join our Telegram channel for updates and support: https://t.me/airdrop_node${RESET}"
