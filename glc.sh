#!/bin/bash

# Skrip Instalasi Verifier Node dengan Screen di Direktori Root /glacier

# Warna untuk output
LIGHT_GREEN='\033[1;92m'
RED='\033[1;31m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Ikon untuk indikator langkah
CHECK_MARK="${LIGHT_GREEN}✔${NC}"
CROSS_MARK="${RED}✖${NC}"
ARROW="${CYAN}➜${NC}"
BULLET="${MAGENTA}•${NC}"

# Nama binary dan file konfigurasi
BINARY_NAME="verifier_linux_amd64"
CONFIG_FILE="config.yaml"
BINARY_URL="https://github.com/Glacier-Labs/node-bootstrap/releases/download/v0.0.2-beta/verifier_linux_amd64"  # URL baru
INSTALL_DIR="/glacier"

# Gas Price otomatis
GAS_PRICE=5
GAS_PRICE_WEI=$((GAS_PRICE * 1000000000))  # Konversi Gwei ke Wei

# Periksa apakah pengguna adalah root
if [[ $EUID -ne 0 ]]; then
   echo -e "${CROSS_MARK} ${RED}Skrip ini harus dijalankan sebagai root!${NC}"
   exit 1
fi

echo -e "${ARROW} ${CYAN}Memulai instalasi Verifier Node...${NC}"

# Langkah 1: Pastikan direktori instalasi ada
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${CHECK_MARK} ${YELLOW}Membuat direktori instalasi: $INSTALL_DIR${NC}"
    mkdir -p "$INSTALL_DIR"
else
    echo -e "${CHECK_MARK} ${YELLOW}Direktori instalasi sudah ada: $INSTALL_DIR${NC}"
fi

# Langkah 2: Pindah ke direktori instalasi
cd "$INSTALL_DIR" || exit

# Langkah 3: Instal screen jika belum ada
echo -e "${ARROW} ${BLUE}Memastikan screen sudah terinstal...${NC}"
if ! command -v screen &> /dev/null; then
    echo -e "${BULLET} ${MAGENTA}Menginstal screen...${NC}"
    sudo apt-get update -q && sudo apt-get install -y screen
    echo -e "${CHECK_MARK} ${LIGHT_GREEN}Screen berhasil diinstal.${NC}"
else
    echo -e "${CHECK_MARK} ${LIGHT_GREEN}Screen sudah terinstal.${NC}"
fi

# Langkah 4: Unduh binary
echo -e "${ARROW} ${BLUE}Mengunduh binary dari URL baru...${NC}"
wget -q --show-progress "$BINARY_URL" -O "$BINARY_NAME"
if [[ $? -ne 0 ]]; then
    echo -e "${CROSS_MARK} ${RED}Gagal mengunduh binary!${NC}"
    exit 1
fi
echo -e "${CHECK_MARK} ${LIGHT_GREEN}Binary berhasil diunduh.${NC}"

# Langkah 5: Beri izin eksekusi
chmod +x "$BINARY_NAME"
echo -e "${CHECK_MARK} ${LIGHT_GREEN}Izin eksekusi diberikan pada binary.${NC}"

# Langkah 6: Buat file konfigurasi
echo -e "${ARROW} ${BLUE}Membuat file konfigurasi...${NC}"
read -p "$(echo -e ${YELLOW}Masukkan PrivateKey Anda:${NC} )" PRIVATE_KEY

cat <<EOF > "$CONFIG_FILE"
Http:
  Listen: "127.0.0.1:10801"
Network: "testnet"
RemoteBootstrap: "https://glacier-labs.github.io/node-bootstrap/"
Keystore:
  PrivateKey: "$PRIVATE_KEY"
TEE:
  IpfsURL: "https://greenfield.onebitdev.com/ipfs/"
GasPrice:
  Gwei: "$GAS_PRICE"
  Wei: "$GAS_PRICE_WEI"
EOF
echo -e "${CHECK_MARK} ${LIGHT_GREEN}File konfigurasi berhasil dibuat.${NC}"

# Langkah 7: Periksa struktur direktori
if [[ -f "$BINARY_NAME" && -f "$CONFIG_FILE" ]]; then
    echo -e "${CHECK_MARK} ${LIGHT_GREEN}Struktur file sudah benar di direktori $INSTALL_DIR:${NC}"
    echo -e "${WHITE}."
    echo -e "├── ${MAGENTA}${CONFIG_FILE}${NC}"
    echo -e "└── ${CYAN}${BINARY_NAME}${NC}"
else
    echo -e "${CROSS_MARK} ${RED}File binary atau konfigurasi tidak ditemukan!${NC}"
    exit 1
fi

# Langkah 8: Jalankan node dalam screen
echo -e "${ARROW} ${BLUE}Menjalankan node dalam screen session...${NC}"
screen -dmS glacier-node ./"$BINARY_NAME"
echo -e "${CHECK_MARK} ${LIGHT_GREEN}Node sedang berjalan di dalam screen session bernama 'glacier-node'.${NC}"

# Petunjuk tambahan
echo -e "${ARROW} ${YELLOW}Gunakan perintah berikut untuk melihat log:${NC}"
echo -e "${BULLET} ${CYAN}screen -r glacier-node${NC}"

# Tambahkan ajakan bergabung ke Telegram
echo -e "\n${ARROW} ${BLUE}Bergabunglah dengan channel Telegram untuk informasi lebih lanjut:${NC}"
echo -e "${BULLET} ${LIGHT_GREEN}https://t.me/airdrop_node${NC}"
