#!/bin/bash

# Skrip otomatis untuk menginstal dan mengatur Privasea Acceleration Node

# Warna output
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# Fungsi untuk menampilkan pesan sukses
function success_message {
    echo -e "${GREEN}[✔] $1${NC}"
}

# Fungsi untuk menampilkan pesan proses
function info_message {
    echo -e "${CYAN}[-] $1...${NC}"
}

# Fungsi untuk menampilkan pesan kesalahan
function error_message {
    echo -e "${RED}[✘] $1${NC}"
}

clear
echo -e "${CYAN}========================================"
echo "   Privasea Acceleration Node Setup"
echo -e "========================================${NC}"
echo ""

# Langkah 1: Tarik gambar Docker
info_message "Mengunduh gambar Docker"
if docker pull privasea/acceleration-node-beta:latest; then
    success_message "Gambar Docker berhasil diunduh"
else
    error_message "Gagal mengunduh gambar Docker"
    exit 1
fi

echo ""

# Langkah 2: Buat direktori konfigurasi
info_message "Membuat direktori konfigurasi"
if mkdir -p $HOME/privasea/config; then
    success_message "Direktori konfigurasi berhasil dibuat"
else
    error_message "Gagal membuat direktori konfigurasi"
    exit 1
fi

echo ""

# Langkah 3: Buat file keystore
info_message "Membuat file keystore"
if docker run -it -v "$HOME/privasea/config:/app/config" \
privasea/acceleration-node-beta:latest ./node-calc new_keystore; then
    success_message "File keystore berhasil dibuat"
else
    error_message "Gagal membuat file keystore"
    exit 1
fi

echo ""

# Langkah 4: Pindahkan file keystore ke nama baru
info_message "Memindahkan file keystore"
if mv $HOME/privasea/config/UTC--* $HOME/privasea/config/wallet_keystore; then
    success_message "File keystore berhasil dipindahkan ke wallet_keystore"
else
    error_message "Gagal memindahkan file keystore"
    exit 1
fi

echo ""

# Langkah akhir
echo -e "${GREEN}========================================"
echo "   Instalasi Selesai"
echo -e "========================================${NC}"
echo ""
echo -e "${CYAN}File konfigurasi tersedia di:${NC} $HOME/privasea/config"
echo -e "${CYAN}Keystore disimpan sebagai:${NC} wallet_keystore"
echo ""
