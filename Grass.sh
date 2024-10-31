#!/bin/bash

# ANSI escape codes for colors
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
UNDERLINE_YELLOW='\033[1;4;33m'
NC='\033[0m' # No Color

# Function to display logo
display_logo() {
    echo -e "${YELLOW}
           _         _                   _   _           _      
     /\   (_)       | |                 | \ | |         | |     
    /  \   _ _ __ __| |_ __ ___  _ __   |  \| | ___   __| | ___ 
   / /\ \ | | '__/ _\` | '__/ _ \| '_ \  | . \` |/ _ \ / _\` |/ _ \\
  / ____ \| | | | (_| | | | (_) | |_) | | |\  | (_) | (_| |  __/
 /_/    \_\_|_|  \__,_|_|  \___/| .__/  |_| \_|\___/ \__,_|\___|
                                | |                             
                                |_|                             
${BLUE}
               Join the Airdrop Node Now!${GREEN}
        ──────────────────────────────────────
        🚀 Telegram Group: ${UNDERLINE_YELLOW}https://t.me/airdrop_node${NC}
        ──────────────────────────────────────"
}

# Enable error handling
set -e

# Function to install Docker if not present
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker tidak ditemukan. Menginstal Docker..."
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker sudah diinstal dan dijalankan."
    else
        echo "Docker sudah terinstal."
    fi
}

# Function to install Docker Compose if not present
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose tidak ditemukan. Menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose sudah diinstal."
    else
        echo "Docker Compose sudah terinstal."
    fi
}

# Function to read proxy settings from the proxy.txt file
read_proxy() {
    if [[ -f "proxy.txt" ]]; then
        PROXY_URL=$(cat proxy.txt)
        echo "Menggunakan proxy: $PROXY_URL"
    else
        PROXY_URL=""
        echo "Tidak ada proxy yang ditentukan."
    fi
}

# Function to install the node
install_node() {
    echo "Untuk melanjutkan, silakan daftarkan diri di tautan berikut:"
    echo -e "${YELLOW}https://app.getgrass.io/register/?referralCode=2G4AzIQX87ObykI${NC}"
    echo -n "Apakah Anda sudah menyelesaikan pendaftaran? (y/n): "
    read -r registered

    if [[ "$registered" != "y" && "$registered" != "Y" ]]; then
        echo "Silakan selesaikan pendaftaran dan gunakan kode rujukan airdropnode untuk melanjutkan."
        read -p "Tekan Enter untuk kembali ke menu..."
        return
    fi

    # Prompt for user credentials
    read -p "Masukkan email Anda: " USER_EMAIL
    read -sp "Masukkan kata sandi Anda: " USER_PASSWORD
    echo

    # Read proxy settings
    read_proxy

    # Build the Docker run command with proxy if provided
    PROXY_SETTINGS=""
    if [[ -n "$PROXY_URL" ]]; then
        PROXY_SETTINGS="-e HTTP_PROXY=$PROXY_URL -e HTTPS_PROXY=$PROXY_URL"
    fi

    # Run the Docker container with user credentials and proxy settings
    docker run -d --name grass -h my_device -e GRASS_USER="$USER_EMAIL" -e GRASS_PASS="$USER_PASSWORD" $PROXY_SETTINGS airdropnode/grass:latest

    echo "Node berhasil diinstal. Periksa log untuk mengonfirmasi autentikasi."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to view logs
view_logs() {
    echo "Melihat log..."
    docker logs grass
    echo
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to restart node
restart_node() {
    echo "Memulai ulang node..."
    docker restart grass
    echo "Node telah dimulai ulang."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to stop node
stop_node() {
    echo "Menghentikan node..."
    docker stop grass
    echo "Node telah dihentikan."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to start node
start_node() {
    echo "Memulai node..."
    docker start grass
    echo "Node telah dimulai."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to change account details
change_account() {
    echo "Mengubah detail akun..."
    read -p "Masukkan email baru: " USER_EMAIL
    read -sp "Masukkan kata sandi baru: " USER_PASSWORD
    echo

    # Update the Docker container with new user credentials
    docker stop grass
    docker rm grass

    # Read proxy settings
    read_proxy
    PROXY_SETTINGS=""
    if [[ -n "$PROXY_URL" ]]; then
        PROXY_SETTINGS="-e HTTP_PROXY=$PROXY_URL -e HTTPS_PROXY=$PROXY_URL"
    fi

    # Run the Docker container with new user credentials and proxy settings
    docker run -d --name grass -h my_device -e GRASS_USER="$USER_EMAIL" -e GRASS_PASS="$USER_PASSWORD" $PROXY_SETTINGS airdropnode/grass:latest

    echo "Detail akun berhasil diperbarui."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to display account details
cat_account() {
    echo "Detail akun saat ini:"
    echo "Email: $USER_EMAIL"
    echo "Password: $USER_PASSWORD"
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Main menu
show_menu() {
    clear
    display_logo  # Call the function to display the logo
    echo "Silakan pilih opsi:"
    echo "1.  Instal Node"
    echo "2.  Lihat Log"
    echo "3.  Restart Node"
    echo "4.  Hentikan Node"
    echo "5.  Mulai Node"
    echo "6.  Lihat Akun"
    echo "7.  Ganti Akun"
    echo "0.  Keluar"
    echo -n "Masukkan nomor perintah [0-7]: "
    read -r choice
}

# Main loop
while true; do
    cd ~/grass  # Navigate to the grass directory
    install_docker
    install_docker_compose
    show_menu
    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) restart_node ;;
        4) stop_node ;;
        5) start_node ;;
        6) cat_account ;;
        7) change_account ;;
        0) echo "Keluar..."; exit 0 ;;
        *) echo "Input tidak valid. Silakan coba lagi."; read -p "Tekan Enter untuk melanjutkan..." ;;
    esac
done
