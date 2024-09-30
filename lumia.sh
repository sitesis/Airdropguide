#!/bin/bash

# Nama Proyek
PROJECT_NAME="lumia-project"

# 1. Inisialisasi Proyek
echo "Inisialisasi Proyek NPM..."
mkdir $PROJECT_NAME
cd $PROJECT_NAME || exit
npm init -y

# 2. Instalasi Hardhat dan Dependensi
echo "Menginstal Hardhat dan Dependensi..."
npm install --save-dev hardhat @nomicfoundation/hardhat-verify @openzeppelin/contracts dotenv

# 3. Inisialisasi Proyek Hardhat
echo "Membuat Proyek Hardhat..."
npx hardhat

# 4. Meminta Input Private Key MetaMask
echo "Masukkan Private Key MetaMask Anda (tanpa prefix 0x):"
read -r PRIVATE_KEY_INPUT

# 5. Membuat File private.json
echo "Menyiapkan File private.json..."
cat <<EOT >> private.json
{
  "privateKey": "$PRIVATE_KEY_INPUT"
}
EOT

# 6. Membuat File .env
echo "Menyiapkan File .env..."
cat <<EOT >> .env
LUMIA_TESTNET_RPC_URL="https://testnet-rpc.lumia.org"
EOT

# 7. Mengkonfigurasi hardhat.config.js
echo "Mengonfigurasi hardhat.config.js..."
cat <<EOT > hardhat.config.js
require('@nomiclabs/hardhat-waffle');
require('@nomicfoundation/hardhat-verify');
require('dotenv').config();
const { privateKey } = require("./private.json");

module.exports = {
  solidity: "0.8.20",
  
  networks: {
    "lumia-testnet": {
      url: process.env.LUMIA_TESTNET_RPC_URL,
      chainId: 1952959480,
      accounts: [privateKey],
    },
  },
  
  etherscan: {
    apiKey: "dummyapikey",
    customChains: [
      {
        network: "lumia-testnet",
        chainId: 1952959480,
        urls: {
          apiURL: "https://blockscout.lumia.org/api",
          browserURL: "https://blockscout.lumia.org",
        }
      }
    ]
  }
};
EOT

# 8. Membuat Kontrak Sportimex ERC20
echo "Membuat Kontrak ERC20 Sportimex..."
mkdir -p contracts
cat <<EOT > contracts/Sportimex.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract Sportimex is ERC20, ERC20Permit {
    constructor() ERC20("Hello Lumia", "HelloLumia") ERC20Permit("HelloLumia") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}
EOT

# 9. Membuat Skrip Deployment
echo "Membuat Skrip Deployment..."
mkdir -p scripts
cat <<EOT > scripts/deploy.js
async function main() {
  const Sportimex = await ethers.getContractFactory("Sportimex");
  const sportimex = await Sportimex.deploy();
  
  console.log("Sportimex deployed to:", sportimex.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOT

# 10. Deploy Kontrak
echo "Melakukan Deployment Kontrak di Lumia Testnet..."
npx hardhat run scripts/deploy.js --network lumia-testnet

# 11. Verifikasi Kontrak
echo "Verifikasi Kontrak di BlockScout Lumia Testnet..."
DEPLOYED_CONTRACT_ADDRESS=$(npx hardhat run scripts/deploy.js --network lumia-testnet | grep 'Sportimex deployed to:' | awk '{print $4}')
npx hardhat verify --network lumia-testnet $DEPLOYED_CONTRACT_ADDRESS

# 12. Menambahkan File .gitignore
echo "Menambahkan private.json ke .gitignore..."
cat <<EOT >> .gitignore
private.json
.env
node_modules/
EOT

echo "Proses selesai. Proyek Lumia berhasil diinstal dan dikonfigurasi."
