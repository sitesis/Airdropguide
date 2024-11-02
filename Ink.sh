#!/bin/bash

# Display logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Function to handle errors
handle_error() {
    echo "Error: $1"
    exit 1
}

# Install necessary packages if not already installed
echo "Installing required packages..."
sudo apt update || handle_error "Failed to update package list."
sudo apt install -y curl || handle_error "Failed to install curl."

# Check if Node.js is installed
if command -v node >/dev/null 2>&1; then
    echo "Node.js is already installed: $(node -v)"
else
    # Install Node.js
    echo "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash - || handle_error "Failed to setup NodeSource."
    sudo apt install -y nodejs || handle_error "Failed to install Node.js."
    echo "Node.js installed: $(node -v)"
fi

# Create project directory
PROJECT_DIR=~/INKProject
if [ ! -d "$PROJECT_DIR" ]; then
    mkdir "$PROJECT_DIR" || handle_error "Failed to create project directory."
    echo "Directory $PROJECT_DIR created."
else
    echo "Directory $PROJECT_DIR already exists."
fi

# Navigate to project directory
cd "$PROJECT_DIR" || handle_error "Failed to navigate to project directory."

# Initialize npm project
npm init -y || handle_error "Failed to initialize NPM project."
echo "NPM project initialized."

# Install Hardhat, Ethers.js, OpenZeppelin, and dotenv with error handling
if ! npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox ethers dotenv @openzeppelin/contracts; then
    handle_error "Failed to install dependencies."
fi
echo "Dependencies installed: Hardhat, Ethers.js, OpenZeppelin, dotenv."

# Prompt for private key and BlockScout API key securely
read -sp "Enter your private key (with 0x prefix): " PRIVATE_KEY
echo
if [[ ! $PRIVATE_KEY =~ ^0x[a-fA-F0-9]{40}$ ]]; then
    handle_error "Invalid private key format."
fi

read -p "Enter your BlockScout API key (leave empty if you don't have one): " BLOCKSCOUT_API_KEY

# Create .env file
{
    echo "PRIVATE_KEY=$PRIVATE_KEY"
    echo "INK_SEPOLIA_URL=https://rpc-gel-sepolia.inkonchain.com"
    echo "BLOCKSCOUT_API_KEY=${BLOCKSCOUT_API_KEY:-}"
} > .env || handle_error "Failed to create .env file."
echo ".env file created."

# Create contracts directory and INKToken.sol file
mkdir -p contracts
cat <<EOL > contracts/INKToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract INKToken is ERC20 {
    constructor() ERC20("INKToken", "NODE") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}
EOL
echo "Contract INKToken.sol created."

# Create scripts directory and deploy.js file
mkdir -p scripts
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const Token = await ethers.getContractFactory("INKToken");
    const token = await Token.deploy();
    await token.deployed();

    console.log("INKToken deployed to:", token.address);
    return token.address; // Return the token address
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
EOL
echo "Deployment script deploy.js created."

# Create .gitignore file
cat <<EOL > .gitignore
# Node modules
node_modules/

# Environment variables
.env

# Coverage files
coverage/
coverage.json

# Hardhat files
cache/
artifacts/

# Build files
build/
EOL
echo ".gitignore file created."

# Create hardhat.config.js file
cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    inksepolia: {
      url: process.env.INK_SEPOLIA_URL || "",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: {
      inksepolia: process.env.BLOCKSCOUT_API_KEY,
    },
    customChains: [
      {
        network: "inksepolia",
        chainId: 763373,
        urls: {
          apiURL: "https://explorer-sepolia.inkonchain.com/api/v2",
          browserURL: "https://explorer-sepolia.inkonchain.com/",
        },
      },
    ],
  },
};
EOL
echo "Hardhat configuration file hardhat.config.js created."

# Deploy the contract
echo "Deploying the contract..."
DEPLOY_OUTPUT=$(npx hardhat run scripts/deploy.js --network inksepolia)

# Display the output of the deployment
echo "$DEPLOY_OUTPUT"

# Extract the token address from the output
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')

# Show the scan link for the token address
if [ -n "$TOKEN_ADDRESS" ]; then
    echo "===================="
    echo "Check your token on the explorer: https://explorer-sepolia.inkonchain.com/address/$TOKEN_ADDRESS"
    echo "===================="
else
    echo "Unable to find the deployed token address."
fi

# Final message
echo -e "\n🎉 Deployment complete! 🎉"
echo -e "👉 Join the Airdrop Node: https://t.me/airdrop_node 👈"
