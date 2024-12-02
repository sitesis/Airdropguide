#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Kode warna
RED="\033[1;31m"
LIGHT_GREEN="\033[1;92m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

check_command_success() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌  Terjadi kesalahan. Periksa pesan di atas untuk detailnya.${RESET}"
        exit 1
    fi
}

# Periksa Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker belum terinstal. Silakan instal Docker terlebih dahulu.${RESET}"
    exit 1
else
    echo -e "${LIGHT_GREEN}✅ Docker sudah terinstal.${RESET}"
fi

# Periksa Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose belum terinstal. Silakan instal Docker Compose terlebih dahulu.${RESET}"
    exit 1
else
    echo -e "${LIGHT_GREEN}✅ Docker Compose sudah terinstal.${RESET}"
fi

# Input Private Key
echo -e "\n${CYAN}🔐  Masukkan Private Key Anda:${RESET}"
read -s YOUR_PRIVATE_KEY

# Validasi input
if [[ -z "$YOUR_PRIVATE_KEY" || ! "$YOUR_PRIVATE_KEY" =~ ^0x[a-fA-F0-9]{64}$ ]]; then
    echo -e "${RED}❌ Private Key tidak valid. Pastikan formatnya benar (64 karakter heksadesimal, dimulai dengan '0x').${RESET}"
    exit 1
fi

# Jalankan container Docker
CONTAINER_NAME="glacier-verifier"
IMAGE_NAME="docker.io/glaciernetwork/glacier-verifier:v0.0.3"

echo -e "\n${CYAN}🔄  Menjalankan Docker container dengan Private Key...${RESET}"
docker run -d -e PRIVATE_KEY="$YOUR_PRIVATE_KEY" --name "$CONTAINER_NAME" "$IMAGE_NAME"

if [ $? -eq 0 ]; then
    echo -e "${LIGHT_GREEN}✅  Docker container '$CONTAINER_NAME' berhasil dijalankan!${RESET}"
else
    echo -e "${RED}❌  Gagal menjalankan Docker container. Periksa log untuk detailnya.${RESET}"
    exit 1
fi

# Tampilkan log opsional
echo -e "\n${YELLOW}📋  Apakah Anda ingin melihat log container '$CONTAINER_NAME' sekarang? (y/n)${RESET}"
read -r SHOW_LOGS

if [[ "$SHOW_LOGS" =~ ^[Yy]$ ]]; then
    docker logs -f "$CONTAINER_NAME"
else
    echo -e "\n${LIGHT_GREEN}✅  Instalasi selesai. Anda dapat melihat log kapan saja dengan perintah:${RESET}"
    echo -e "${WHITE}     docker logs -f $CONTAINER_NAME${RESET}\n"
fi

# Informasi tambahan
echo -e "\n${CYAN}📢  Bergabunglah dengan channel Airdrop Node untuk update terbaru: ${WHITE}https://t.me/airdrop_node${RESET}"
