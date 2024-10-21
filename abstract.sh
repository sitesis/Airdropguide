#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Display function for progress updates
show() {
    echo -e "[*] $1"
    if [[ $2 == "progress" ]]; then
        sleep 1
    fi
}

# Function to install dependencies
install_dependencies() {
    show "Installing Node.js..." "progress"
    source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/ndjs.sh)
    clear
    show "Initializing Hardhat project..." "progress"
    npx hardhat init --yes
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
      enableEraVMExtensions: false,
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

    mv contracts/Lock.sol contracts/HelloAbstract.sol
    cat <<EOL > contracts/HelloAbstract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HelloAbstract {
    function sayHello() public pure virtual returns (string memory) {
        return "Hey there, This smart contract is deployed with the help of Airdropnode!";
    }
}
EOL

    npx hardhat clean
    npx hardhat compile --network abstractTestnet
}

# Function to set up deployment script
deployment() {
    read -p "Enter your wallet private key (without 0x): " DEPLOYER_PRIVATE_KEY
    mkdir -p deploy
    cat <<EOL > deploy/deploy.ts
import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";

export default async function (hre: HardhatRuntimeEnvironment) {
  const wallet = new Wallet("$DEPLOYER_PRIVATE_KEY");
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("HelloAbstract");

  const tokenContract = await deployer.deploy(artifact);
  console.log(\`Your deployed contract address : \${await tokenContract.getAddress()}\`);
}
EOL
}

# Function to deploy multiple contracts
deploy_contracts() {
    read -p "How many contracts do you want to deploy? " CONTRACT_COUNT
    > contracts.txt

    for ((i = 1; i <= CONTRACT_COUNT; i++)); do
        show "Deploying contract #$i..." "progress"
        npx hardhat deploy-zksync --script deploy.ts
        show "Contract #$i deployed successfully"
        echo "------------------------------------"
        read -p "Please enter the deployed contract address for contract #$i : " CONTRACT_ADDRESS
        echo "$CONTRACT_ADDRESS" >> contracts.txt
    done
}

# Function to verify deployed contracts
verify_contracts() {
    while IFS= read -r CONTRACT_ADDRESS; do
        show "Verifying smart contract at address: $CONTRACT_ADDRESS..." "progress"
        npx hardhat verify --network abstractTestnet "$CONTRACT_ADDRESS"
    done < contracts.txt
}

# Main function
main() {
    install_dependencies
    compilation
    deployment
    deploy_contracts
    verify_contracts
}

# Execute the main function
main
