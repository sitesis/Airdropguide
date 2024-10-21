#!/bin/bash

# Install script for setting up a Hardhat project with zkSync

# Start by installing logo script
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Display function for progress updates
show() {
    echo -e "[*] $1"
    if [[ $2 == "progress" ]]; then
        sleep 1
    fi
}

# Function to create project directory and initialize Hardhat
create_project() {
    show "Creating project directory..." "progress"
    mkdir my-abstract-project && cd my-abstract-project
    show "Initializing Hardhat project..." "progress"

    # User choices for project initialization
    echo "✔ What do you want to do? · Create a TypeScript project"
    echo "✔ Hardhat project root: · $(pwd)"

    # Prompt for .gitignore
    read -p "✔ Do you want to add a .gitignore? (Y/n) · " add_gitignore
    add_gitignore=${add_gitignore:-y} # default to 'y' if no input

    # Prompt for installing dependencies
    read -p "✔ Do you want to install dependencies with npm? (Y/n) · " install_deps
    install_deps=${install_deps:-y} # default to 'y' if no input

    # Initialize Hardhat project with options
    npx hardhat init --yes --gitignore $add_gitignore --install-deps $install_deps
}

# Function to install Node.js and dependencies
install_dependencies() {
    show "Installing Node.js..." "progress"
    source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/ndjs.sh)
    clear
    show "Installing required dependencies..." "progress"
    npm install -D @matterlabs/hardhat-zksync @matterlabs/zksync-contracts zksync-ethers@6 ethers@6

    show "All dependencies installation completed."
}

# Function to modify the Hardhat configuration and compile the contracts
compilation() {
    show "Modifying Hardhat configuration..." "progress"
    cat <<EOL > hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@matterlabs/hardhat-zksync";

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest",
    settings: {
      enableEraVMExtensions: true,
    },
  },
  defaultNetwork: "abstractTestnet",
  networks: {
    abstractTestnet: {
      url: "https://api.testnet.abs.xyz",
      ethNetwork: "sepolia",
      zksync: true,
      verifyURL: "https://api-explorer-verify.testnet.abs.xyz/contract_verification",
    },
  },
  solidity: {
    version: "0.8.24",
  },
};

export default config;
EOL

    show "Renaming Lock.sol to HelloAbstract.sol..." "progress"
    mv contracts/Lock.sol contracts/HelloAbstract.sol

    show "Writing new smart contract in HelloAbstract.sol..." "progress"
    cat <<EOL > contracts/HelloAbstract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HelloAbstract {
    function sayHello() public pure virtual returns (string memory) {
        return "Hello, World!";
    }
}
EOL

    show "Cleaning and compiling contracts..." "progress"
    npx hardhat clean
    npx hardhat compile --network abstractTestnet
}

# Function to set DEPLOYER_PRIVATE_KEY
set_private_key() {
    read -p "Enter your private key: " DEPLOYER_PRIVATE_KEY
    npx hardhat vars set DEPLOYER_PRIVATE_KEY $DEPLOYER_PRIVATE_KEY
    show "DEPLOYER_PRIVATE_KEY has been set." "progress"
}

# Function to create the deploy script
create_deploy_script() {
    show "Creating deploy directory..." "progress"
    mkdir deploy
    show "Creating deploy.ts script..." "progress"
    cat <<EOL > deploy/deploy.ts
import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { vars } from "hardhat/config";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(\`Running deploy script\`);

  // Initialize the wallet using your private key.
  const wallet = new Wallet(vars.get("DEPLOYER_PRIVATE_KEY"));

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);
  // Load contract
  const artifact = await deployer.loadArtifact("HelloAbstract");

  // Deploy this contract. The returned object will be of a \`Contract\` type.
  const tokenContract = await deployer.deploy(artifact);

  // Log the contract address
  const contractAddress = await tokenContract.getAddress();
  console.log(
    \`\${
      artifact.contractName
    } was deployed to \${contractAddress}\`
  );

  // Return the contract address for further use
  return contractAddress;
}
EOL
    show "deploy.ts script created successfully." "progress"
}

# Function to deploy the smart contract
deploy_contract() {
    show "Deploying the smart contract..." "progress"
    # Capture the deployed contract address
    DEPLOYED_ADDRESS=$(npx hardhat deploy-zksync --script deploy.ts)
    show "Deployment completed successfully!" "progress"

    # Output the contract address and verification instructions
    echo -e "\nTo verify your smart contract, run the following command:"
    echo "npx hardhat verify --network abstractTestnet $DEPLOYED_ADDRESS"
    echo -e "\nYou can explore the transaction on the testnet explorer at:"
    echo "https://explorer.testnet.abs.xyz/"
}

# Main script execution
create_project
install_dependencies
compilation
set_private_key
create_deploy_script
deploy_contract

show "Setup and deployment completed successfully!"
