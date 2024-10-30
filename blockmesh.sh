#!/bin/bash

# Set nama direktori
DIRECTORY="blockmesh_directory"

# Cek dan instal Docker jika belum ada
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

# Cek dan instal Docker Compose jika belum ada
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

# Fungsi instalasi node
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

    mkdir -p "$DIRECTORY" && cd "$DIRECTORY" || exit

    cat <<EOL > docker-compose.yml
version: '3.8'

services:
  blockmesh-cli:
    image: dknodes/blockmesh-cli_x86_64:v0.0.316
    container_name: blockmesh-cli
    environment:
      - USER_EMAIL=\${USER_EMAIL}
      - USER_PASSWORD=\${USER_PASSWORD}
    restart: unless-stopped
EOL

    read -p "Masukkan email Anda: " USER_EMAIL
    read -sp "Masukkan kata sandi Anda: " USER_PASSWORD
    echo

    cat <<EOL > .env
USER_EMAIL=$USER_EMAIL
USER_PASSWORD=$USER_PASSWORD
EOL

    docker-compose up -d
    echo "Node berhasil diinstal. Periksa log untuk mengonfirmasi autentikasi."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi melihat log
view_logs() {
    echo "Melihat log..."
    docker-compose logs
    echo
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi restart node
restart_node() {
    echo "Memulai ulang node..."
    docker-compose down
    docker-compose up -d
    echo "Node telah dimulai ulang."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi menghentikan node
stop_node() {
    echo "Menghentikan node..."
    docker-compose down
    echo "Node telah dihentikan."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi memulai node
start_node() {
    echo "Memulai node..."
    docker-compose up -d
    echo "Node telah dimulai."
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Fungsi mengganti akun
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

# Fungsi menampilkan akun
cat_account() {
    cat .env
    read -p "Tekan Enter untuk kembali ke menu..."
}

# Menu utama
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

# Loop utama
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
