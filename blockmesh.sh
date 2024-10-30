#!/bin/bash

# Set directory name
DIRECTORY="blockmesh_directory"

# Enable error handling
set -e

# Check and install Docker if not present
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

# Check and install Docker Compose if not present
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

# Function to install the node
install_node() {
    echo "Untuk melanjutkan, silakan daftarkan diri di tautan berikut:"
    echo "https://app.blockmesh.xyz/register?invite_code=airdropnode"
    echo -n "Apakah Anda sudah menyelesaikan pendaftaran? (y/n): "
    read registered

    if [[ "$registered" != "y" && "$registered" != "Y" ]]; then
        echo "Silakan selesaikan pendaftaran dan gunakan kode rujukan airdropnode untuk melanjutkan."
        read -p "Tekan Enter untuk kembali ke menu..."
        return
    fi

    # Create directory if it does not exist
    mkdir -p "$DIRECTORY"
    cd "$DIRECTORY" || exit

    # Create docker-compose.yml
    cat <<EOL > docker-compose.yml
version: '3.8'

services:
  blockmesh-cli:
    image: airdropnode/blockmesh-cli:v0.0.316
    container_name: blockmesh-cli
    environment:
      - USER_EMAIL=\${USER_EMAIL}
      - USER_PASSWORD=\${USER_PASSWORD}
    restart: unless-stopped
EOL

    # Prompt for user credentials
    read -p "Masukkan email Anda: " USER_EMAIL
    read -sp "Masukkan kata sandi Anda: " USER_PASSWORD
    echo

    # Create .env file with user credentials
    cat <<EOL > .env
USER_EMAIL=$USER_EMAIL
USER_PASSWORD=$USER_PASSWORD
EOL

    docker-compose up -d
    echo "Node berhasil diinstal. Periksa log untuk mengonfirmasi autentikasi."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to view logs
view_logs() {
    echo "Melihat log..."
    docker-compose logs
    echo
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to restart node
restart_node() {
    echo "Memulai ulang node..."
    docker-compose down
    docker-compose up -d
    echo "Node telah dimulai ulang."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to stop node
stop_node() {
    echo "Menghentikan node..."
    docker-compose down
    echo "Node telah dihentikan."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to start node
start_node() {
    echo "Memulai node..."
    docker-compose up -d
    echo "Node telah dimulai."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to change account
change_account() {
    echo "Mengubah detail akun..."
    read -p "Masukkan email baru: " USER_EMAIL
    read -sp "Masukkan kata sandi baru: " USER_PASSWORD
    echo
    echo "USER_EMAIL=${USER_EMAIL}" > .env
    echo "USER_PASSWORD=${USER_PASSWORD}" >> .env
    echo "Detail akun berhasil diperbarui."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Function to display account
cat_account() {
    cat .env
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Main menu
show_menu() {
    clear
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
    read choice
}

# Main loop
while true; do
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
