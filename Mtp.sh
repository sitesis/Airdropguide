#!/bin/bash

# Kode warna
RED="\033[1;31m"
LIGHT_GREEN="\033[1;92m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
RESET="\033[0m"

# Fungsi untuk mengecek apakah perintah terakhir berhasil
check_command_success() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌  Terjadi kesalahan. Periksa pesan di atas untuk detailnya.${RESET}\n"
        exit 1
    fi
}

# Menampilkan logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
echo -e "\n${BLUE}💡  Selamat datang di proses instalasi Multiple Node!${RESET}\n"
sleep 3

# Memeriksa apakah Docker sudah terpasang
echo -e "${CYAN}🔍  Memeriksa instalasi Docker...${RESET}"
if command -v docker &> /dev/null; then
    echo -e "${LIGHT_GREEN}✅  Docker sudah terinstal. Melewati langkah instalasi Docker.${RESET}\n"
else
    echo -e "${BLUE}📦  Docker tidak ditemukan. Memulai instalasi Docker...${RESET}\n"

    # Memperbarui sistem
    echo -e "${BLUE}🔄  Memperbarui daftar paket...${RESET}"
    sudo apt-get update -y && sudo apt-get upgrade -y
    check_command_success

    # Menginstal dependensi
    echo -e "${CYAN}📂  Menginstal dependensi Docker...${RESET}"
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    check_command_success

    # Menambahkan GPG key Docker
    echo -e "${CYAN}🔑  Menambahkan GPG key Docker...${RESET}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    check_command_success

    # Menambahkan repository Docker
    echo -e "${CYAN}📂  Menambahkan repository resmi Docker...${RESET}"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    check_command_success

    # Menginstal Docker
    echo -e "${CYAN}🐳  Menginstal Docker...${RESET}"
    sudo apt-get update -y && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    check_command_success

    # Menambahkan pengguna ke grup Docker
    echo -e "${CYAN}👤  Menambahkan pengguna ke grup Docker...${RESET}"
    sudo usermod -aG docker $USER
    check_command_success
    echo -e "${YELLOW}⚠️  Silakan logout dan login kembali agar perubahan grup Docker diterapkan.${RESET}\n"
fi

# Memeriksa arsitektur sistem
ARCHITECTURE=$(uname -m)
if [[ "$ARCHITECTURE" == "x86_64" ]]; then
    DOWNLOAD_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
    echo -e "${CYAN}🔄  Arsitektur terdeteksi: x86_64. Mengunduh file untuk X64...${RESET}\n"
elif [[ "$ARCHITECTURE" == "aarch64" ]]; then
    DOWNLOAD_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
    echo -e "${CYAN}🔄  Arsitektur terdeteksi: ARM64. Mengunduh file untuk ARM64...${RESET}\n"
else
    echo -e "${RED}❌  Arsitektur tidak dikenali. Proses dihentikan.${RESET}\n"
    exit 1
fi

# Mengunduh dan mengekstrak file
WORK_DIR="$HOME/multipleforlinux"
echo -e "${BLUE}📥  Mengunduh file Multiple CLI...${RESET}"
wget -q -O multipleforlinux.tar $DOWNLOAD_URL
check_command_success

echo -e "${BLUE}📂  Mengekstrak file...${RESET}"
tar -xvf multipleforlinux.tar -C $HOME
check_command_success

# Masuk ke direktori kerja
cd $WORK_DIR || { echo -e "${RED}❌  Gagal masuk ke direktori ${WORK_DIR}.${RESET}\n"; exit 1; }

# Memberikan izin eksekusi
echo -e "${CYAN}🔧  Memberikan izin eksekusi untuk file...${RESET}"
chmod +x ./multiple-cli ./multiple-node
check_command_success

# Menjalankan Multiple Node
echo -e "${CYAN}🚀  Menjalankan Multiple Node...${RESET}"
nohup ./multiple-node > $WORK_DIR/output.log 2>&1 &
check_command_success
echo -e "${LIGHT_GREEN}✅  Multiple Node berhasil dijalankan!${RESET}\n"

# Meminta input pengguna
echo -e "${CYAN}🔐  Masukkan detail akun Anda:${RESET}"
read -p "Masukkan Identifier: " USER_IDENTIFIER
read -s -p "Masukkan PIN Code: " USER_PIN
echo

# Validasi input
if [[ -z "$USER_IDENTIFIER" || -z "$USER_PIN" ]]; then
    echo -e "${RED}❌  Identifier dan PIN tidak boleh kosong.${RESET}\n"
    exit 1
fi

# Menjalankan Multiple CLI untuk bind akun
echo -e "${BLUE}🔗  Mengikat akun dengan Multiple CLI...${RESET}"
./multiple-cli bind \
    --bandwidth-download 100 \
    --identifier "$USER_IDENTIFIER" \
    --pin "$USER_PIN" \
    --storage 200 \
    --bandwidth-upload 100
check_command_success
echo -e "${LIGHT_GREEN}✅  Akun berhasil diikat!${RESET}\n"

# Informasi selesai
echo -e "${YELLOW}📋  Log node dapat diperiksa dengan perintah:${RESET} ${WHITE}tail -f $WORK_DIR/output.log${RESET}"
echo -e "${CYAN}📢  Bergabung dengan channel Airdrop Node untuk update:${RESET} ${WHITE}https://t.me/airdrop_node${RESET}"
echo -e "\n${LIGHT_GREEN}🎉  Instalasi selesai! Selamat menggunakan Multiple Node!${RESET}\n"
