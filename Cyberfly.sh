#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Cyberfly Node Setup Script with Screen Session
# =======================================
# Script Di buat Oleh Airdrop Node
# =======================================

# Fungsi untuk mencetak header dengan format menarik
print_header() {
    echo ""
    echo "=============================================="
    echo " $1"
    echo "=============================================="
    echo ""
}

# Fungsi untuk mencetak pesan sukses
print_success() {
    echo ""
    echo "✅ $1"
    echo ""
}

# Fungsi untuk mencetak pesan error
print_error() {
    echo ""
    echo "❌ $1"
    echo ""
    exit 1
}

# Memastikan script dijalankan dengan sudo
if [ "$EUID" -ne 0 ]; then
    print_error "Harap jalankan script ini dengan sudo!"
fi

# Meminta input dari pengguna
print_header "Input Data Kadena Anda"
read -p "Masukkan Kadena Wallet Address Anda: " kadena_wallet_address
read -p "Masukkan Node Private Key Anda: " node_priv_key

# Verifikasi input pengguna
if [ -z "$kadena_wallet_address" ] || [ -z "$node_priv_key" ]; then
    print_error "Kadena Wallet Address dan Node Private Key tidak boleh kosong!"
fi

# Update sistem dan instalasi dasar
print_header "Update Sistem dan Instalasi Dependensi"
apt update && apt upgrade -y || print_error "Gagal melakukan update sistem!"
apt install -y git curl screen || print_error "Gagal menginstal dependensi dasar!"

# Clone repository Cyberfly
print_header "Mengunduh Repository Cyberfly Node"
git clone https://github.com/cyberfly-io/cyberfly-node-docker.git || print_error "Gagal mengunduh repository Cyberfly. Periksa koneksi internet Anda!"
cd cyberfly-node-docker || print_error "Gagal masuk ke direktori repository Cyberfly!"

# Update repository Cyberfly
print_header "Memperbarui Repository Cyberfly Node"
git pull || print_error "Gagal memperbarui repository Cyberfly!"

# Memberikan izin eksekusi pada script
print_header "Menyiapkan Script untuk Menjalankan Node"
chmod +x start_node.sh || print_error "Gagal memberikan izin eksekusi pada script!"

# Menjalankan node menggunakan screen
print_header "Menjalankan Node Cyberfly dalam Screen Session"
screen -dmS airdropnode_kadena ./start_node.sh k:"$kadena_wallet_address" "$node_priv_key" || print_error "Gagal menjalankan Cyberfly Node dalam screen session!"

# Pesan akhir
print_success "Node Cyberfly berhasil dijalankan di screen dengan nama 'airdropnode_kadena'!"
print_success "Pastikan Anda mencadangkan Node Private Key Anda: $node_priv_key"

echo "=============================================="
echo " Untuk melihat log node, jalankan perintah berikut:"
echo " screen -r airdropnode_kadena"
echo "=============================================="
