#!/bin/bash

# Warna
MERAH="\033[1;31m"
HIJAU="\033[1;32m"
KUNING="\033[1;33m"
BIRU="\033[1;34m"
NOL="\033[0m" # Reset warna

# Skrip instalasi logo
echo -e "${HIJAU}Menampilkan logo...${NOL}"
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

echo -e "${HIJAU}Memperbarui sistem...${NOL}"
sudo apt update && sudo apt upgrade -y

echo -e "${KUNING}Menghapus file yang lama...${NOL}"
sudo rm -rf blockless-cli.tar.gz target

# Install Docker jika belum terpasang
if ! command -v docker &> /dev/null; then
    echo -e "${BIRU}Menginstal Docker...${NOL}"
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
else
    echo -e "${HIJAU}Docker sudah terpasang, melewati...${NOL}"
fi

# Install Docker Compose jika belum terpasang
if ! command -v docker-compose &> /dev/null; then
    echo -e "${BIRU}Menginstal Docker Compose...${NOL}"
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose.tmp
    if [[ -f /usr/local/bin/docker-compose ]]; then
        sudo rm /usr/local/bin/docker-compose
    fi
    sudo mv /usr/local/bin/docker-compose.tmp /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo -e "${HIJAU}Docker Compose sudah terpasang, melewati...${NOL}"
fi

# Membuat direktori target/release
echo -e "${KUNING}Membuat direktori target/release...${NOL}"
sudo mkdir -p target/release

# Mengunduh dan mengekstrak Blockless CLI
echo -e "${BIRU}Mengunduh dan mengekstrak Blockless CLI...${NOL}"
curl -s -L https://github.com/blocklessnetwork/cli/releases/download/v0.3.0/bls-linux-arm64-blockless-cli.tar.gz -o blockless-cli.tar.gz

# Verifikasi file telah terunduh
if [[ ! -f blockless-cli.tar.gz ]]; then
    echo -e "${MERAH}Error: File blockless-cli.tar.gz tidak ditemukan. Keluar...${NOL}"
    exit 1
fi

# Mengekstrak file
sudo tar -xzf blockless-cli.tar.gz --strip-components=3 -C target/release

# Verifikasi apakah file biner blockless-cli ada
if [[ ! -f target/release/blockless-cli ]]; then
    echo -e "${MERAH}Error: File biner blockless-cli tidak ditemukan di target/release. Keluar...${NOL}"
    exit 1
fi

# Meminta input pengguna untuk email dan kata sandi
read -p "Masukkan email Blockless Anda: " email
read -s -p "Masukkan kata sandi Blockless Anda: " password
echo

# Mengecek dan membuat kontainer Docker Blockless CLI jika belum ada
if ! sudo docker ps --filter "name=blockless-cli-container" | grep -q 'blockless-cli-container'; then
    echo -e "${HIJAU}Membuat kontainer Docker untuk Blockless CLI...${NOL}"
    sudo docker run -it --rm \
        --name blockless-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockless-cli --email "$email" --password "$password"
else
    echo -e "${HIJAU}Kontainer Blockless CLI sudah berjalan, melewati...${NOL}"
fi
