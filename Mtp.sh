#!/bin/bash
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5
# Define custom light colors
BLUE='\033[1;34m'    
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'         

# Check Linux architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
elif [[ "$ARCH" == "aarch64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
else
    echo -e "${RED}Arsitektur tidak didukung: $ARCH${NC}"
    exit 1
fi

# Add space and color for visual impact
echo -e "${BLUE}🚀 Mengunduh klien dari $CLIENT_URL...${NC}"
if ! wget $CLIENT_URL -O multipleforlinux.tar; then
    echo -e "${RED}Gagal mengunduh paket klien.${NC}"
    exit 1
fi

echo -e "${BLUE}🔧 Mengekstrak paket instalasi...${NC}"
if ! tar -xvf multipleforlinux.tar; then
    echo -e "${RED}Gagal mengekstrak paket klien.${NC}"
    exit 1
fi

# Navigate into the extracted directory
cd multipleforlinux

echo -e "${BLUE}🔒 Menetapkan izin yang diperlukan...${NC}"
if ! chmod +x multiple-cli multiple-node; then
    echo -e "${RED}Gagal menetapkan izin pada binari klien.${NC}"
    exit 1
fi

# Configure required parameters
echo -e "${BLUE}⚙️ Mengonfigurasi PATH...${NC}"
if ! echo "PATH=\$PATH:$(pwd)" >> ~/.bashrc; then
    echo -e "${RED}Gagal memperbarui PATH di ~/.bashrc.${NC}"
    exit 1
fi
if ! source ~/.bashrc; then
    echo -e "${RED}Gagal mengeksekusi source ~/.bashrc.${NC}"
    exit 1
fi

# Set permissions for the directory
echo -e "${BLUE}🔐 Menetapkan izin untuk direktori...${NC}"
if ! chmod -R 777 .; then
    echo -e "${RED}Gagal menetapkan izin direktori.${NC}"
    exit 1
fi

# Prompt for IDENTIFIER and PIN
read -p "Masukkan IDENTIFIER Anda: " IDENTIFIER
read -p "Masukkan PIN Anda: " PIN

# Run the program
echo -e "${BLUE}🚀 Menjalankan program...${NC}"
if ! nohup ./multiple-node > output.log 2>&1 & then
    echo -e "${RED}Gagal menjalankan program.${NC}"
    exit 1
fi

# Bind unique account identifier
echo -e "${BLUE}🔗 Mengikat akun dengan identifier dan PIN...${NC}"
if ! ./multiple-cli bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100; then
    echo -e "${RED}Gagal mengikat akun dengan kredensial yang diberikan.${NC}"
    exit 1
fi

echo -e "${BLUE}✅ Proses selesai.${NC}"
