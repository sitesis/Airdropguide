#!/bin/bash

# Function to print messages in colors
print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

print_blue() {
    echo -e "\033[0;34m$1\033[0m"
}

print_yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

print_red() {
    echo -e "\033[0;31m$1\033[0m"
}

# Memeriksa apakah Node.js sudah terinstal
if command -v node >/dev/null 2>&1; then
    print_green "Node.js sudah terinstal: $(node -v)"
else
    # Memperbarui daftar paket
    sudo apt update

    # Menginstal curl jika belum terinstal
    sudo apt install -y curl

    # Mengunduh dan menginstal Node.js menggunakan NodeSource
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt install -y nodejs

    # Memverifikasi instalasi
    print_green "Node.js dan npm telah diinstal."
    node -v
    npm -v
fi

# Skrip instalasi logo

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Mengganti direktori proyek ke RomeProject
PROJECT_DIR=~/RomeProject

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir "$PROJECT_DIR"
    print_green "Direktori $PROJECT_DIR telah dibuat."
else
    print_yellow "Direktori $PROJECT_DIR sudah ada."
fi

# Masuk ke direktori proyek
cd "$PROJECT_DIR" || exit

# Menginisialisasi proyek NPM
npm init -y
print_green "Proyek NPM telah diinisialisasi."

# Menginstal Hardhat, Ethers.js, dan OpenZeppelin
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts dotenv
print_green "Hardhat, Ethers.js, dan OpenZeppelin telah diinstal."

# Memulai proyek Hardhat
npx hardhat init -y
print_green "Proyek Hardhat telah dibuat dengan konfigurasi kosong."

# Membuat folder contracts dan scripts
mkdir contracts && mkdir scripts
print_green "Folder 'contracts' dan 'scripts' telah dibuat."

# Meminta pengguna untuk memasukkan nama dan simbol token
read -p "$(print_blue "Masukkan nama token Anda: ")" TOKEN_NAME
read -p "$(print_blue "Masukkan simbol token Anda: ")" TOKEN_SYMBOL

# Meminta pengguna untuk memasukkan private key
read -sp "$(print_blue "Masukkan Private Key Anda: ")" PRIVATE_KEY
echo ""

# Menyimpan nama, simbol token, dan private key ke dalam file .env
echo "TOKEN_NAME=$TOKEN_NAME" > .env
echo "TOKEN_SYMBOL=$TOKEN_SYMBOL" >> .env
echo "PRIVATE_KEY=$PRIVATE_KEY" >> .env
print_green ".env telah diperbarui."

# Membuat file AirdropNode.sol
cat <<EOL > contracts/AirdropNode.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNode is ERC20 {
    constructor(uint256 initialSupply) ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, initialSupply);
    }
}
EOL
print_green "File 'AirdropNode.sol' telah dibuat di folder 'contracts'."

# Mengompilasi kontrak
npx hardhat compile
print_green "Kontrak telah dikompilasi."

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
print_green "File '.gitignore' telah dibuat dengan contoh kode."

# Membuat file hardhat.config.js
cat <<EOL > hardhat.config.js
/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.26",
  networks: {
    rome: {
      url: "https://rome.testnet.romeprotocol.xyz/",
      chainId: 200001, // Memperbarui ID rantai ke 200001 (Rome Testnet)
      accounts: [process.env.PRIVATE_KEY], // Menggunakan kunci pribadi dari variabel lingkungan
    },
  },
};
EOL
print_green "File 'hardhat.config.js' telah diisi dengan konfigurasi Hardhat untuk Rome."

# Membuat file deploy.js di folder scripts
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const TOKEN_NAME = process.env.TOKEN_NAME;
    const TOKEN_SYMBOL = process.env.TOKEN_SYMBOL;
    const initialSupply = ethers.utils.parseUnits("1000", "ether");  // Menentukan jumlah supply token yang akan dideploy

    // Mendapatkan signer yang akan digunakan untuk deploy
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Mendapatkan kontrak AirdropNode dan mendeply kontrak dengan parameter nama dan simbol token
    const Token = await ethers.getContractFactory("AirdropNode");
    const token = await Token.deploy(initialSupply);
    console.log(\`\${TOKEN_NAME} (\${TOKEN_SYMBOL}) token deployed to:\`, token.address);

    return token.address;
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL
print_green "File 'deploy.js' telah dibuat di folder 'scripts'."

# Menjalankan skrip deploy
print_yellow "Menjalankan skrip deploy..."
DEPLOY_OUTPUT=$(npx hardhat run --network rome scripts/deploy.js)

# Menampilkan output deploy
echo "$DEPLOY_OUTPUT"

# Menampilkan link hasil deploy di explorer
print_green "\nToken Anda telah berhasil dideploy. 

Cek token Anda di explorer: https://rome.testnet.romeprotocol.xyz:1000/tokens"

# Mengajak bergabung ke Airdrop Node
print_green "\n🎉 **Done! ** 🎉"
print_blue "\n👉 **[Join Airdrop Node](https://t.me/airdrop_node)** 👈"
