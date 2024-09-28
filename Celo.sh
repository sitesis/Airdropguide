#!/bin/bash

# Fungsi untuk menginstal Node.js dan npm
install_nodejs_npm() {
  echo "Menginstal Node.js dan npm..."
  
  # Menghapus versi Node.js yang mungkin sudah ada
  sudo apt-get remove -y nodejs npm
  
  # Menginstal Node.js versi LTS (misalnya, versi 16.x)
  curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
  sudo apt-get install -y nodejs
  
  # Memverifikasi instalasi Node.js dan npm
  node_version=$(node -v)
  npm_version=$(npm -v)
  echo "Node.js versi $node_version terinstal."
  echo "npm versi $npm_version terinstal."
}

# Fungsi untuk membuat proyek Hardhat baru dengan nama celodeploy
create_hardhat_project() {
  project_dir="celodeploy"
  
  echo "Membuat proyek Hardhat di direktori $project_dir..."
  
  # Membuat direktori proyek
  mkdir -p $project_dir
  cd $project_dir
  
  # Menginisialisasi proyek Node.js
  echo "Inisialisasi proyek Node.js..."
  npm init -y
  
  # Menginstal Hardhat secara lokal di proyek
  echo "Menginstal Hardhat..."
  npm install --save-dev hardhat
  
  # Menginisialisasi proyek Hardhat
  echo "Inisialisasi proyek Hardhat..."
  npx hardhat
  
  # Menginstal dependensi lain yang diperlukan
  echo "Menginstal dependensi yang diperlukan..."
  npm install --save-dev @nomicfoundation/hardhat-toolbox dotenv
}

# Fungsi untuk menambahkan konfigurasi ke dalam hardhat.config.js
configure_hardhat() {
  echo "Menambahkan konfigurasi ke dalam hardhat.config.js..."
  
  # Membuat file hardhat.config.js dengan konfigurasi Celo Alfajores
  cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: [process.env.PRIVATE_KEY], // Ambil private key dari .env
    },
  },
};
EOL

  echo "Konfigurasi hardhat.config.js telah dibuat!"
}

# Fungsi untuk membuat file .env
create_env_file() {
  echo "Membuat file .env..."
  touch .env
  
  # Meminta pengguna untuk memasukkan private key
  read -p "Masukkan private key Anda: " private_key
  
  # Menambahkan private key ke file .env
  echo "PRIVATE_KEY=$private_key" > .env
  
  echo "File .env telah dibuat dengan private key Anda!"
}

# Fungsi untuk membuat skrip deploy.js
create_deploy_script() {
  echo "Membuat skrip deploy di scripts/deploy.js..."

  mkdir -p scripts

  cat <<EOL > scripts/deploy.js
const hre = require("hardhat");

async function main() {
  // Mengambil akun yang digunakan untuk melakukan deploy
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Mendapatkan saldo akun
  const balance = await deployer.getBalance();
  console.log("Account balance:", hre.ethers.utils.formatEther(balance), "ETH");

  // Mengambil kontrak Token dan mendeplynya
  const Token = await hre.ethers.getContractFactory("Token");
  const token = await Token.deploy();

  // Menunggu hingga kontrak dideploy
  await token.deployed();
  console.log("Token deployed to:", token.address);
}

// Menjalankan fungsi utama dan menangani error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOL

  echo "Skrip deploy.js telah dibuat di folder scripts!"
}

# Fungsi untuk memverifikasi kontrak
verify_contract() {
  read -p "Masukkan alamat kontrak yang dideploy: " contract_address
  read -p "Masukkan argumen constructor (misalnya, '0x0D6Dc2f182Eafa687090F95466d5368726C1ca45'): " constructor_args
  
  echo "Verifikasi kontrak di jaringan Alfajores..."
  
  npx hardhat verify --network alfajores $contract_address $constructor_args
}

# Fungsi untuk membuat file .gitignore
create_gitignore() {
  echo "Membuat file .gitignore..."
  
  cat <<EOL > .gitignore
# Node.js dependencies
node_modules/

# Hardhat artifacts
artifacts/
cache/

# Environment variables file
.env

# Logs
logs/
npm-debug.log*
yarn-debug.log*
EOL

  echo "File .gitignore telah dibuat!"
}

# Fungsi untuk menampilkan informasi tentang bergabung di channel Telegram
join_telegram_channel() {
  echo "Proses selesai!"
  echo "Anda telah berhasil mengatur proyek Hardhat dan siap untuk mendeply kontrak."
  echo "Jangan lupa untuk bergabung di channel Telegram Airdrop Node untuk mendapatkan informasi terbaru dan dukungan:"
  echo "👉 https://t.me/airdrop_node"
}

# Fungsi utama untuk menjalankan semua langkah
main() {
  install_nodejs_npm
  create_hardhat_project
  configure_hardhat
  create_env_file
  create_deploy_script
  create_gitignore # Tambahkan pemanggilan fungsi di sini
  
  echo "Proses instalasi, konfigurasi, dan pembuatan skrip deploy selesai!"
  echo "Silakan jalankan 'npx hardhat run scripts/deploy.js --network alfajores' untuk mendeply kontrak."

  # Verifikasi kontrak setelah deploy
  read -p "Apakah Anda ingin memverifikasi kontrak sekarang? (y/n): " verify_choice
  if [[ "$verify_choice" == "y" ]]; then
    verify_contract
  fi
  
  # Memanggil fungsi join_telegram_channel
  join_telegram_channel
}

# Memulai script
main
