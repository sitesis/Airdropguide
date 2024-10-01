#!/bin/bash

# Buat direktori proyek dan masuk ke dalamnya
mkdir citrea
cd citrea || exit

# Check for Node.js installation
if ! command -v node &> /dev/null
then
    echo "Node.js is not installed. Please install Node.js before running this script."
    exit 1
fi

# Check for npm installation
if ! command -v npm &> /dev/null
then
    echo "npm is not installed. Please install npm before running this script."
    exit 1
fi

# Install Hardhat
echo "Installing Hardhat..."
npm install --save-dev hardhat

# Create a new Hardhat project
echo "Creating a new Hardhat project..."
npx hardhat init

# Check if hardhat.config.js exists
CONFIG_FILE="hardhat.config.js"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found. Please make sure to run 'npx hardhat init' first."
    exit 1
fi

# Prompt for private key
read -sp "Enter your private key (this will be kept secret): " PRIVATE_KEY
echo

# Update hardhat.config.js with Citrea configuration
echo "Configuring Hardhat for Citrea..."

# Add Citrea network configuration to hardhat.config.js
cat <<EOL >> $CONFIG_FILE

module.exports = {
    solidity: "0.8.19", // Version Solidity
    networks: {
        citrea: {
            url: "https://rpc.testnet.citrea.xyz",
            chainId: 5115,
            accounts: ["$PRIVATE_KEY"],
        },
    },
};
EOL

# Create a simple smart contract
echo "Creating a sample smart contract..."
mkdir -p contracts
cat <<EOL > contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MyContract {
    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    function setName(string memory _name) public {
        name = _name;
    }
}
EOL

# Create a deploy script
echo "Creating a deploy script..."
mkdir -p scripts
cat <<EOL > scripts/deploy.js
const hre = require("hardhat");

async function main() {
    const MyContract = await hre.ethers.getContractFactory("MyContract");
    const myContract = await MyContract.deploy("Hello, Citrea!");
    await myContract.deployed();
    console.log("Contract deployed to:", myContract.address);
}

async function deploy() {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

deploy();
EOL

# Print success message
echo "Hardhat has been configured for Citrea Testnet successfully!"
echo "You can now deploy your smart contracts using the command:"
echo "npx hardhat run --network citrea scripts/deploy.js"
