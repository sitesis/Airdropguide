#!/bin/bash

# Kode warna ANSI
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
UNDERLINE_YELLOW='\033[1;4;33m'
NC='\033[0m' # Tanpa Warna

# Fungsi untuk menampilkan logo
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
               Bergabunglah dengan Airdrop Node Sekarang!${GREEN}
        ──────────────────────────────────────
        🚀 Grup Telegram: ${UNDERLINE_YELLOW}https://t.me/airdrop_node${NC}
        ──────────────────────────────────────"
}

# Mengaktifkan penanganan kesalahan
set -e

# Fungsi untuk menginstal Docker jika belum ada
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker tidak ditemukan. Menginstal Docker..."
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker telah diinstal dan berjalan."
    else
        echo "Docker sudah terinstal."
    fi
}

# Fungsi untuk menginstal Docker Compose jika belum ada
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose tidak ditemukan. Menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose telah diinstal."
    else
        echo "Docker Compose sudah terinstal."
    fi
}

# Fungsi untuk menginstal node dan menghasilkan docker-compose.yml
install_node() {
    echo "Untuk melanjutkan, silakan daftar menggunakan tautan berikut:"
    echo -e "${YELLOW}https://app.getgrass.io/register/?referralCode=2G4AzIQX87ObykI${NC}"
    read -p "Apakah Anda sudah menyelesaikan pendaftaran? (y/n): " registered

    if [[ ! "$registered" =~ ^[yY]$ ]]; then
        echo "Silakan selesaikan pendaftaran dan gunakan kode referal airdropnode untuk melanjutkan."
        return
    fi

    # Minta direktori untuk menyimpan docker-compose.yml
    read -p "Masukkan direktori untuk menyimpan docker-compose.yml (default: $HOME/grass_data): " save_directory
    save_directory=${save_directory:-$HOME/grass_data} # Gunakan default jika kosong

    # Buat direktori jika belum ada
    mkdir -p "$save_directory"

    # Minta kredensial pengguna
    read -p "Masukkan email Anda: " USER_EMAIL
    read -sp "Masukkan kata sandi Anda: " USER_PASSWORD
    echo

    # Inisialisasi array untuk WebSocket proxies
    WEBSOCKET_PROXIES=()

    # Minta URL proxy WebSocket pertama
    while true; do
        read -p "Masukkan URL Proxy WebSocket (kosongkan jika tidak diperlukan): " WEBSOCKET_PROXY
        if [[ -n "$WEBSOCKET_PROXY" ]]; then
            WEBSOCKET_PROXIES+=("$WEBSOCKET_PROXY")
        fi
        
        read -p "Apakah Anda ingin menambahkan proxy lain? (y/n): " add_more
        if [[ ! "$add_more" =~ ^[yY]$ ]]; then
            break
        fi
    done

    # Buat file docker-compose.yml dengan kredensial pengguna dan proxy WebSocket opsional
    cat <<EOF > "$save_directory/docker-compose.yml"
version: "3.9"
services:
  grass-node:
    container_name: grass-node
    hostname: my_device
    image: airdropnode/grass-node
    environment:
      USER_EMAIL: ${USER_EMAIL}
      USER_PASSWORD: ${USER_PASSWORD}
EOF

    # Tambahkan proxy WebSocket ke docker-compose.yml jika ada
    for proxy in "${WEBSOCKET_PROXIES[@]}"; do
        echo "      WEBSOCKET_PROXY: ${proxy}" >> "$save_directory/docker-compose.yml"
    done

    cat <<EOF >> "$save_directory/docker-compose.yml"
    ports:
      - "5900:5900"
      - "6080:6080"
    volumes:
      - ./grass_data:/app/data
EOF

    # Jalankan Docker Compose untuk memulai kontainer
    (cd "$save_directory" && docker-compose up -d)

    echo "Node telah berhasil diinstal. Periksa log untuk memastikan otentikasi."
}

# Fungsi untuk melihat log
view_logs() {
    echo "Melihat log untuk kontainer grass-node..."
    docker logs grass-node
    echo
}

# Fungsi untuk menampilkan detail akun
display_account() {
    echo "Detail akun saat ini:"
    echo "Email: ${USER_EMAIL:-Belum Diatur}"
    echo "Kata Sandi: ${USER_PASSWORD:-Belum Diatur}"
    echo "Proxy WebSocket: ${WEBSOCKET_PROXIES[*]:-Tidak Ada}"
}

# Menu utama
show_menu() {
    clear
    display_logo  # Panggil fungsi untuk menampilkan logo
    echo "Silakan pilih opsi:"
    echo "1.  Instal Node"
    echo "2.  Lihat Log"
    echo "3.  Lihat Detail Akun"
    echo "0.  Keluar"
    echo -n "Masukkan pilihan Anda [0-3]: "
    read -r choice
}

# Loop utama
while true; do
    install_docker
    install_docker_compose
    show_menu
    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) display_account ;;
        0) echo "Keluar..."; exit 0 ;;
        *) echo "Input tidak valid. Silakan coba lagi."; read -p "Tekan Enter untuk melanjutkan..." ;;
    esac
done
