#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e 

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

# Membuat direktori proyek
PROJECT_DIR=~/TestToken

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

# Mengunduh dan menjalankan script tambahan
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash

sleep 2

# Menginstal Hardhat, Ethers.js, dan OpenZeppelin
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts
echo "Hardhat, Ethers.js, dan OpenZeppelin telah diinstal."

# Memulai proyek Hardhat
npx hardhat <<< "Create an empty hardhat.config.js"
echo "Proyek Hardhat telah dibuat dengan konfigurasi kosong."

# Membuat folder contracts dan scripts
mkdir contracts && mkdir scripts
echo "Folder 'contracts' dan 'scripts' telah dibuat."

# Membuat file MyToken.sol
cat <<EOL > contracts/MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Mytoken", "MTK") {
        _mint(msg.sender, initialSupply);
    }
}
EOL
echo "File 'MyToken.sol' telah dibuat di folder 'contracts'."

# Mengompilasi kontrak
npx hardhat compile
echo "Kontrak telah dikompilasi."

# Menginstal paket dotenv
npm install dotenv
echo "Paket dotenv telah diinstal."

# Membuat file .env
touch .env
echo "File '.env' telah dibuat di direktori proyek."

# Menyuruh pengguna untuk menambahkan kunci privat
echo "Silakan tambahkan baris berikut ke file .env:"
echo "PRIVATE_KEY=your_exported_private_key"
echo "Setelah selesai, simpan dan keluar dari nano dengan Ctrl + X, lalu Y, kemudian Enter."

# Membuat file .gitignore
cat <<EOL > .gitignore
# Sample .gitignore code
# Node modules
node_modules

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
EOL
echo "File '.gitignore' telah dibuat dengan contoh kode."

# Membuat file hardhat.config.js
cat <<EOL > hardhat.config.js
/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");

const SONIC_PRIVATE_KEY = "YOUR SONIC TEST ACCOUNT PRIVATE KEY";

module.exports = {
  solidity: "0.8.19",
  networks: {
    sonic: {
      url: "https://rpc.testnet.soniclabs.com",
      accounts: [SONIC_PRIVATE_KEY]
    }
  }
};
EOL
echo "File 'hardhat.config.js' telah diisi dengan konfigurasi Hardhat yang baru."

# Membuat file deploy.js di folder scripts
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();
    const initialSupply = ethers.utils.parseUnits("1000", "ether");

    const Token = await ethers.getContractFactory("MyToken");
    const token = await Token.deploy(initialSupply);

    console.log("Token deployed to:", token.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL
echo "File 'deploy.js' telah dibuat di folder 'scripts'."

# Menjalankan skrip deploy.js di jaringan sonic
npx hardhat run scripts/deploy.js --network sonic
echo "Skrip deploy.js telah dijalankan di jaringan sonic."

echo "Bergabunglah dengan airdrop node di https://t.me/airdrop_node"
