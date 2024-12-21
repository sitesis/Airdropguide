#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Kode warna untuk teks
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'  # Reset warna

# Memperbarui dan meng-upgrade paket sistem
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Memperbarui dan meng-upgrade sistem...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
sudo apt update && sudo apt upgrade -y

# Menginstal dependensi yang diperlukan (wget, unzip, screen, libssl-dev)
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Menginstal dependensi yang diperlukan...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
sudo apt install -y wget unzip screen libssl-dev

# Mengunduh file ZIP dari GitHub
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Mengunduh mining-cli...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
wget https://github.com/InternetMaximalism/intmax2-mining-cli/releases/download/v1.1.8/mining-cli-x86_64-unknown-linux-musl.zip

# Mengekstrak file ZIP
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Mengekstrak file ZIP...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
unzip mining-cli-x86_64-unknown-linux-musl.zip

# Memberikan izin eksekusi
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Memberikan izin eksekusi...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
chmod +x mining-cli-x86_64-unknown-linux-musl

# Mengecek apakah sesi screen bernama 'airdropnode_intmax' sudah ada
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Mengecek sesi screen 'airdropnode_intmax'...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
if ! screen -list | grep -q "airdropnode_intmax"; then
  echo -e "\n${YELLOW}Sesi screen 'airdropnode_intmax' tidak ditemukan. Membuat sesi baru...${RESET}"
  screen -dmS airdropnode_intmax
else
  echo -e "\n${YELLOW}Sesi screen 'airdropnode_intmax' ditemukan.${RESET}"
fi

# Menjalankan mining-cli di dalam screen
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Menjalankan mining-cli di dalam screen...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
screen -S airdropnode_intmax -X stuff "./mining-cli-x86_64-unknown-linux-musl\n"

# Memberikan informasi bahwa skrip telah dijalankan di dalam screen
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Skrip telah dijalankan di dalam screen bernama 'screen -r airdropnode_intmax'.${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
