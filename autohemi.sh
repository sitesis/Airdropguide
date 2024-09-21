#!/bin/bash

# Nama folder proyek
PROJECT_DIR="TestToken"

# Membuat direktori proyek
echo "Creating project directory: $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Inisialisasi npm
echo "Initializing npm..."
npm init -y

# Install dependensi yang diperlukan
echo "Installing necessary dependencies..."
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts

# Membuat struktur folder untuk Hardhat
echo "Setting up Hardhat..."
npx hardhat

# Membuat file hardhat.config.js dengan konfigurasi Hemi Network
echo "Creating hardhat.config.js with Hemi Network configuration..."
cat <<EOL > hardhat.config.js
/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.20",
  networks: {
    hemi: {
      url: "https://testnet.rpc.hemi.network/rpc",  // Hemi Testnet URL
      chainId: 743111,  // Hemi Testnet Chain ID
      accounts: [\`0x\${process.env.PRIVATE_KEY}\`],
    },
  }
};
EOL

# Membuat folder contracts dan scripts
echo "Creating contracts and scripts directories..."
mkdir contracts && mkdir scripts

# Membuat file MyToken.sol di dalam folder contracts
echo "Creating MyToken.sol contract..."
cat <<EOL > contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _mint(msg.sender, initialSupply);
    }
}
EOL

# Mengompilasi kontrak
echo "Compiling the contract..."
npx hardhat compile

# Membuat file deploy.js di dalam folder scripts
echo "Creating deploy.js script..."
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000", "ether");

    const Token = await ethers.getContractFactory("MyToken");
    const token = await Token.deploy(initialSupply);

    console.log("Token deployed to:", token.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL

# Membuat file .env
echo "Creating .env file..."
touch .env

# Instruksi untuk membuka .env menggunakan nano dan menambahkan PRIVATE_KEY
echo "Open the .env file using nano to add your private key:"
echo "Run: nano .env"
echo "Add the following line to your .env file:"
echo "PRIVATE_KEY=your_exported_private_key"

# Membuat file .gitignore
echo "Creating .gitignore file..."
cat <<EOL > .gitignore
# Sample .gitignore code
node_modules/
.env
artifacts/
cache/
EOL

echo "Project directory setup completed!"
