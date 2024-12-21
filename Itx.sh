#!/bin/bash

# Kode warna untuk teks
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'  # Reset warna

# File log untuk mencatat aktivitas
LOG_FILE="script_log.txt"
exec > >(tee -i "$LOG_FILE") 2>&1

# Fungsi untuk menangani kesalahan
error_exit() {
  echo -e "${RED}Terjadi kesalahan: $1${RESET}"
  exit 1
}

# Memperbarui dan meng-upgrade paket sistem
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Memperbarui dan meng-upgrade sistem...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
sudo apt update && sudo apt upgrade -y || error_exit "Gagal memperbarui sistem."

# Menginstal dependensi yang diperlukan
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Menginstal dependensi yang diperlukan...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
sudo apt install -y wget unzip screen libssl-dev || error_exit "Gagal menginstal dependensi."

# Mengunduh file ZIP dari GitHub
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Mengunduh mining-cli...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
wget -q https://github.com/InternetMaximalism/intmax2-mining-cli/releases/download/v1.1.8/mining-cli-x86_64-unknown-linux-musl.zip || error_exit "Gagal mengunduh file ZIP."

# Mengekstrak file ZIP
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Mengekstrak file ZIP...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
unzip -q mining-cli-x86_64-unknown-linux-musl.zip || error_exit "Gagal mengekstrak file ZIP."

# Memberikan izin eksekusi
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Memberikan izin eksekusi...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
chmod +x mining-cli-x86_64-unknown-linux-musl || error_exit "Gagal memberikan izin eksekusi."

# Membersihkan file sementara
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Membersihkan file sementara...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
rm mining-cli-x86_64-unknown-linux-musl.zip || error_exit "Gagal menghapus file sementara."

# Mengecek apakah sesi screen bernama 'airdropnode_intmax' sudah ada
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Mengecek sesi screen 'airdropnode_intmax'...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
if ! screen -list | grep -q "airdropnode_intmax"; then
  echo -e "\n${YELLOW}Sesi screen 'airdropnode_intmax' tidak ditemukan. Membuat sesi baru...${RESET}"
  screen -dmS airdropnode_intmax || error_exit "Gagal membuat sesi screen."
else
  echo -e "\n${YELLOW}Sesi screen 'airdropnode_intmax' ditemukan.${RESET}"
fi

# Menjalankan mining-cli di dalam screen
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Menjalankan mining-cli di dalam screen...${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
screen -S airdropnode_intmax -X stuff "./mining-cli-x86_64-unknown-linux-musl\n" || error_exit "Gagal menjalankan mining-cli di dalam screen."

# Memberikan informasi bahwa skrip telah dijalankan di dalam screen
echo -e "\n${CYAN}════════════════════════════════════════════════════${RESET}"
echo -e "${GREEN}Skrip telah dijalankan di dalam screen bernama 'airdropnode_intmax'.${RESET}"
echo -e "${CYAN}════════════════════════════════════════════════════${RESET}"
