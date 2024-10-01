#!/bin/bash

# Nama Proyek
PROJECT_NAME="citrea-project"

# Cek apakah Node.js sudah terinstal
if command -v node >/dev/null 2>&1; then
  echo "Node.js sudah terinstal. Lewati instalasi."
else
  echo "Node.js tidak ditemukan. Menginstal Node.js dan npm..."
  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# Cek apakah npm sudah terinstal
if command -v npm >/dev/null 2>&1; then
  echo "npm sudah terinstal. Lewati instalasi."
else
  echo "npm tidak ditemukan. Menginstal npm..."
  sudo apt-get install -y npm
fi

# 1. Inisialisasi Proyek
echo "Inisialisasi Proyek NPM..."
mkdir $PROJECT_NAME
cd $PROJECT_NAME || exit
npm init -y

# 2. Instalasi Hardhat, Sourcify, dan Dependensi Tambahan
echo "Menginstal Hardhat, Sourcify, dan Dependensi..."
npm install --save-dev hardhat @nomicfoundation/hardhat-verify @openzeppelin/contracts dotenv @nomiclabs/hardhat-waffle @sourcify/hardhat-sourcify

# 3. Inisialisasi Proyek Hardhat
echo "Menginisialisasi Proyek Hardhat..."
npx hardhat init

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
CITREA_TESTNET_RPC_URL="https://rpc.testnet.citrea.xyz"
EOT

# 7. Mengkonfigurasi hardhat.config.js (dengan plugin Sourcify)
echo "Mengonfigurasi hardhat.config.js dengan Sourcify..."
cat <<EOT > hardhat.config.js
require('@nomiclabs/hardhat-waffle');
require('@nomicfoundation/hardhat-verify');
require('@sourcify/hardhat-sourcify');  // Plugin Sourcify
require('dotenv').config();
const { privateKey } = require("./private.json");

module.exports = {
    solidity: {
        version: "0.8.20",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        citrea: {
            url: process.env.CITREA_TESTNET_RPC_URL,
            chainId: 5115,
            accounts: [privateKey],
        },
    },
    etherscan: {
        apiKey: "dummyapikey",
        customChains: [
            {
                network: "citrea",
                chainId: 5115,
                urls: {
                    apiURL: "https://explorer.testnet.citrea.xyz/api",
                    browserURL: "https://explorer.testnet.citrea.xyz",
                }
            }
        ]
    },
    sourcify: {
        // Konfigurasi Sourcify untuk verifikasi otomatis setelah deploy
        endpoint: "https://sourcify.dev/server",  // Server Sourcify
        verifyOnDeploy: true,  // Otomatis memverifikasi kontrak setelah deploy
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
    constructor() ERC20("Hello Citrea", "HelloCitrea") ERC20Permit("HelloCitrea") {
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

# 10. Mengompilasi Proyek
echo "Mengompilasi Proyek..."
npx hardhat compile

# 11. Deploy Kontrak di Citrea Testnet
echo "Melakukan Deployment Kontrak di Citrea Testnet..."
npx hardhat run --network citrea scripts/deploy.js

# 12. Verifikasi Kontrak menggunakan Sourcify
echo "Verifikasi Kontrak di Sourcify..."
npx hardhat sourcify --network citrea

# 13. Menambahkan File .gitignore
echo "Menambahkan private.json ke .gitignore..."
cat <<EOT >> .gitignore
private.json
.env
node_modules/
EOT

echo "Proses selesai. Proyek Citrea berhasil diinstal, dikonfigurasi, dan diverifikasi melalui Sourcify."
