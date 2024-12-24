#!/bin/bash

# Menampilkan logo (opsional)
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Memeriksa apakah Node.js sudah terinstal
if command -v node >/dev/null 2>&1; then
    echo "Node.js sudah terinstal: $(node -v)"
else
    # Memperbarui daftar paket
    sudo apt update

    # Menginstal curl jika belum terinstal
    sudo apt install -y curl

    # Mengunduh dan menginstal Node.js versi terbaru menggunakan NodeSource
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    sudo apt install -y nodejs

    # Memverifikasi instalasi
    echo "Node.js dan npm versi terbaru telah diinstal."
    node -v
    npm -v
fi

# Membuat direktori proyek
PROJECT_DIR=~/SoneiumProject

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir "$PROJECT_DIR"
    echo "Direktori $PROJECT_DIR telah dibuat."
else
    echo "Direktori $PROJECT_DIR sudah ada."
fi

# Masuk ke direktori proyek
cd "$PROJECT_DIR" || exit

# Menginisialisasi proyek NPM
npm init -y
echo "Proyek NPM telah diinisialisasi."

# Menginstal Hardhat, Ethers.js, OpenZeppelin, dan dotenv
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts dotenv
echo "Hardhat, Ethers.js, OpenZeppelin, dan dotenv telah diinstal."

# Memulai proyek Hardhat
npx hardhat init -y
echo "Proyek Hardhat telah dibuat dengan konfigurasi default."

# Membuat folder contracts dan scripts
mkdir contracts && mkdir scripts
echo "Folder 'contracts' dan 'scripts' telah dibuat."

# Membuat file kontrak SoneiumToken.sol
cat <<EOL > contracts/SoneiumToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SoneiumToken is ERC20 {
    constructor() ERC20("SoneiumToken", "SNT") {
        _mint(msg.sender, 1000000e18); // Mint 1 juta token Soneium ke alamat deployer
    }
}
EOL
echo "File 'SoneiumToken.sol' telah dibuat di folder 'contracts'."

# Mengompilasi kontrak
npx hardhat compile
echo "Kontrak telah dikompilasi."

# Membuat file .env
touch .env
echo "File '.env' telah dibuat di direktori proyek."

# Mengambil input private key dari pengguna
read -p "Masukkan private key Anda: " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo "Private key Anda telah disimpan di file .env."

# Membuat file .gitignore
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
echo "File '.gitignore' telah dibuat dengan contoh kode."

# Membuat file hardhat.config.js
cat <<EOL > hardhat.config.js
/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");

const PK = process.env.PRIVATE_KEY;

module.exports = {
  solidity: "0.8.20",
  networks: {
    soneium: {
      url: "https://rpc.minato.soneium.org", // Soneium RPC URL
      accounts: [PK],
    },
  },
};
EOL
echo "File 'hardhat.config.js' telah diisi dengan konfigurasi Hardhat untuk Soneium."

# Membuat file deploy.js di folder scripts
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000000", "ether");

    const Token = await ethers.getContractFactory("SoneiumToken");
    const token = await Token.deploy();

    console.log("Token deployed to:", token.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL
echo "File 'deploy.js' telah dibuat di folder 'scripts'."

# Menjalankan skrip deploy
echo "Menjalankan skrip deploy..."
DEPLOY_OUTPUT=$(npx hardhat run --network soneium scripts/deploy.js)

# Menampilkan output deploy
echo "$DEPLOY_OUTPUT"

# Menampilkan informasi penting
echo -e "\nProyek Soneium telah disiapkan dan kontrak telah dideploy!"

# Mengambil alamat token dari output deploy
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')

# Menampilkan pesan untuk memeriksa alamat di explorer
if [ -n "$TOKEN_ADDRESS" ]; then
    echo -e "Silakan periksa alamat token Anda di explorer: https://soneium-minato.blockscout.com/address/$TOKEN_ADDRESS"
else
    echo "Alamat token yang dideploy tidak ditemukan."
fi

# Verifikasi kontrak
echo -e "\nMemverifikasi kontrak..."
npx hardhat verify --network soneium $TOKEN_ADDRESS "SoneiumToken" "SNT"

# Ajak gabung ke Airdrop Node
echo -e "\n🎉 **Selesai!** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
