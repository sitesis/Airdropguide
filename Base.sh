#!/bin/bash

# Define color codes for a more appealing look
RESET="\e[0m"
BOLD="\e[1m"
MAROON="\e[38;5;88m"       # Maroon for success
CYAN="\e[96m"              # Light cyan for informational messages
YELLOW="\e[93m"            # Light yellow for prompts
RED="\e[91m"               # Red for errors
MAGENTA="\e[35m"           # Magenta for special notes
BLUE="\e[94m"              # Blue for general sections
ORANGE="\e[38;5;214m"      # Orange for major actions
LIGHT_BLUE="\e[94m"        # Light blue for deployment steps

# Display the logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

install_dependencies() {
    CONTRACT_NAME="AirdropNode"

    # Initialize Git if not already done
    if [ ! -d ".git" ]; then
        echo -e "${MAGENTA}Initializing Git repository...${RESET}"
        git init
    fi

    # Install Foundry if not already installed using the updated Foundry.sh URL
    if ! command -v forge &> /dev/null; then
        echo -e "${ORANGE}Foundry is not installed. Installing now...${RESET}"
        source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh)
    fi

    # Install OpenZeppelin Contracts if not already installed
    if [ ! -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; then
        echo -e "${CYAN}Installing OpenZeppelin Contracts...${RESET}"
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
    else
        echo -e "${MAROON}OpenZeppelin Contracts already installed.${RESET}"
    fi
}

input_required_details() {
    echo -e "${LIGHT_BLUE}-----------------------------------${RESET}"

    # Remove existing .env if it exists
    if [ -f "$SCRIPT_DIR/token_deployment/.env" ]; then
        rm "$SCRIPT_DIR/token_deployment/.env"
    fi

    # Ask for token name and symbol, defaulting to AirdropNode and NODE if left blank
    echo -e "${BLUE}Enter Token Name (default: AirdropNode): ${RESET}"
    read TOKEN_NAME
    TOKEN_NAME="${TOKEN_NAME:-AirdropNode}"

    echo -e "${BLUE}Enter Token Symbol (default: NODE): ${RESET}"
    read TOKEN_SYMBOL
    TOKEN_SYMBOL="${TOKEN_SYMBOL:-NODE}"

    # Ask for the number of contract addresses to deploy
    echo -e "${BLUE}Enter number of contract addresses to deploy (default: 1): ${RESET}"
    read NUM_CONTRACTS
    NUM_CONTRACTS="${NUM_CONTRACTS:-1}"

    # Ask for private key input
    echo -e "${BLUE}Enter your Private Key: ${RESET}"
    read PRIVATE_KEY

    # Define the RPC URL directly
    RPC_URL="https://mainnet.base.org"

    # Create .env file with provided details
    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
NUM_CONTRACTS="$NUM_CONTRACTS"
RPC_URL="$RPC_URL"
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

    echo -e "${MAROON}Updated files with your given data.${RESET}"
}

deploy_contract() {
    echo -e "${LIGHT_BLUE}-----------------------------------${RESET}"
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
    echo -e "${CYAN}Compiling contract...${RESET}"
    forge build

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Contract compilation failed.${RESET}"
        exit 1
    fi

    # Deploy the contract based on the number of contracts
    for i in $(seq 1 "$NUM_CONTRACTS"); do
        echo -e "${LIGHT_BLUE}Deploying contract $i of $NUM_CONTRACTS...${RESET}"

        DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/AirdropNode.sol:AirdropNode" \
            --rpc-url "$RPC_URL" \
            --private-key "$PRIVATE_KEY")

        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Deployment of contract $i failed.${RESET}"
            continue
        fi

        # Extract and display the deployed contract address
        CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
        echo -e "${MAROON}Contract $i deployed successfully at address: $CONTRACT_ADDRESS${RESET}"

        # Generate and display the BaseScan URL for the contract
        BASESCAN_URL="https://basescan.org/address/$CONTRACT_ADDRESS"
        echo -e "${CYAN}You can view your contract at: $BASESCAN_URL${RESET}"
    done
}

# Main execution flow
install_dependencies
input_required_details
deploy_contract

# Invite to join Telegram channel
echo -e "${YELLOW}-----------------------------------${RESET}"
echo -e "${MAGENTA}Join our Telegram channel for updates and support: https://t.me/airdrop_node${RESET}"
