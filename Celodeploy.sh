#!/bin/bash

# Fungsi untuk membuat proyek dApp Celo Composer baru
buat_proyek_celo() {
  echo "Memulai pembuatan dApp Celo Composer..."
  echo "Masukkan nama proyek Anda: "
  read nama_proyek
  
  # Menjalankan perintah Celo Composer untuk membuat proyek
  npx @celo/celo-composer@latest create "$nama_proyek"
  
  echo "Apakah Anda ingin menggunakan Hardhat? (Y/n): "
  read gunakan_hardhat
  
  echo "Apakah Anda ingin menggunakan template? (Y/n): "
  read gunakan_template
  
  if [ "$gunakan_template" == "Y" ] || [ "$gunakan_template" == "y" ]; then
    echo "Pilih template (minipay/valora/social-connect): "
    read nama_template
  else
    nama_template=""
  fi

  echo "Masukkan nama pemilik proyek: "
  read pemilik_proyek

  # Setelah proyek dibuat, pindah ke direktori proyek
  cd "$nama_proyek" || exit

  # Ganti nama .env.template menjadi .env
  echo "Mengganti nama .env.template menjadi .env..."
  mv packages/react-app/.env.template packages/react-app/.env

  # Mengarahkan untuk mengisi file .env
  echo "Silakan edit file .env di packages/react-app/.env dengan variabel lingkungan Anda."

  # Instal dependensi
  echo "Menginstal dependensi..."
  cd packages/react-app || exit
  yarn install

  # Memulai server pengembangan
  echo "Memulai server pengembangan..."
  yarn dev
}

# Fungsi untuk inisialisasi dan konfigurasi Hardhat khusus untuk Alfajores
konfigurasi_hardhat_alfajores() {
  echo "Inisialisasi Hardhat..."
  
  # Inisialisasi Hardhat di dalam proyek
  npx hardhat init
  
  # Instal Hardhat Toolbox
  echo "Menginstal @nomicfoundation/hardhat-toolbox..."
  npm install --save-dev @nomicfoundation/hardhat-toolbox
  
  # Tambahkan konfigurasi untuk jaringan Alfajores saja
  echo "Menambahkan konfigurasi jaringan Alfajores ke hardhat.config.js..."
  
  cat <<EOL >> hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.4",
  networks: {
    alfajores: {
      url: "https://alfajores-forno.celo-testnet.org",
      accounts: ["<YOUR_PRIVATE_KEY>"],
      chainId: 44787,
    }
  },
  etherscan: {
    apiKey: {
      alfajores: "<CELOSCAN_API_KEY>"
    },
    customChains: [
      {
        network: "alfajores",
        chainId: 44787,
        urls: {
          apiURL: "https://api-alfajores.celoscan.io/api",
          browserURL: "https://alfajores.celoscan.io",
        },
      }
    ]
  }
};
EOL

  echo "Konfigurasi jaringan Alfajores selesai."
  echo "Silakan lengkapi kunci privat dan CELOSCAN API Key di hardhat.config.js."
}

# Jalankan fungsi
buat_proyek_celo
konfigurasi_hardhat_alfajores
