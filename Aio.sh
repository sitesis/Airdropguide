#!/bin/bash

# Warna
merah='\033[1;31m'
hijau='\033[1;32m'
biru='\033[1;34m'
normal='\033[0m'

# Cek Docker
if ! command -v docker &> /dev/null; then
  echo -e "${merah} Docker belum terinstal. Menginstal... ${normal}"
  
  # Instalasi Docker
  sudo apt update -y
  sudo apt install docker.io -y
  sudo systemctl start docker
  sudo systemctl enable docker
  sudo usermod -aG docker $USER
  
  echo -e "${hijau} Docker berhasil diinstal! ${normal}"
else
  echo -e "${hijau} Docker sudah terinstal. Melanjutkan... ${normal}"
fi

# Unduh Gambar Docker
echo -e "${biru}==============================================${normal}"
echo -e "${hijau} Mengunduh Gambar Docker Sophon Testnet ${normal}"
echo -e "${biru}==============================================${normal}"
docker pull sophonhub/sophon-light-node:latest-stg

# Konfigurasi
echo -e "${biru}==============================================${normal}"
echo -e "${hijau} Masukkan Nilai Konfigurasi ${normal}"
echo -e "${biru}==============================================${normal}"

DEFAULT_IP=$(hostname -I | awk '{print $1}')  # Ambil IP pertama dari hostname -I

read -p "Masukkan Alamat Dompet Operator: " OPERATOR_ADDRESS
read -p "Masukkan Alamat Tujuan Hadiah: " DESTINATION_ADDRESS
read -p "Masukkan Persentase Biaya Hadiah (0-100): " PERCENTAGE
read -p "Masukkan Alamat IP VPS [default: $DEFAULT_IP]: " PUBLIC_DOMAIN
PUBLIC_DOMAIN=${PUBLIC_DOMAIN:-$DEFAULT_IP}  # Gunakan nilai default jika kosong
read -p "Masukkan Port (default: 7007): " PORT
PORT=${PORT:-7007}  # Gunakan 7007 jika kosong

# Jalankan Node
echo -e "${biru}==============================================${normal}"
echo -e "${hijau} Jalankan Node Sophon Testnet ${normal}"
echo -e "${biru}==============================================${normal}"
docker run -d --name sophon-light-node \
  --restart on-failure:5 \
  -e OPERATOR_ADDRESS=$OPERATOR_ADDRESS \
  -e DESTINATION_ADDRESS=$DESTINATION_ADDRESS \
  -e PERCENTAGE=$PERCENTAGE \
  -e PUBLIC_DOMAIN=$PUBLIC_DOMAIN:$PORT \
  -e PORT=$PORT \
  -p $PORT:$PORT \
  sophonhub/sophon-light-node:latest-stg

# Selesai
echo -e "${hijau} Node Sophon Testnet berhasil dijalankan! ${normal}"
echo -e "${biru}==============================================${normal}"
echo -e "Cek status node: docker ps -a"
echo -e "Log node: docker logs -f sophon-light-node"
echo -e "Berhenti node: docker stop sophon-light-node"
echo -e "Hapus node: docker rm sophon-light-node"
echo -e "${biru}==============================================${normal}"

# Bergabung ke Channel Telegram
echo -e "${biru}==============================================${normal}"
echo -e "${hijau} Jangan lupa bergabung ke channel Telegram kami untuk informasi lebih lanjut! ${normal}"
echo -e "${biru}==============================================${normal}"
echo -e "Link channel Telegram: https://t.me/airdrop_node"
