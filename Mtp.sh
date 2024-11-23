#!/bin/bash

# Script instalasi untuk multiple-cli dan multiple-node

# Periksa apakah script dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
  echo "Harap jalankan script ini sebagai root."
  exit 1
fi

# URL untuk mengunduh client
URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"

# Nama file hasil unduhan
FILE_NAME="multipleforlinux.tar"

# Direktori hasil ekstrak (folder yang sesuai dengan hasil ekstraksi)
EXTRACT_DIR="multipleforlinux"

# Fungsi untuk menangani kesalahan
handle_error() {
  echo "Terjadi kesalahan. Pastikan Anda memiliki koneksi internet dan ruang penyimpanan yang cukup."
  exit 1
}

# Unduh client
echo "Mengunduh client dari $URL..."
wget $URL -O $FILE_NAME || handle_error

# Ekstrak file di lokasi saat ini
echo "Mengekstrak file instalasi..."
tar -xvf $FILE_NAME || handle_error

# Cek apakah folder hasil ekstraksi benar-benar ada
if [ -d "$EXTRACT_DIR" ]; then
  echo "Folder $EXTRACT_DIR ditemukan, memberikan izin eksekusi pada multiple-cli dan multiple-node..."
  
  # Beri izin eksekusi pada file multiple-cli dan multiple-node
  chmod +x "$EXTRACT_DIR/multiple-cli" || handle_error
  chmod +x "$EXTRACT_DIR/multiple-node" || handle_error

  # Tambahkan direktori hasil ekstrak ke PATH
  echo "Menambahkan folder $EXTRACT_DIR ke PATH..."
  export PATH=$PATH:$(pwd)/$EXTRACT_DIR
  echo "export PATH=\$PATH:$(pwd)/$EXTRACT_DIR" >> ~/.bashrc

  # Terapkan perubahan PATH dengan memuat /etc/profile
  echo "Menerapkan perubahan PATH dengan 'source /etc/profile'..."
  source /etc/profile || handle_error

  # Kembali ke direktori root dan memberikan izin penuh (777) ke folder hasil ekstrak
  echo "Kembali ke direktori root dan memberikan izin 777 ke folder $EXTRACT_DIR..."
  cd / || handle_error
  chmod -R 777 "$EXTRACT_DIR" || handle_error
else
  echo "Folder hasil ekstrak $EXTRACT_DIR tidak ditemukan."
  echo "Mungkin ada kesalahan dalam proses ekstraksi atau nama folder yang berbeda."
  exit 1
fi

# Bersihkan file unduhan
echo "Membersihkan file instalasi sementara..."
rm -f $FILE_NAME

# Input untuk Unique Account Identifier dan PIN Code
echo "Masukkan Unique Account Identifier (XXXXXXX):"
read -r ACCOUNT_IDENTIFIER

echo "Masukkan PIN Code (XXXXXX):"
read -r PIN_CODE

# Menjalankan multiple-cli bind dengan parameter yang diberikan
echo "Mengikat akun dengan identifier $ACCOUNT_IDENTIFIER dan PIN Code yang diberikan..."
multiple-cli bind --bandwidth-download 100 --identifier "$ACCOUNT_IDENTIFIER" --pin "$PIN_CODE" --storage 200 --bandwidth-upload 100

# Mulai jalankan multiple-node di latar belakang
echo "Menjalankan multiple-node di latar belakang..."
nohup ./$EXTRACT_DIR/multiple-node > output.log 2>&1 &

# Selesai
echo "Instalasi selesai. Program multiple-node telah dijalankan di latar belakang."
echo "Log dapat ditemukan di 'output.log'."
