#!/bin/bash

# Menampilkan logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Mengecek apakah Node.js sudah terinstal
if command -v node >/dev/null 2>&1; then
    echo -e "\e[32mNode.js sudah terinstal: $(node -v)\e[0m"
else
    # Update daftar paket
    sudo apt update

    # Install curl jika belum terinstal
    sudo apt install -y curl

    # Download dan install Node.js versi terbaru
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    sudo apt install -y nodejs

    # Verifikasi instalasi
    echo -e "\e[32mNode.js dan npm versi terbaru telah terinstal.\e[0m"
    node -v
    npm -v
fi

# Membuat direktori proyek
PROJECT_DIR=~/AirdropNodeProject

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir "$PROJECT_DIR"
    echo -e "\e[32mDirektori $PROJECT_DIR telah dibuat.\e[0m"
else
    echo -e "\e[32mDirektori $PROJECT_DIR sudah ada.\e[0m"
fi

# Masuk ke direktori proyek
cd "$PROJECT_DIR" || exit

# Inisialisasi proyek NPM
npm init -y
echo -e "\e[32mProyek NPM telah diinisialisasi.\e[0m"

# Install Hardhat, Ethers.js, OpenZeppelin, dan dotenv
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts dotenv
echo -e "\e[32mHardhat, Ethers.js, OpenZeppelin, dan dotenv telah diinstal.\e[0m"

# Inisialisasi proyek Hardhat
npx hardhat init -y
echo -e "\e[32mProyek Hardhat telah dibuat dengan konfigurasi kosong.\e[0m"

# Membuat folder contracts dan scripts
mkdir contracts && mkdir scripts
echo -e "\e[32mFolder 'contracts' dan 'scripts' telah dibuat.\e[0m"

# Membuat file AirdropNodeToken.sol
cat <<EOL > contracts/AirdropNodeToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNodeToken is ERC20 {
    constructor() ERC20("AirdropNode", "AND") {
        _mint(msg.sender, 1000000e18); // Mint 1 juta AirdropNode token untuk alamat deployer
    }
}
EOL
echo -e "\e[32mFile 'AirdropNodeToken.sol' telah dibuat di folder 'contracts'.\e[0m"

# Mengompilasi kontrak
npx hardhat compile
echo -e "\e[32mKontrak telah dikompilasi.\e[0m"

# Membuat file .env
touch .env
echo -e "\e[32mFile '.env' telah dibuat di direktori proyek.\e[0m"

# Meminta input private key dari pengguna
read -p "Masukkan private key Anda: " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo -e "\e[32mPrivate key Anda telah disimpan di file .env.\e[0m"

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
echo -e "\e[32mFile '.gitignore' telah dibuat dengan contoh kode.\e[0m"

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
      url: "https://rpc.minato.soneium.org",  // URL RPC untuk Soneium yang diperbarui
      accounts: [PK],
    },
  },
};
EOL
echo -e "\e[32mFile 'hardhat.config.js' telah diisi dengan konfigurasi Hardhat untuk Soneium.\e[0m"

# Membuat file deploy.js di folder scripts
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000000", "ether");

    const Token = await ethers.getContractFactory("AirdropNodeToken");
    const token = await Token.deploy();

    console.log("Token dideploy ke:", token.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL
echo -e "\e[32mFile 'deploy.js' telah dibuat di folder 'scripts'.\e[0m"

# Menjalankan skrip deploy
echo -e "\e[33mMenjalankan skrip deploy...\e[0m"
DEPLOY_OUTPUT=$(npx hardhat run --network soneium scripts/deploy.js)

# Menampilkan output deploy
echo "$DEPLOY_OUTPUT"

# Menampilkan informasi penting
echo -e "\nProyek AirdropNode telah disiapkan dan kontrak telah dideploy!"

# Mendapatkan alamat token dari output deploy
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')

# Menampilkan pesan untuk memeriksa alamat di explorer
if [ -n "$TOKEN_ADDRESS" ]; then
    echo -e "Silakan periksa alamat token Anda di explorer: https://soneium-minato.blockscout.com/address/$TOKEN_ADDRESS"
else
    echo "Tidak dapat menemukan alamat token yang sudah dideploy."
fi

# Menampilkan pesan untuk bergabung dengan Airdrop Node
echo -e "\n🎉 **Selesai!** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
