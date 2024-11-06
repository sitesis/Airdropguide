#!/bin/bash

# Warna
NC='\033[0m'        # No Color
RED='\033[0;31m'    # Merah
GREEN='\033[0;32m'  # Hijau
YELLOW='\033[0;33m' # Kuning
BLUE='\033[0;34m'   # Biru
CYAN='\033[0;36m'   # Cyan
BOLD='\033[1m'      # Tebal

# Instalasi Logo
echo -e "${CYAN}=== Memuat Logo... ===${NC}"
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Update dan Upgrade Sistem
echo -e "\n${YELLOW}=== Memperbarui dan Meng-upgrade Sistem... ===${NC}"
sudo apt update && sudo apt upgrade -y

# Periksa dan Install jq
echo -e "\n${YELLOW}=== Memeriksa 'jq'... ===${NC}"
if ! command -v jq &> /dev/null; then
    echo -e "${RED}'jq' tidak terpasang. Menginstall...${NC}"
    sudo apt install jq -y
else
    echo -e "${GREEN}'jq' sudah terpasang.${NC}"
fi

# Periksa Docker & Docker Compose
echo -e "\n${YELLOW}=== Memeriksa Docker dan Docker Compose... ===${NC}"
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Docker atau Docker Compose tidak ditemukan. Harap instalasi terlebih dahulu.${NC}"
    exit 1
fi

# Clone Repositori Git Ink
echo -e "\n${CYAN}=== Meng-clone Repositori Git Ink... ===${NC}"
if git clone https://github.com/inkonchain/node; then
    echo -e "${GREEN}Repositori berhasil di-clone.${NC}"
else
    echo -e "${RED}Gagal meng-clone repositori. Periksa URL dan koneksi internet.${NC}"
    exit 1
fi

# Masuk ke Direktori Ink
echo -e "\n${CYAN}=== Memasuki Direktori Ink... ===${NC}"
cd node || { echo -e "${RED}Gagal masuk ke direktori.${NC}"; exit 1; }

# Pilihan untuk Memasukkan Private Key
echo -e "\n${YELLOW}=== Memasukkan Private Key ===${NC}"
read -p "Apakah Anda ingin memasukkan private key Anda? (y/n): " user_input

if [ "$user_input" == "y" ] || [ "$user_input" == "Y" ]; then
    # Meminta Input Private Key
    echo -e "\n${YELLOW}=== Masukkan Private Key Anda: ===${NC}"
    read -s -p "Private Key: " private_key
    echo

    # Pastikan Direktori var/secrets Ada
    mkdir -p var/secrets

    # Menyimpan Private Key ke file var/secrets/jwt.txt
    echo -e "\n${CYAN}=== Menyimpan Private Key ke var/secrets/jwt.txt ===${NC}"
    echo "$private_key" > var/secrets/jwt.txt
    echo -e "${GREEN}Private Key berhasil disimpan di var/secrets/jwt.txt.${NC}"
else
    echo -e "${YELLOW}Private key tidak dimasukkan.${NC}"
fi

# Membuat File .env
echo -e "\n${CYAN}=== Membuat File .env dengan Konfigurasi... ===${NC}"
cat <<EOL > .env
L1_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
L1_BEACON_URL=https://ethereum-sepolia-beacon-api.publicnode.com
EOL
echo -e "${GREEN}File .env berhasil dibuat.${NC}"

# Jalankan Setup
echo -e "\n${CYAN}=== Menjalankan Skrip Setup... ===${NC}"
if [ -f "./setup.sh" ]; then
    ./setup.sh && echo -e "${GREEN}Skrip setup berhasil dijalankan.${NC}"
else
    echo -e "${RED}Skrip setup.sh tidak ditemukan. Pastikan skrip ini ada di direktori.${NC}"
    exit 1
fi

# Mulai Node dengan Docker Compose
echo -e "\n${CYAN}=== Memulai Node dengan Docker Compose... ===${NC}"
if [ -f "docker-compose.yml" ]; then
    docker-compose up -d
    echo -e "${GREEN}Node berhasil dijalankan.${NC}"
else
    echo -e "${RED}File docker-compose.yml tidak ditemukan.${NC}"
    exit 1
fi

# Verifikasi Status Sinkronisasi
echo -e "\n${YELLOW}=== Memverifikasi Status Sinkronisasi... ===${NC}"
sync_status=$(curl -X POST -H "Content-Type: application/json" --data \
    '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
    http://localhost:9545 | jq)

echo -e "${CYAN}Status sinkronisasi: $sync_status${NC}"

# Ambil Nomor Blok Finalisasi
echo -e "\n${YELLOW}=== Mengecek Nomor Blok Finalisasi Lokal dan Jarak Jauh... ===${NC}"
local_block=$(curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized", false],"id":1}' \
  | jq -r .result.number | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')

remote_block=$(curl -s -X POST https://rpc-gel-sepolia.inkonchain.com/ -H "Content-Type: application/json" \
 --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized", false],"id":1}' \
 | jq -r .result.number | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')

echo -e "${CYAN}Blok finalisasi lokal: $local_block${NC}"
echo -e "${CYAN}Blok finalisasi jarak jauh: $remote_block${NC}"

# Perbandingan Blok
if [ "$local_block" -eq "$remote_block" ]; then
    echo -e "\n${GREEN}Node lokal Anda sinkron dengan RPC jarak jauh.${NC}"
else
    echo -e "\n${RED}Node lokal Anda tidak sinkron. Lokal: $local_block | Jarak Jauh: $remote_block.${NC}"
fi

# Selesai
echo -e "\n${GREEN}=== Instalasi, Setup, dan Verifikasi Selesai! ===${NC}"
echo -e "\n👉 ${BOLD}[Join Airdrop Node](https://t.me/airdrop_node)👈${NC}"
