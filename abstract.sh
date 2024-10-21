#!/bin/bash

# Install logo script
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Check if Node.js is installed
if command -v node >/dev/null 2>&1; then
    echo "Node.js is installed: $(node -v)"
else
    # Update package list
    sudo apt update

    # Install curl if not installed
    sudo apt install -y curl

    # Download and install the latest Node.js version using NodeSource
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    sudo apt install -y nodejs

    # Verify installation
    echo "Node.js and npm have been installed."
    node -v
    npm -v
fi

# Create project directory
PROJECT_DIR=~/AbstractProject

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir "$PROJECT_DIR"
    echo "Directory $PROJECT_DIR has been created."
else
    echo "Directory $PROJECT_DIR already exists."
fi

# Navigate to project directory
cd "$PROJECT_DIR" || exit

# Initialize NPM project
npm init -y
echo "NPM project has been initialized."

# Install dependencies
npm install -D @matterlabs/hardhat-zksync @matterlabs/zksync-contracts zksync-ethers ethers
echo "Installed Hardhat, zkSync, and Ethers dependencies."

# Initialize Hardhat project
npx hardhat init -y
echo "Hardhat project has been created with an empty configuration."

# Create folders for contracts and scripts
mkdir contracts && mkdir scripts
echo "Folders 'contracts' and 'scripts' have been created."

# Create AbstractToken.sol file
cat <<EOL > contracts/AbstractToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AbstractToken is ERC20 {
    constructor() ERC20("AbstractToken", "ABS") {
        _mint(msg.sender, 1000000e18);
    }
}
EOL
echo "File 'AbstractToken.sol' has been created in the 'contracts' folder."

# Compile contracts using the abstractTestnet network
npx hardhat compile --network abstractTestnet
echo "Contracts have been compiled on the abstractTestnet network."

# Create .env file
touch .env
echo "File '.env' has been created in the project directory."

# Get private key input from user
read -p "Enter your private key (do not share publicly): " PRIVATE_KEY
if [ -z "$PRIVATE_KEY" ]; then
    echo "Private key cannot be empty. Exiting."
    exit 1
fi
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo "Your private key has been saved in the .env file."

# Create .gitignore file
cat <<EOL > .gitignore
# Sample .gitignore code
# Node modules
node_modules/

# Environment variables
.env

# Coverage files
coverage/
coverage.json

# Typechain generated files
typechain/
typechain-types/

# Hardhat files
cache/
artifacts/

# Build files
build/
EOL
echo "File '.gitignore' has been created with sample code."

# Create hardhat.config.ts file
cat <<EOL > hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@matterlabs/hardhat-zksync";

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest", // Use the latest version of zkSolidity
    settings: {
      // Set to true if you plan to interact directly with NonceHolder or ContractDeployer system contracts
      enableEraVMExtensions: true,
    },
  },
  defaultNetwork: "abstractTestnet", // Set the default network to abstractTestnet
  networks: {
    abstractTestnet: {
      url: "https://api.testnet.abs.xyz", // URL for the abstract testnet
      ethNetwork: "sepolia", // Specify the Ethereum network to use
      zksync: true, // Enable zkSync for this network
      verifyURL: "https://api-explorer-verify.testnet.abs.xyz/contract_verification", // Verification URL for contracts
    },
  },
  solidity: {
    version: "0.8.24", // Specify the Solidity compiler version
  },
};

export default config;
EOL
echo "File 'hardhat.config.ts' has been created with Hardhat configuration for zkSync."

# Create deploy.js file in the scripts folder
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000000", "ether");

    const Token = await ethers.getContractFactory("AbstractToken");
    const token = await Token.deploy();

    console.log("Token deployed to:", token.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL
echo "File 'deploy.js' has been created in the 'scripts' folder."

# Run the deploy script
echo "Running deploy script..."
DEPLOY_OUTPUT=$(npx hardhat run --network abstractTestnet scripts/deploy.js)

# Display deploy output
echo "$DEPLOY_OUTPUT"

# Display important information
echo -e "\nAbstract project has been set up and the contract has been deployed!"

# Retrieve token address from deploy output
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')

# Display message to check address in explorer
if [ -n "$TOKEN_ADDRESS" ]; then
    echo -e "Please check your token address on the explorer: https://explorer.testnet.abs.xyz/address/$TOKEN_ADDRESS"
else
    echo "Unable to find the deployed token address."
fi

# Invite to join Airdrop Node
echo -e "\n🎉 **Done!** 🎉"
echo -e "\n👉 **[Join Airdrop Node](https://t.me/airdrop_node)** 👈"
