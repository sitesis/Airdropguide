#!/bin/bash

# Fungsi untuk mengklon repositori
clone_repo() {
  echo "Mengklon repositori..."
  if [ ! -d "assisterr-daily-bot" ]; then
    git clone https://github.com/Widiskel/assisterr-daily-bot
  else
    echo "Repositori sudah diklon."
  fi
  cd assisterr-daily-bot || exit
}

# Fungsi untuk menginstal dependensi
install_dependencies() {
  echo "Menginstal dependensi dengan npm..."
  npm install
}

# Fungsi untuk menyalin file accounts
copy_account_file() {
  echo "Menyalin template accounts.js..."
  cp accounts/accounts_tmp.js accounts/accounts.js
}

# Fungsi untuk mengedit file accounts.js
edit_accounts() {
  echo "Buka file accounts.js dan tambahkan private key dompet Anda."
  nano accounts/accounts.js
}

# Fungsi untuk memulai aplikasi
start_app() {
  echo "Memulai aplikasi..."
  npm run start
}

# Fungsi untuk menampilkan pilihan kepada pengguna
show_menu() {
  echo "Pilih opsi:"
  echo "1. Clone repositori"
  echo "2. Install dependensi"
  echo "3. Copy file accounts"
  echo "4. Edit accounts.js"
  echo "5. Start aplikasi"
  echo "6. Exit"
}

# Main loop
while true; do
  show_menu
  read -p "Masukkan pilihan Anda: " choice
  case $choice in
    1) clone_repo ;;
    2) install_dependencies ;;
    3) copy_account_file ;;
    4) edit_accounts ;;
    5) start_app ;;
    6) exit 0 ;;
    *) echo "Pilihan tidak valid." ;;
  esac
done
