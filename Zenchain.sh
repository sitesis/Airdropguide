#!/bin/bash

# Function to update the VPS
update_vps() {
    echo "Updating VPS..."
    sudo apt-get update -y
    sudo apt-get upgrade -y
    echo "VPS updated successfully."
}

# Function to check if Node.js is installed and install if necessary
install_nodejs() {
    echo "Checking if Node.js is installed..."
    if command -v node > /dev/null 2>&1; then
        NODE_VERSION=$(node -v)
        echo "Node.js is already installed: $NODE_VERSION"
        if [[ "$NODE_VERSION" == v16.* || "$NODE_VERSION" == v18.* ]]; then
            echo "Compatible Node.js version found."
        else
            echo "Incompatible Node.js version. Installing Node.js v16.x..."
            install_nodejs_version 16
        fi
    else
        echo "Node.js not found. Installing Node.js v16.x..."
        install_nodejs_version 16
    fi
}

# Function to install Node.js (v16.x or v18.x)
install_nodejs_version() {
    VERSION=$1
    curl -fsSL https://deb.nodesource.com/setup_$VERSION.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "Node.js v$VERSION.x installed successfully."
}

# Function to install Hardhat
install_hardhat() {
    echo "Installing Hardhat..."
    if [ -d "node_modules" ]; then
        echo "node_modules directory already exists. Skipping Hardhat installation."
    else
        npm install --save-dev hardhat
        echo "Hardhat installed successfully."
    fi
}

# Function to initialize Hardhat project
initialize_hardhat() {
    echo "Initializing Hardhat project..."
    npx hardhat
}

# Function to configure ZenChain network in hardhat.config.js
configure_zenchain_network() {
    CONFIG_FILE="hardhat.config.js"
    echo "Configuring ZenChain network in $CONFIG_FILE..."

    # Check if hardhat.config.js exists
    if [ -f "$CONFIG_FILE" ]; then
        read -sp "Enter your Metamask private key: " PRIVATE_KEY
        echo

        # Replace PRIVATE_KEY with the actual private key securely
        echo "Ensure your private key is stored securely and not shared publicly."

        # Update hardhat.config.js with ZenChain network settings
        cat <<EOL >> $CONFIG_FILE

module.exports = {
  solidity: "0.8.19",
  networks: {
    zenchain: {
      url: "https://rpc-testnet.zenchainlabs.io",
      chainId: 1000,
      accounts: [\`0x\${PRIVATE_KEY}\`] // Your Metamask private key
    },
  },
};
EOL
        echo "ZenChain network configuration added to $CONFIG_FILE."
    else
        echo "Error: $CONFIG_FILE not found. Ensure you are in the Hardhat project directory."
    fi
}

# Function to write a basic smart contract in contracts/MyContract.sol
write_smart_contract() {
    CONTRACTS_DIR="contracts"
    CONTRACT_FILE="$CONTRACTS_DIR/MyContract.sol"

    echo "Creating the MyContract.sol smart contract..."

    # Check if contracts directory exists, if not create it
    if [ ! -d "$CONTRACTS_DIR" ]; then
        mkdir $CONTRACTS_DIR
    fi

    # Write the basic smart contract to MyContract.sol
    cat <<EOL > $CONTRACT_FILE
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MyContract {
    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function setMessage(string memory _message) public {
        message = _message;
    }
}
EOL

    echo "Smart contract MyContract.sol created successfully in the contracts directory."
}

# Function to compile the smart contract
compile_smart_contract() {
    echo "Compiling the smart contract..."
    npx hardhat compile

    if [ $? -eq 0 ]; then
        echo "Smart contract compiled successfully. ABI and bytecode are generated in the artifacts folder."
    else
        echo "Error occurred during contract compilation."
    fi
}

# Function to write the deployment script in scripts/deploy.js
write_deployment_script() {
    SCRIPTS_DIR="scripts"
    DEPLOY_SCRIPT="$SCRIPTS_DIR/deploy.js"

    echo "Creating the deployment script deploy.js..."

    # Check if scripts directory exists, if not create it
    if [ ! -d "$SCRIPTS_DIR" ]; then
        mkdir $SCRIPTS_DIR
    fi

    # Write the deployment script to deploy.js
    cat <<EOL > $DEPLOY_SCRIPT
const hre = require("hardhat");

async function main() {
    const MyContract = await hre.ethers.getContractFactory("MyContract");
    const myContract = await MyContract.deploy("Zenosama!");

    await myContract.deployed();

    console.log("MyContract deployed to:", myContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOL

    echo "Deployment script deploy.js created successfully in the scripts directory."
}

# Function to deploy the smart contract
deploy_smart_contract() {
    echo "Deploying the smart contract to ZenChain testnet..."
    npx hardhat run scripts/deploy.js --network zenchain

    if [ $? -eq 0 ]; then
        echo "Smart contract deployed successfully to ZenChain testnet."
    else
        echo "Error occurred during contract deployment."
    fi
}

# Function to verify contract deployment on ZenChain block explorer
verify_deployment() {
    read -p "Enter the contract address to verify: " CONTRACT_ADDRESS
    echo "Checking contract address on ZenChain block explorer..."

    # Provide the block explorer URL for ZenChain
    EXPLORER_URL="https://explorer.zenchainlabs.io/address/$CONTRACT_ADDRESS"

    # Open the browser to the contract's page in ZenChain Explorer
    echo "You can verify the contract deployment by visiting the following URL:"
    echo $EXPLORER_URL
}

# Main script execution
update_vps
install_nodejs
install_hardhat
initialize_hardhat
configure_zenchain_network
write_smart_contract
compile_smart_contract
write_deployment_script
deploy_smart_contract
verify_deployment

echo "Installation, configuration, contract creation, compilation, deployment, and verification completed. Remember to store your private key securely."
