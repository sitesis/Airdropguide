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
sudo rm -rf bls-cli.tar.gz target

# Memastikan Docker terinstal
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

# Memastikan Docker Compose terinstal
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

# Menentukan nama target dan folder yang disesuaikan
TARGET_FILENAME="bls-linux-arm64-blockless-cli.tar.gz"  # Nama file target yang baru
TARGET_DIR="blockless-cli"  # Nama direktori tujuan

# Membuat direktori untuk target dan release
echo -e "${KUNING}Membuat direktori $TARGET_DIR/release...${NOL}"
sudo mkdir -p "$TARGET_DIR/release"

# Mengunduh dan mengekstrak file
LATEST_RELEASE_URL="https://github.com/blocklessnetwork/cli/releases/download/v0.3.0/$TARGET_FILENAME"
echo -e "${BIRU}Mengunduh dan mengekstrak $TARGET_FILENAME...${NOL}"
curl -L "$LATEST_RELEASE_URL" -o "$TARGET_FILENAME"

# Coba ekstrak ulang jika file binary tidak ditemukan
if ! sudo tar -xzf "$TARGET_FILENAME" --strip-components=1 -C "$TARGET_DIR/release"; then
    echo -e "${MERAH}Error: Ekstraksi file gagal, coba unduh ulang...${NOL}"
    rm -rf "$TARGET_FILENAME" "$TARGET_DIR"
    curl -L "$LATEST_RELEASE_URL" -o "$TARGET_FILENAME"
    if ! sudo tar -xzf "$TARGET_FILENAME" --strip-components=1 -C "$TARGET_DIR/release"; then
        echo -e "${MERAH}Error: Ekstraksi ulang gagal. Keluar...${NOL}"
        exit 1
    fi
fi

# Pengecekan lebih kuat untuk memastikan file binary ada
if [[ ! -f "$TARGET_DIR/release/bls" ]]; then
    echo -e "${MERAH}Error: file biner bls tidak ditemukan di $TARGET_DIR/release. Keluar...${NOL}"
    exit 1
else
    echo -e "${HIJAU}File binary bls ditemukan di $TARGET_DIR/release.${NOL}"
fi

# Mengubah prompt untuk email dan kata sandi Blockless
read -p "Masukkan email akun Blockless Anda: " email
read -s -p "Masukkan kata sandi akun Blockless Anda: " password
echo

# Membuat dan menjalankan kontainer Docker jika belum berjalan
if ! sudo docker ps --filter "name=bls-cli-container" | grep -q 'bls-cli-container'; then
    echo -e "${HIJAU}Membuat kontainer Docker untuk Blockless CLI...${NOL}"
    sudo docker run -it --rm \
        --name bls-cli-container \
        -v $(pwd)/"$TARGET_DIR/release":/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./bls --email "$email" --password "$password"
else
    echo -e "${HIJAU}Kontainer Blockless CLI sudah berjalan, melewati...${NOL}"
fi
