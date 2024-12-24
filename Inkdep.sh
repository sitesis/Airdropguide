#!/bin/bash

# Variabel untuk input
echo "Masukkan private key Anda:"
read PRIVATE_KEY
echo "Masukkan Blockscout API Key Anda:"
read BLOCKSCOUT_API_KEY

# Instalasi dependensi sistem
echo "Menginstal dependensi sistem..."
sudo apt update
sudo apt install -y curl git build-essential

# Instalasi Node.js jika belum terpasang
echo "Memeriksa Node.js..."
if ! command -v node &>/dev/null; then
    echo "Node.js tidak ditemukan. Menginstal Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
else
    echo "Node.js sudah terpasang."
fi

# Instalasi Hardhat
echo "Menginstal Hardhat..."
mkdir -p ~/AirdropNodeProject
cd ~/AirdropNodeProject
npm init -y
npm install --save-dev hardhat

# Membuat konfigurasi Hardhat
echo "Membuat konfigurasi Hardhat..."
npx hardhat

# Menambahkan dependensi yang dibutuhkan
npm install @openzeppelin/contracts dotenv

# Menambahkan konfigurasi Solidity di hardhat.config.js
echo "Mengonfigurasi hardhat.config.js..."
cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.20", // Sesuaikan dengan versi Solidity
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    inksepolia: {
      url: process.env.INK_SEPOLIA_URL || "https://sepolia.infura.io/v3/\${process.env.API_KEY}",
      accounts: [\${process.env.PRIVATE_KEY}],
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
          apiURL: "https://explorer-sepolia.inkonchain.com/api/v2",  # Sesuaikan dengan URL yang diberikan
          browserURL: "https://explorer-sepolia.inkonchain.com/",  # Sesuaikan dengan URL yang diberikan
        },
      },
    ],
  },
};
EOL

# Menambahkan file .env untuk variabel lingkungan
echo "Membuat file .env..."
cat <<EOL > .env
PRIVATE_KEY=$PRIVATE_KEY
BLOCKSCOUT_API_KEY=$BLOCKSCOUT_API_KEY
INK_SEPOLIA_URL=https://sepolia.infura.io/v3/$API_KEY
EOL

# Menambahkan kontrak AirdropNodeToken.sol
echo "Membuat kontrak AirdropNodeToken.sol..."
mkdir -p contracts
cat <<EOL > contracts/AirdropNodeToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNodeToken is ERC20 {
    constructor() ERC20("AirdropNodeToken", "ANT") {
        _mint(msg.sender, 5000000e18); // Mint 5 juta token
    }
}
EOL

# Menambahkan skrip deploy.js
echo "Membuat skrip deploy.js..."
mkdir -p scripts
cat <<EOL > scripts/deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const AirdropNodeToken = await ethers.getContractFactory("AirdropNodeToken");
  const token = await AirdropNodeToken.deploy();
  console.log("Token deployed to:", token.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
EOL

# Menjalankan kompilasi Hardhat
echo "Kompilasi proyek..."
npx hardhat compile

# Menjalankan deployment
echo "Menjalankan deployment..."
npx hardhat run scripts/deploy.js --network inksepolia

echo "Proyek telah disiapkan dan kontrak telah dideploy!"
