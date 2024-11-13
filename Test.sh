#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Periksa apakah Node.js sudah terinstal
if command -v node >/dev/null 2>&1; then
    echo "Node.js sudah terinstal: $(node -v)"
else
    # Memperbarui daftar paket
    sudo apt update

    # Install curl jika belum terinstal
    sudo apt install -y curl

    # Unduh dan install Node.js versi terbaru menggunakan NodeSource
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    sudo apt install -y nodejs

    # Verifikasi instalasi Node.js
    echo "Node.js dan npm telah terinstal."
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

# Inisialisasi proyek NPM
npm init -y
echo "Proyek NPM telah diinisialisasi."

# Install Hardhat, Ethers.js, OpenZeppelin, dotenv, dan plugin etherscan
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts dotenv @nomiclabs/hardhat-verify
echo "Hardhat, Ethers.js, OpenZeppelin, dotenv, dan plugin etherscan telah diinstal."

# Inisialisasi proyek Hardhat
npx hardhat init -y
echo "Proyek Hardhat telah dibuat."

# Membuat folder contracts dan scripts
mkdir contracts && mkdir scripts
echo "Folder 'contracts' dan 'scripts' telah dibuat."

# Membuat file SoneiumToken.sol
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
echo "File 'SoneiumToken.sol' telah dibuat."

# Kompilasi kontrak
npx hardhat compile
echo "Kontrak telah dikompilasi."

# Membuat file .env
touch .env
echo "File '.env' telah dibuat."

# Meminta input private key dari pengguna
read -p "Masukkan private key Anda: " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo "Private key Anda telah disimpan di file .env."

# Meminta input API key untuk Blockscout dari pengguna
read -p "Masukkan API key Blockscout Anda: " ETHERSCAN_API_KEY
echo "ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY" >> .env
echo "API key Blockscout Anda telah disimpan di file .env."

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
echo "File '.gitignore' telah dibuat."

# Membuat file hardhat.config.js
cat <<EOL > hardhat.config.js
/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
require('@nomiclabs/hardhat-verify');

const PK = process.env.PRIVATE_KEY;
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY; // API key untuk Blockscout

module.exports = {
  solidity: "0.8.20",
  networks: {
    soneium: {
      url: "https://rpc.minato.soneium.org", // Soneium RPC URL
      accounts: [PK],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY // API key untuk Blockscout atau layanan serupa
  },
};
EOL
echo "File 'hardhat.config.js' telah dibuat."

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
echo "File 'deploy.js' telah dibuat."

# Menjalankan skrip deploy
echo "Menjalankan skrip deploy..."
DEPLOY_OUTPUT=$(npx hardhat run --network soneium scripts/deploy.js)

# Menampilkan output deploy
echo "$DEPLOY_OUTPUT"

# Memverifikasi kontrak
echo -e "\nMemverifikasi kontrak..."
npx hardhat verify --network soneium $TOKEN_ADDRESS "SoneiumToken" "SNT"

# Menampilkan informasi penting
echo -e "\nProyek Soneium telah disiapkan dan kontrak telah dideploy!"
