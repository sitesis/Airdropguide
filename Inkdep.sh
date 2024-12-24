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

# Install Hardhat, Ethers.js, OpenZeppelin, dotenv, dan Hardhat toolbox
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox ethers @openzeppelin/contracts dotenv
echo -e "\e[32mHardhat, Ethers.js, OpenZeppelin, dotenv, dan Hardhat toolbox telah diinstal.\e[0m"

# Inisialisasi proyek Hardhat
npx hardhat init -y
echo -e "\e[32mProyek Hardhat telah dibuat dengan konfigurasi kosong.\e[0m"

# Membuat folder contracts dan scripts
mkdir contracts && mkdir scripts
echo -e "\e[32mFolder 'contracts' dan 'scripts' telah dibuat.\e[0m"

# Meminta nama token dari pengguna
read -p "Masukkan nama token Anda: " TOKEN_NAME

# Membuat file kontrak dengan nama token yang diberikan
cat <<EOL > contracts/AirdropNodeToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNodeToken is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "${TOKEN_NAME^^}") {
        _mint(msg.sender, 5000000e18); // Mint 5 juta AirdropNode token untuk alamat deployer
    }
}
EOL
echo -e "\e[32mFile 'AirdropNodeToken.sol' telah dibuat di folder 'contracts' dengan nama token $TOKEN_NAME.\e[0m"

# Mengompilasi kontrak
npx hardhat compile
echo -e "\e[32mKontrak telah dikompilasi.\e[0m"

# Membuat file .env
touch .env
echo -e "\e[32mFile '.env' telah dibuat di direktori proyek.\e[0m"

# Memasukkan private key ke dalam .env
read -p "Masukkan Private Key Anda (tanpa '0x'): " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo -e "\e[32mPrivate Key telah dimasukkan ke file .env.\e[0m"

# Memasukkan API Key untuk Blockscout
read -p "Masukkan API Key untuk Blockscout: " BLOCKSCOUT_API_KEY
echo "BLOCKSCOUT_API_KEY=$BLOCKSCOUT_API_KEY" >> .env
echo -e "\e[32mAPI Key untuk Blockscout telah dimasukkan ke file .env.\e[0m"

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
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
  networks: {
    inksepolia: {
      url: process.env.INK_SEPOLIA_URL || "https://sepolia.infura.io/v3/<your_project_id>",
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
echo -e "\e[32mFile 'hardhat.config.js' telah diisi dengan konfigurasi Hardhat untuk Ink Sepolia.\e[0m"

# Membuat file deploy.js di folder scripts
cat <<EOL > scripts/deploy.js
async function main() {
  const InkContract = await ethers.getContractFactory("AirdropNodeToken");
  const contract = await InkContract.deploy();

  await contract.deployed();

  console.log("AirdropNodeToken deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOL
echo -e "\e[32mFile 'deploy.js' telah dibuat di folder 'scripts'.\e[0m"

# Menjalankan skrip deploy ke Ink Sepolia
echo -e "\e[33mMenjalankan skrip deploy...\e[0m"
DEPLOY_OUTPUT=$(npx hardhat run scripts/deploy.js --network inksepolia)

# Menampilkan output deploy
echo "$DEPLOY_OUTPUT"

# Menampilkan informasi penting
echo -e "\nProyek AirdropNode telah disiapkan dan kontrak telah dideploy!"

# Mendapatkan alamat token dari output deploy
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')

# Verifikasi kontrak setelah deployment
if [ -n "$TOKEN_ADDRESS" ]; then
    echo -e "\nVerifikasi kontrak di Ink Sepolia dengan perintah berikut:"
    echo "npx hardhat verify --network inksepolia $TOKEN_ADDRESS"
    # Menjalankan verifikasi kontrak
    npx hardhat verify --network inksepolia "$TOKEN_ADDRESS"
else
    echo "Tidak dapat menemukan alamat token yang sudah dideploy."
fi

# Menampilkan pesan untuk memeriksa alamat di explorer
if [ -n "$TOKEN_ADDRESS" ]; then
    echo -e "Silakan periksa alamat token Anda di explorer: https://explorer-sepolia.inkonchain.com/address/$TOKEN_ADDRESS"
else
    echo "Tidak dapat menemukan alamat token yang sudah dideploy."
fi

# Menampilkan pesan untuk bergabung dengan Airdrop Node
echo -e "\n🎉 **Selesai!** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
