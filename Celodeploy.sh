#!/bin/bash

# Function to install Celo Composer, deploy, and verify contracts
install_celo_composer() {
  echo "Starting Celo Composer installation, deployment, and verification..."

  # Install Node.js
  echo "Installing Node.js..."
  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  sudo apt-get install -y nodejs
  echo "Node.js installed successfully!"

  # Install Yarn
  echo "Installing Yarn..."
  npm install --global yarn
  echo "Yarn installed successfully!"

  # Clone the Celo Composer repository
  echo "Cloning Celo Composer repository..."
  git clone https://github.com/celo-org/celo-composer.git
  cd celo-composer || exit
  echo "Repository cloned successfully!"

  # Install project dependencies
  echo "Installing project dependencies..."
  yarn install
  echo "Dependencies installed successfully!"

  # Install Hardhat and Celo plugins
  echo "Installing Hardhat and Celo plugins..."
  yarn add --dev hardhat @celo/hardhat @celo-tools/hardhat-ethers @nomiclabs/hardhat-etherscan
  echo "Hardhat and plugins installed successfully!"

  # Create Hardhat configuration
  echo "Creating Hardhat configuration..."
  cat <<EOL > hardhat.config.js
require('@nomiclabs/hardhat-waffle');
require('@celo/hardhat');
require('@nomiclabs/hardhat-etherscan');

module.exports = {
  solidity: "0.8.4",
  networks: {
    alfajores: {
      url: "https://alfajores-forno.celo.org",
      accounts: [process.env.PRIVATE_KEY], // Ganti dengan private key Anda
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY // Ganti dengan API key Etherscan Anda
  }
};
EOL
  echo "Hardhat configuration created successfully!"

  # Compile the smart contracts
  echo "Compiling smart contracts..."
  yarn hardhat compile
  echo "Contracts compiled successfully!"

  # Create a deployment script
  echo "Creating deployment script..."
  mkdir -p scripts
  cat <<EOL > scripts/deploy.js
async function main() {
  const Contract = await ethers.getContractFactory("YourContractName"); // Ganti dengan nama kontrak Anda
  const contract = await Contract.deploy();
  await contract.deployed();
  console.log("Contract deployed to:", contract.address);
  return contract.address; // Kembalikan alamat kontrak
}

main()
  .then((address) => {
    console.log("Contract Address:", address);
    return address;
  })
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOL
  echo "Deployment script created successfully!"

  # Create a verification script
  echo "Creating verification script..."
  cat <<EOL > scripts/verify.js
const { run } = require("hardhat");

async function main() {
  const contractAddress = process.argv[2]; // Ambil alamat kontrak dari argumen
  await run("verify:verify", {
    address: contractAddress,
    constructorArguments: [], // Tambahkan argumen konstruktor jika ada
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOL
  echo "Verification script created successfully!"

  echo "Celo Composer installation completed successfully!"

  # Deployment and verification process
  echo "Deploying contract..."
  CONTRACT_ADDRESS=$(npx hardhat run scripts/deploy.js --network alfajores)

  echo "Verifying contract..."
  npx hardhat run scripts/verify.js --network alfajores $CONTRACT_ADDRESS

  echo "Deployment and verification completed successfully!"
}

# Start installation process
install_celo_composer
