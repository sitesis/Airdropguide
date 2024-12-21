#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Warna untuk teks
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'  # Reset warna

# Simbol
INFO="🛠️"
CHECK="✅"
CROSS="❌"
FOLDER_ICON="📂"
DOWNLOAD_ICON="⬇️"
EXTRACT_ICON="📦"
EXECUTE_ICON="⚡"
SCREEN_ICON="🎥"

# Tentukan nama folder tempat direktori
FOLDER_NAME="intmax-mining"

# Menampilkan informasi pembuatan direktori
echo -e "\n${CYAN}${INFO} ${YELLOW}Membuat direktori $FOLDER_NAME jika belum ada...${RESET}\n"
if [ ! -d "$FOLDER_NAME" ]; then
    mkdir "$FOLDER_NAME"
    echo -e "${GREEN}${CHECK} Folder $FOLDER_NAME telah dibuat.${RESET}\n"
else
    echo -e "${GREEN}${CHECK} Folder $FOLDER_NAME sudah ada.${RESET}\n"
fi

# Berikan izin penuh pada folder
echo -e "${CYAN}${INFO} ${YELLOW}Memberikan izin penuh pada folder $FOLDER_NAME...${RESET}\n"
chmod 755 "$FOLDER_NAME"
echo -e "${GREEN}${CHECK} Izin folder $FOLDER_NAME telah diatur.${RESET}\n"

# Pindah ke dalam folder yang baru dibuat
cd "$FOLDER_NAME"

# Memperbarui sistem
echo -e "${CYAN}${INFO} ${YELLOW}Memperbarui dan meng-upgrade sistem...${RESET}\n"
sudo apt update -y && sudo apt upgrade -y
echo -e "${GREEN}${CHECK} Sistem telah diperbarui.${RESET}\n"

# Periksa apakah wget sudah terpasang, jika tidak, pasang
echo -e "${CYAN}${INFO} ${YELLOW}Memeriksa apakah wget terpasang...${RESET}\n"
if ! command -v wget &> /dev/null; then
    echo -e "${RED}${CROSS} wget tidak ditemukan. Menginstal wget...${RESET}\n"
    sudo apt install wget -y
else
    echo -e "${GREEN}${CHECK} wget sudah terpasang.${RESET}\n"
fi

# Periksa apakah unzip sudah terpasang, jika tidak, pasang
echo -e "${CYAN}${INFO} ${YELLOW}Memeriksa apakah unzip terpasang...${RESET}\n"
if ! command -v unzip &> /dev/null; then
    echo -e "${RED}${CROSS} unzip tidak ditemukan. Menginstal unzip...${RESET}\n"
    sudo apt install unzip -y
else
    echo -e "${GREEN}${CHECK} unzip sudah terpasang.${RESET}\n"
fi

# Periksa apakah chmod sudah terpasang, jika tidak, pasang
echo -e "${CYAN}${INFO} ${YELLOW}Memeriksa apakah chmod terpasang...${RESET}\n"
if ! command -v chmod &> /dev/null; then
    echo -e "${RED}${CROSS} chmod tidak ditemukan. Menginstal chmod...${RESET}\n"
    sudo apt install coreutils -y
else
    echo -e "${GREEN}${CHECK} chmod sudah terpasang.${RESET}\n"
fi

# Unduh file ZIP
echo -e "${CYAN}${INFO} ${YELLOW}Mengunduh mining-cli...${RESET}\n"
wget https://github.com/InternetMaximalism/intmax2-mining-cli/releases/download/v1.1.8/mining-cli-x86_64-unknown-linux-musl.zip

# Ekstrak file ZIP
echo -e "${CYAN}${INFO} ${YELLOW}Mengekstrak file mining-cli...${RESET}\n"
unzip mining-cli-x86_64-unknown-linux-musl.zip
echo -e "${GREEN}${CHECK} File telah diekstrak.${RESET}\n"

# Ubah izin file hasil ekstraksi agar dapat dijalankan
echo -e "${CYAN}${INFO} ${YELLOW}Memberikan izin eksekusi pada mining-cli...${RESET}\n"
chmod +x mining-cli
echo -e "${GREEN}${CHECK} Izin eksekusi telah diberikan.${RESET}\n"

# Periksa apakah screen sudah terpasang, jika tidak, pasang
echo -e "${CYAN}${INFO} ${YELLOW}Memeriksa apakah screen terpasang...${RESET}\n"
if ! command -v screen &> /dev/null; then
    echo -e "${RED}${CROSS} screen tidak ditemukan. Menginstal screen...${RESET}\n"
    sudo apt install screen -y
else
    echo -e "${GREEN}${CHECK} screen sudah terpasang.${RESET}\n"
fi

# Jalankan mining-cli di dalam sesi screen dengan nama airdropnode_intmax dan langsung masuk ke sesi screen
echo -e "${CYAN}${INFO} ${YELLOW}Menjalankan mining-cli di dalam sesi screen bernama airdropnode_intmax...${RESET}\n"
screen -S airdropnode_intmax -dm ./mining-cli
screen -r airdropnode_intmax

# Pesan selesai
echo -e "\n${CYAN}${INFO} ${YELLOW}Skrip selesai! Proses mining-cli berjalan di dalam screen session 'airdropnode_intmax'.${RESET}"

# Informasi tentang pembuat skrip
echo -e "\n${CYAN}${INFO} ${YELLOW}Dibuat oleh Airdrop Node. Gabung di Telegram: ${RESET} ${BLUE}https://t.me/airdrop_node${RESET}\n"
