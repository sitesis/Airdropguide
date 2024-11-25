#!/bin/bash

# Tampilkan logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Warna
RED='\033[0;31m'
LIGHT_GREEN='\033[1;32m'
YELLOW='\033[0;33m'
LIGHT_BLUE='\033[1;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

# 🖥️ Periksa arsitektur Linux
ARCH=$(uname -m)

if [[ "$ARCH" == "x86_64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
elif [[ "$ARCH" == "aarch64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
else
    echo -e "${RED}❌ Arsitektur tidak didukung: $ARCH${NC}"
    exit 1
fi

# Unduh file
echo -e "${CYAN}🔽 Mengunduh klien dari $CLIENT_URL...${NC}"
wget $CLIENT_URL -O multipleforlinux.tar || { 
    echo -e "${RED}❌ Gagal mengunduh file dari $CLIENT_URL.${NC}"; exit 1; 
}
echo ""

# Ekstraksi file
echo -e "${MAGENTA}📦 Mengekstrak paket instalasi...${NC}"
tar -xvf multipleforlinux.tar || { 
    echo -e "${RED}❌ Ekstraksi file gagal.${NC}"; exit 1; 
}
echo ""

# Masuk ke direktori
cd multipleforlinux || { 
    echo -e "${RED}❌ Direktori tidak ditemukan.${NC}"; exit 1; 
}
echo ""

# Berikan izin eksekusi
echo -e "${YELLOW}🔧 Mengatur izin yang diperlukan...${NC}"
chmod +x multiple-cli multiple-node
echo ""

# Konfigurasi PATH
echo -e "${LIGHT_BLUE}⚙️ Menambahkan PATH ke environment...${NC}"
echo "PATH=\$PATH:$(pwd)" >> ~/.bashrc
source ~/.bashrc
if ! echo $PATH | grep -q "$(pwd)"; then
    echo -e "${RED}❌ Gagal memperbarui PATH.${NC}"
    exit 1
fi
echo ""

# Set izin untuk direktori
echo -e "${LIGHT_GREEN}🔑 Memberikan izin direktori...${NC}"
chmod -R 777 .
echo ""

# Masukkan IDENTIFIER dan PIN
echo -e "${CYAN}📝 Masukkan informasi yang diperlukan:${NC}"
read -p "Masukkan IDENTIFIER Anda: " IDENTIFIER
read -s -p "Masukkan PIN Anda: " PIN
echo ""

# Validasi input
if [ -z "$IDENTIFIER" ] || [ -z "$PIN" ]; then
    echo -e "${RED}❌ ERROR: IDENTIFIER dan PIN tidak boleh kosong.${NC}"
    exit 1
fi

# Konfigurasi dinamis
read -p "Masukkan kapasitas storage (dalam GB, misalnya 200): " STORAGE
read -p "Masukkan bandwidth upload (dalam Mbps, misalnya 100): " UPLOAD
read -p "Masukkan bandwidth download (dalam Mbps, misalnya 100): " DOWNLOAD

# Jalankan program
echo -e "${LIGHT_GREEN}🚀 Menjalankan program...${NC}"
mkdir -p logs
nohup ./multiple-node > logs/output.log 2>&1 &
echo -e "${LIGHT_GREEN}✅ Logs tersedia di folder 'logs'.${NC}"
echo ""

# Bind akun
echo -e "${YELLOW}🔗 Menghubungkan akun dengan IDENTIFIER dan PIN...${NC}"
./multiple-cli bind --bandwidth-download "$DOWNLOAD" --identifier "$IDENTIFIER" --pin "$PIN" --storage "$STORAGE" --bandwidth-upload "$UPLOAD"
echo ""

# Pembersihan file sementara
echo -e "${CYAN}🧹 Membersihkan file sementara...${NC}"
cd ..
rm -rf multipleforlinux.tar
echo -e "${LIGHT_GREEN}✅ File sementara telah dihapus.${NC}"
echo ""

# Join Telegram

echo -e "${LIGHT_GREEN}✅ Proses selesai.${NC}"
echo -e "${CYAN}📱 Gabung ke channel Telegram untuk pembaruan: https://t.me/airdrop_node${NC}"
