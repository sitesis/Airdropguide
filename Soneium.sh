#!/bin/bash

# Fungsi untuk mencetak pesan dengan warna
print_color() {
    case $1 in
        "green") echo -e "\033[32m$2\033[0m" ;;  # Hijau
        "blue") echo -e "\033[34m$2\033[0m" ;;   # Biru
        "yellow") echo -e "\033[33m$2\033[0m" ;; # Kuning
        "red") echo -e "\033[31m$2\033[0m" ;;    # Merah
        "bold") echo -e "\033[1m$2\033[0m" ;;    # Tebal
        *) echo -e "$2" ;;                        # Default
    esac
}

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Mengecek apakah Node.js sudah terinstal
if command -v node >/dev/null 2>&1; then
    print_color "green" "Node.js sudah terinstal: $(node -v)"
else
    # Memperbarui daftar paket
    sudo apt update

    # Menginstal curl jika belum terinstal
    sudo apt install -y curl

    # Mengunduh dan menginstal Node.js versi terbaru menggunakan NodeSource
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    sudo apt install -y nodejs

    # Verifikasi instalasi
    print_color "green" "Node.js dan npm versi terbaru sudah terinstal."
    node -v
    npm -v
fi

# Membuat direktori proyek
PROJECT_DIR=~/soneium

if [ ! -d "$PROJECT_DIR" ];then
    mkdir "$PROJECT_DIR"
    print_color "green" "Direktori $PROJECT_DIR sudah dibuat."
else
    print_color "yellow" "Direktori $PROJECT_DIR sudah ada."
fi

# Masuk ke direktori proyek
cd "$PROJECT_DIR" || exit

# Inisialisasi proyek NPM
npm init -y
print_color "green" "Proyek NPM sudah diinisialisasi."

# Instalasi Hardhat, Ethers.js, OpenZeppelin, dan dotenv
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts dotenv
print_color "green" "Hardhat, Ethers.js, OpenZeppelin, dan dotenv sudah diinstal."

# Memulai proyek Hardhat
npx hardhat init -y
print_color "green" "Proyek Hardhat sudah dibuat dengan konfigurasi kosong."

# Membuat folder contracts dan scripts
mkdir contracts && mkdir scripts
print_color "green" "Folder 'contracts' dan 'scripts' sudah dibuat."

# Membuat file AirdropNode.sol
cat <<EOL > contracts/AirdropNode.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNode is ERC20 {
    constructor() ERC20("AirdropNode", "AND") {
        _mint(msg.sender, 1000000e18); // Mint 1 juta AirdropNode token ke alamat deployer
    }
}
EOL
print_color "green" "File 'AirdropNode.sol' sudah dibuat di folder 'contracts'."

# Mengkompilasi kontrak
npx hardhat compile
print_color "green" "Kontrak sudah dikompilasi."

# Membuat file .env
touch .env
print_color "green" "File '.env' sudah dibuat di direktori proyek."

# Meminta input private key dari pengguna
read -p "Masukkan private key Anda: " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
print_color "yellow" "Private key Anda sudah disimpan di file .env."

# Membuat file .gitignore
cat <<EOL > .gitignore
# Contoh kode .gitignore
# Node modules
node_modules/

# Environment variables
.env

# File Coverage
coverage/
coverage.json

# File hasil generate Typechain
typechain/
typechain-types/

# File Hardhat
cache/
artifacts/

# File build
build/
EOL
print_color "green" "File '.gitignore' sudah dibuat dengan contoh kode."

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
      url: "https://rpc.minato.soneium.org", // RPC URL untuk Soneium
      accounts: [PK],
    },
  },
};
EOL
print_color "green" "File 'hardhat.config.js' sudah diisi dengan konfigurasi Hardhat untuk Soneium."

# Membuat file deploy.js di folder scripts
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000000", "ether");

    const Token = await ethers.getContractFactory("AirdropNode");
    const token = await Token.deploy();

    console.log("Token deployed to:", token.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL
print_color "green" "File 'deploy.js' sudah dibuat di folder 'scripts'."

# Menjalankan skrip deploy
print_color "blue" "Menjalankan skrip deploy..."
DEPLOY_OUTPUT=$(npx hardhat run --network soneium scripts/deploy.js)

# Menampilkan output deploy
print_color "blue" "$DEPLOY_OUTPUT"

# Menampilkan informasi penting
print_color "green" "\nProyek Soneium sudah disiapkan dan kontrak sudah dideploy!"

# Mengambil alamat token dari output deploy
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')

# Menampilkan pesan untuk memeriksa alamat di explorer
if [ -n "$TOKEN_ADDRESS" ]; then
    print_color "blue" "Silakan periksa alamat token Anda di explorer: https://soneium.minato.blockscout.com/address/$TOKEN_ADDRESS"
else
    print_color "red" "Tidak dapat menemukan alamat token yang sudah dideploy."
fi

# Gabung ke Soneium Node
print_color "green" "\n🎉 **Selesai!** 🎉"
print_color "blue" "\n👉 **[Gabung Soneium Node](https://t.me/soneium_node)** 👈"
