#!/bin/bash

# Warna
MERAH="\033[1;31m"
HIJAU="\033[1;32m"
KUNING="\033[1;33m"
BIRU="\033[1;34m"
NOL="\033[0m" # Reset warna

# Menampilkan Logo Instalasi
echo -e "${HIJAU}Menampilkan logo...${NOL}"
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash || { echo -e "${MERAH}Gagal menampilkan logo.${NOL}"; exit 1; }
sleep 5

# Update Sistem
echo -e "${HIJAU}Memperbarui sistem...${NOL}"
apt update && apt upgrade -y || { echo -e "${MERAH}Gagal memperbarui sistem.${NOL}"; exit 1; }

# Menghapus File Lama
echo -e "${KUNING}Menghapus file yang lama...${NOL}"
rm -rf bls-cli.tar.gz target || { echo -e "${MERAH}Gagal menghapus file lama.${NOL}"; exit 1; }

# Instalasi Docker
if ! command -v docker &> /dev/null; then
    echo -e "${BIRU}Menginstal Docker...${NOL}"
    curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh && rm get-docker.sh || { echo -e "${MERAH}Gagal menginstal Docker.${NOL}"; exit 1; }
else
    echo -e "${HIJAU}Docker sudah terpasang, melewati...${NOL}"
fi

# Instalasi Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${BIRU}Menginstal Docker Compose...${NOL}"
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose.tmp
    [[ -f /usr/local/bin/docker-compose ]] && rm /usr/local/bin/docker-compose
    mv /usr/local/bin/docker-compose.tmp /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose || { echo -e "${MERAH}Gagal menginstal Docker Compose.${NOL}"; exit 1; }
else
    echo -e "${HIJAU}Docker Compose sudah terpasang, melewati...${NOL}"
fi

# Membuat Direktori Target
echo -e "${KUNING}Membuat direktori target/release...${NOL}"
mkdir -p target/release || { echo -e "${MERAH}Gagal membuat direktori target/release.${NOL}"; exit 1; }

# Unduh dan Ekstrak BLS CLI dari URL langsung
echo -e "${BIRU}Mengunduh dan mengekstrak BLS CLI...${NOL}"
curl -L -o bls-cli.tar.gz "https://github.com/blocklessnetwork/cli/releases/download/latest/bls-linux-x64-blockless-cli.tar.gz"

if [[ -f bls-cli.tar.gz ]]; then
    tar -xzf bls-cli.tar.gz --strip-components=3 -C target/release || { echo -e "${MERAH}Gagal mengekstrak BLS CLI.${NOL}"; exit 1; }
else
    echo -e "${MERAH}Gagal mengunduh arsip BLS CLI. Keluar...${NOL}"
    exit 1
fi

# Verifikasi Biner BLS CLI
if [[ ! -f target/release/bls ]]; then
    echo -e "${MERAH}Error: file biner bls tidak ditemukan di target/release. Keluar...${NOL}"
    exit 1
fi

# Masukkan Kredensial Pengguna
read -p "Masukkan email BLS Anda: " email
read -s -p "Masukkan kata sandi BLS Anda: " password
echo

# Jalankan Kontainer Docker untuk BLS CLI
if ! docker ps --filter "name=bls-cli-container" | grep -q 'bls-cli-container'; then
    echo -e "${HIJAU}Membuat kontainer Docker untuk BLS CLI...${NOL}"
    docker run -it --rm \
        --name bls-cli-container \
        -v "$(pwd)"/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./bls --email "$email" --password "$password" || { echo -e "${MERAH}Gagal menjalankan kontainer Docker.${NOL}"; exit 1; }
else
    echo -e "${HIJAU}Kontainer BLS CLI sudah berjalan, melewati...${NOL}"
fi
