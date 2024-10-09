#!/bin/bash

# Memeriksa apakah Node.js sudah terinstal
if command -v node >/dev/null 2>&1; then
    echo "Node.js sudah terinstal: $(node -v)"
else
    # Memperbarui daftar paket
    sudo apt update

    # Menginstal curl jika belum terinstal
    sudo apt install -y curl

    # Mengunduh dan menginstal Node.js menggunakan NodeSource
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt install -y nodejs

    # Memverifikasi instalasi
    echo "Node.js dan npm telah diinstal."
    node -v
    npm -v
    # Mengunduh dan menampilkan logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5  # Menambahkan delay 5 detik setelah logo
fi

# Membuat direktori proyek
PROJECT_DIR=~/ZenChainProject

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
echo "Proyek Hardhat telah dibuat dengan konfigurasi kosong."

# Membuat folder contracts dan scripts
mkdir contracts && mkdir scripts
echo "Folder 'contracts' dan 'scripts' telah dibuat."

# Membuat file AirdropNode.sol
cat <<EOL > contracts/AirdropNode.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNode is ERC20 {
    constructor(uint256 initialSupply) ERC20("AirdropNode", "NODE") {
        _mint(msg.sender, initialSupply);
    }
}
EOL
echo "File 'AirdropNode.sol' telah dibuat di folder 'contracts'."

# Mengompilasi kontrak
npx hardhat compile
echo "Kontrak telah dikompilasi."

# Membuat file .env
touch .env
echo "File '.env' telah dibuat di direktori proyek."

# Meminta pengguna untuk memasukkan kunci privat
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

module.exports = {
  solidity: "0.8.20",
  networks: {
    zenchain: {
      url: "https://zenchain-testnet.api.onfinality.io/public",  // ZenChain Testnet RPC URL
      chainId: 8408,  // ZenChain testnet chain ID
      accounts: [\`0x\${process.env.PRIVATE_KEY}\`],
    },
  },
};
EOL
echo "File 'hardhat.config.js' telah diisi dengan konfigurasi Hardhat untuk ZenChain."

# Membuat file deploy.js di folder scripts
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000", "ether");

    const Token = await ethers.getContractFactory("AirdropNode");
    const token = await Token.deploy(initialSupply);

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
DEPLOY_OUTPUT=$(npx hardhat run --network zenchain scripts/deploy.js)

# Menampilkan output deploy
echo "$DEPLOY_OUTPUT"

# Menampilkan informasi berguna
echo -e "\nProyek ZenChain telah disiapkan dan kontrak telah dideploy!"

# Mengambil alamat token dari output deploy
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')

# Menampilkan pesan untuk memeriksa alamat di explorer
if [ -n "$TOKEN_ADDRESS" ]; then
    echo -e "Silakan cek alamat token Anda di explorer: https://zentrace.io/address/$TOKEN_ADDRESS"
else
    echo "Tidak dapat menemukan alamat token yang dideploy."
fi

# Mengajak bergabung ke Airdrop Node
echo -e "\n🎉 **Done! ** 🎉"
echo -e "\n👉 **[Join Airdrop Node](https://t.me/airdrop_node)** 👈"
