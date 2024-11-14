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

# Memperbarui sistem
echo -e "${HIJAU}Memperbarui sistem...${NOL}"
sudo apt update && sudo apt upgrade -y || { echo -e "${MERAH}Gagal memperbarui sistem${NOL}"; exit 1; }

# Menghapus file lama
echo -e "${KUNING}Menghapus file yang lama...${NOL}"
rm -rf bls-linux-x64-blockless-cli.tar.gz target

# Memeriksa dan menginstal Docker jika belum terpasang
if ! command -v docker &> /dev/null; then
    echo -e "${BIRU}Menginstal Docker...${NOL}"
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release || { echo -e "${MERAH}Gagal menginstal prasyarat Docker${NOL}"; exit 1; }
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io || { echo -e "${MERAH}Gagal menginstal Docker${NOL}"; exit 1; }
else
    echo -e "${HIJAU}Docker sudah terpasang, melewati...${NOL}"
fi

# Memeriksa dan menginstal Docker Compose jika belum terpasang
if ! command -v docker-compose &> /dev/null; then
    echo -e "${BIRU}Menginstal Docker Compose...${NOL}"
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose.tmp
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
mkdir -p target/release

# Mengunduh dan mengekstrak Blockless CLI
echo -e "${BIRU}Mengunduh dan mengekstrak Blockless CLI...${NOL}"
# Menggunakan API GitHub untuk mendapatkan URL unduhan file terbaru
curl -s https://api.github.com/repos/blocklessnetwork/cli/releases/latest \
| grep -oP '"browser_download_url": "\K(.*bls-linux-x64-blockless-cli.tar.gz)' \
| xargs curl -L -o target/release/bls-linux-x64-blockless-cli.tar.gz

if [ -f target/release/bls-linux-x64-blockless-cli.tar.gz ]; then
    echo -e "${HIJAU}Mengekstrak bls-linux-x64-blockless-cli.tar.gz ke target/release...${NOL}"
    tar -xzf target/release/bls-linux-x64-blockless-cli.tar.gz --strip-components=3 -C target/release
else
    echo -e "${MERAH}Error: File bls-linux-x64-blockless-cli.tar.gz tidak ditemukan. Keluar...${NOL}"
    exit 1
fi

# Verifikasi apakah file binary ada dan memiliki izin eksekusi
if [[ -f target/release/bls_x64-linux ]]; then
    echo -e "${HIJAU}Verifikasi: file bls_x64-linux ditemukan.${NOL}"
    if [[ ! -x target/release/bls_x64-linux ]]; then
        echo -e "${KUNING}Menambahkan izin eksekusi ke bls_x64-linux...${NOL}"
        chmod +x target/release/bls_x64-linux
    fi
    
else
    echo -e "${MERAH}Error: file biner bls_x64-linux tidak ditemukan di target/release. Keluar...${NOL}"
    exit 1
fi

else
    echo -e "${MERAH}Error: file biner bls-linux-x64-blockless-cli tidak ditemukan di target/release. Keluar...${NOL}"
    exit 1
fi

# Meminta input pengguna untuk kredensial Blockless
read -p "Masukkan email Blockless Anda: " email
read -s -p "Masukkan kata sandi Blockless Anda: " password
echo

# Memeriksa apakah kontainer Docker untuk Blockless CLI sudah berjalan
if ! docker ps --filter "name=bls-linux-x64-blockless-cli-container" | grep -q 'bls-linux-x64-blockless-cli-container'; then
    echo -e "${HIJAU}Membuat kontainer Docker untuk bls-linux-x64-blockless-cli...${NOL}"
    docker run -it --rm \
        --name bls-linux-x64-blockless-cli-container \
        -v "$(pwd)"/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./bls-linux-x64-blockless-cli --email "$email" --password "$password"
else
    echo -e "${HIJAU}Kontainer bls-linux-x64-blockless-cli sudah berjalan, melewati...${NOL}"
fi

# Menghapus variabel sensitif setelah digunakan
unset password
