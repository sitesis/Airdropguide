#!/bin/bash

# Meminta input private key dan BlockScout API key
echo "Masukkan private key Anda (jangan dibagikan ke siapapun):"
read -sp "Private Key: " PRIVATE_KEY
echo

echo "Masukkan BlockScout API key Anda (untuk verifikasi kontrak):"
read -sp "BlockScout API Key: " BLOCKSCOUT_API_KEY
echo

# Install Node.js versi 20
echo "Memastikan Node.js versi 20..."
curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Periksa versi Node.js
NODE_VERSION=$(node -v)
echo "Node.js version: $NODE_VERSION"

# Install dependensi proyek
echo "Menginstall dependensi proyek..."
mkdir -p inkdeploy
cd inkdeploy
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox dotenv @openzeppelin/contracts

# Inisialisasi proyek Hardhat
echo "Inisialisasi proyek Hardhat..."
npx hardhat init --force

# Membuat kontrak ERC20
echo "Membuat kontrak ERC20 InkToken.sol..."
cat <<EOL > contracts/InkToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract InkToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("InkToken", "INK") {
        _mint(msg.sender, initialSupply);
    }
}
EOL

# Membuat file .env untuk konfigurasi
echo "Membuat file .env untuk konfigurasi..."
cat <<EOL > .env
PRIVATE_KEY=$PRIVATE_KEY
INK_SEPOLIA_URL=https://rpc-gel-sepolia.inkonchain.com/
BLOCKSCOUT_API_KEY=$BLOCKSCOUT_API_KEY
EOL

# Membuat konfigurasi Hardhat di hardhat.config.js
echo "Memperbarui konfigurasi Hardhat di hardhat.config.js..."
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

# Membuat skrip deploy.js untuk menyebarkan kontrak
echo "Membuat skrip deploy.js untuk penyebaran kontrak..."
cat <<EOL > scripts/deploy.js
async function main() {
  // Mendapatkan factory untuk kontrak InkToken
  const InkToken = await ethers.getContractFactory("InkToken");

  // Men-deploy kontrak dengan menyediakan jumlah token awal (misalnya 1 juta token)
  const initialSupply = ethers.utils.parseUnits("1000000", 18);  // 1 juta token dengan 18 desimal
  const token = await InkToken.deploy(initialSupply);

  // Menunggu hingga kontrak ter-deploy
  await token.deployed();

  // Menampilkan alamat kontrak yang telah ter-deploy
  console.log("InkToken deployed to:", token.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOL

# Menyebarkan kontrak ke jaringan Sepolia Ink
echo "Menyebarkan kontrak ke jaringan Sepolia Ink..."
npx hardhat run scripts/deploy.js --network inksepolia

# Memverifikasi kontrak di BlockScout
DEPLOYED_CONTRACT_ADDRESS=$(cat scripts/deploy.js | grep "InkToken deployed to:" | awk '{print $4}')
echo "Memverifikasi kontrak di BlockScout..."
npx hardhat verify --network inksepolia $DEPLOYED_CONTRACT_ADDRESS

echo "Proses selesai!"
