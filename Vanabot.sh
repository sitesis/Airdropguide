#!/bin/bash

# Fungsi untuk mengecek dan menginstal Git jika belum terinstal
install_git() {
  if ! command -v git &> /dev/null
  then
      echo "Git tidak ditemukan, menginstal Git..."
      sudo apt-get update
      sudo apt-get install -y git
  else
      echo "Git sudah terinstal."
  fi
}

# Fungsi untuk mengecek dan menginstal Node.js jika belum terinstal
install_nodejs() {
  if ! command -v node &> /dev/null
  then
      echo "Node.js tidak ditemukan, menginstal Node.js..."
      sudo apt-get update
      sudo apt-get install -y nodejs npm
  else
      echo "Node.js sudah terinstal."
  fi
}

# Fungsi untuk mengatur variabel lingkungan TELEGRAM_APP_ID dan TELEGRAM_APP_HASH
set_telegram_credentials() {
  echo "Masukkan TELEGRAM_APP_ID:"
  read TELEGRAM_APP_ID
  echo "Masukkan TELEGRAM_APP_HASH:"
  read TELEGRAM_APP_HASH
}

# Fungsi untuk mengklon repositori proyek
clone_repo() {
  if [ ! -d "vana-data-hero-bot" ]; then
    git clone https://github.com/Widiskel/vana-data-hero-bot
  else
    echo "Proyek sudah diklon."
  fi
  cd vana-data-hero-bot || exit
}

# Fungsi untuk menjalankan instalasi npm
run_npm_install() {
  npm install
  npm i telegram@2.22.2
}

# Fungsi untuk membuat direktori 'accounts'
create_accounts_dir() {
  mkdir -p accounts
}

# Fungsi untuk menyalin file konfigurasi template
copy_config_files() {
  cp config/config_tmp.js config/config.js
  cp config/proxy_list_tmp.js config/proxy_list.js
}

# Fungsi untuk mengatur file config.js
configure_app() {
  echo "Menambahkan TELEGRAM_APP_ID dan TELEGRAM_APP_HASH ke config.js..."
  sed -i "s/YOUR_TELEGRAM_APP_ID/$TELEGRAM_APP_ID/" config/config.js
  sed -i "s/YOUR_TELEGRAM_APP_HASH/$TELEGRAM_APP_HASH/" config/config.js
}

# Fungsi untuk memulai aplikasi
start_app() {
  echo "Memulai bot..."
  npm run start
}

# Main script
install_git
install_nodejs
set_telegram_credentials
clone_repo
run_npm_install
create_accounts_dir
copy_config_files
configure_app
start_app
