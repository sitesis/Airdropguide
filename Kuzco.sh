#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Warna untuk output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

# Fungsi untuk menampilkan garis pembatas
print_line() {
    echo -e "${CYAN}============================================================${RESET}"
}

# Periksa apakah curl terinstal
print_line
echo -e "${YELLOW}🔍 Memeriksa apakah 'curl' sudah terinstal...${RESET}"
if ! command -v curl &> /dev/null; then
    echo -e "${RED}❗ 'curl' tidak ditemukan. Menginstal 'curl'...${RESET}"
    sudo apt update && sudo apt install -y curl
else
    echo -e "${GREEN}✅ 'curl' sudah terinstal.${RESET}"
fi

# Mengunduh dan menjalankan script instalasi dari kuzco.xyz
print_line
echo -e "${YELLOW}⬇️  Mengunduh dan menjalankan script instalasi dari 'kuzco.xyz'...${RESET}"
curl -fsSL https://kuzco.xyz/install.sh | sh
echo -e "${GREEN}✅ Instalasi selesai.${RESET}"

# Periksa apakah screen terinstal
print_line
echo -e "${YELLOW}🔍 Memeriksa apakah 'screen' sudah terinstal...${RESET}"
if ! command -v screen &> /dev/null; then
    echo -e "${RED}❗ 'screen' tidak ditemukan. Menginstal 'screen'...${RESET}"
    sudo apt update && sudo apt install -y screen
else
    echo -e "${GREEN}✅ 'screen' sudah terinstal.${RESET}"
fi

# Membuat screen dengan nama airdropnode_kuzco dan menjalankan kuzco init di dalamnya
print_line
echo -e "${YELLOW}🖥️  Membuat screen dengan nama 'airdropnode_kuzco' dan menjalankan 'kuzco init'...${RESET}"
screen -dmS airdropnode_kuzco bash -c 'kuzco init'
echo -e "${GREEN}✅ Screen 'airdropnode_kuzco' berhasil dibuat dan 'kuzco init' dijalankan.${RESET}"

print_line
echo -e "${CYAN}🎉 Proses instalasi selesai!${RESET}"
echo -e "${YELLOW}🔗 Gunakan perintah berikut untuk melihat proses:${RESET}"
echo -e "${GREEN}screen -r airdropnode_kuzco${RESET}"
print_line
