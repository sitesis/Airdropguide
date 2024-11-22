#!/bin/bash

# Skrip Instalasi Verifier Node dengan Screen di Direktori Root /glacier

# Warna untuk output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Nama binary dan file konfigurasi
BINARY_NAME="verifier_linux_amd64"
CONFIG_FILE="config.yaml"
BINARY_URL="https://github.com/Glacier-Labs/node-bootstrap/releases/download/v0.0.1-beta/$BINARY_NAME"
INSTALL_DIR="/glacier"  # Direktori root /glacier

# Periksa apakah pengguna adalah root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Skrip ini harus dijalankan sebagai root!${NC}"
   exit 1
fi

# Langkah 1: Pastikan direktori instalasi ada
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${GREEN}Membuat direktori instalasi: $INSTALL_DIR${NC}"
    mkdir -p "$INSTALL_DIR"
fi

# Langkah 2: Pindah ke direktori instalasi
cd "$INSTALL_DIR" || exit

# Langkah 3: Instal screen jika belum ada
echo -e "${GREEN}Memastikan screen sudah terinstal...${NC}"
if ! command -v screen &> /dev/null; then
    echo -e "${GREEN}Menginstal screen...${NC}"
    sudo apt-get update && sudo apt-get install -y screen
else
    echo -e "${GREEN}Screen sudah terinstal.${NC}"
fi

# Langkah 4: Unduh binary
echo -e "${GREEN}Mengunduh binary dari GitHub...${NC}"
wget -q --show-progress "$BINARY_URL" -O "$BINARY_NAME"
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Gagal mengunduh binary!${NC}"
    exit 1
fi

# Langkah 5: Beri izin eksekusi
chmod +x "$BINARY_NAME"

# Langkah 6: Buat file konfigurasi
echo -e "${GREEN}Membuat file konfigurasi...${NC}"
read -p "Masukkan PrivateKey Anda: " PRIVATE_KEY

cat <<EOF > "$CONFIG_FILE"
Http:
  Listen: "127.0.0.1:10801"
Network: "testnet"
RemoteBootstrap: "https://glacier-labs.github.io/node-bootstrap/"
Keystore:
  PrivateKey: "$PRIVATE_KEY"
TEE:
  IpfsURL: "https://greenfield.onebitdev.com/ipfs/"
EOF

# Langkah 7: Periksa struktur direktori
if [[ -f "$BINARY_NAME" && -f "$CONFIG_FILE" ]]; then
    echo -e "${GREEN}Struktur file sudah benar di direktori $INSTALL_DIR:${NC}"
    echo -e "${GREEN}."
    echo -e "├── ${CONFIG_FILE}"
    echo -e "└── ${BINARY_NAME}${NC}"
else
    echo -e "${RED}File binary atau konfigurasi tidak ditemukan!${NC}"
    exit 1
fi

# Langkah 8: Jalankan node dalam screen
echo -e "${GREEN}Menjalankan node dalam screen session...${NC}"
screen -dmS glacier-node ./"$BINARY_NAME"

echo -e "${GREEN}Node sedang berjalan di dalam screen session bernama 'glacier-node'.${NC}"
echo -e "${GREEN}Gunakan perintah berikut untuk melihat log:${NC}"
echo -e "${GREEN}screen -r glacier-node${NC}"
