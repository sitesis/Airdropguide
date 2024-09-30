#!/bin/bash

# Function to install Node.js
install_node() {
    echo "Installing Node.js..."

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "curl could not be found. Please install curl and run the script again."
        exit 1
    fi

    # Install Node.js using NodeSource
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs

    # Verify installation
    if ! command -v node &> /dev/null; then
        echo "Node.js installation failed."
        exit 1
    fi

    echo "Node.js installed successfully. Version: $(node -v)"
}

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    install_node
else
    echo "Node.js is already installed. Version: $(node -v)"
fi

# Create a new Hardhat project directory
PROJECT_NAME="sonic"
mkdir $PROJECT_NAME
cd $PROJECT_NAME

# Initialize a new npm project
npm init -y

# Install Hardhat and dependencies
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv

# Create Hardhat configuration file
cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

// Replace this private key with your Sonic account private key
const SONIC_PRIVATE_KEY = process.env.SONIC_PRIVATE_KEY;

module.exports = {
  solidity: "0.8.19",
  networks: {
    sonic: {
      url: "https://rpc.testnet.soniclabs.com",
      accounts: [SONIC_PRIVATE_KEY]
    }
  }
};
EOL

# Create .env file for environment variables
cat <<EOL > .env
SONIC_PRIVATE_KEY=YOUR_SONIC_TEST_ACCOUNT_PRIVATE_KEY
EOL

# Create contracts directory and a simple contract
mkdir contracts
cat <<EOL > contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MyContract {
    string public message;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}
EOL

# Create scripts directory and deployment script
mkdir scripts
cat <<EOL > scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    const MyContract = await ethers.getContractFactory("MyContract");
    const myContract = await MyContract.deploy("Hello, Sonic!");

    console.log("Contract deployed to:", myContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
EOL

# Provide instructions for deployment
echo "Setup complete. Please update your .env file with your Sonic private key."
echo "You can deploy your contract using the following command:"
echo "npx hardhat run scripts/deploy.js --network sonic"
