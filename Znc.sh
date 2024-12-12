#!/bin/bash

# Meminta nama validator dari pengguna
read -p "Masukkan nama validator: " VALIDATOR_NAME

# Memastikan sistem memiliki dependensi yang dibutuhkan
install_dependencies() {
    echo "Memeriksa dan menginstal dependensi yang diperlukan..."
    sudo apt-get update
    if ! sudo apt-get install -y jq curl git build-essential; then
        echo "Error: Gagal menginstal dependensi."
        exit 1
    fi
}

# Memastikan Docker dan Docker Compose terinstal
check_docker_installation() {
    if ! command -v docker &>/dev/null; then
        echo "Docker tidak ditemukan. Menginstal Docker..."
        if ! sudo apt-get install -y docker.io; then
            echo "Error: Gagal menginstal Docker."
            exit 1
        fi
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo "Docker sudah terinstal."
    fi

    if ! command -v docker-compose &>/dev/null; then
        echo "Docker Compose tidak ditemukan. Menginstal Docker Compose..."
        if ! sudo curl -L "https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
            echo "Error: Gagal mengunduh Docker Compose."
            exit 1
        fi
        if ! sudo chmod +x /usr/local/bin/docker-compose; then
            echo "Error: Gagal memberikan izin eksekusi untuk Docker Compose."
            exit 1
        fi
    else
        echo "Docker Compose sudah terinstal."
    fi
}

# Memastikan direktori chain-data ada dan memiliki izin yang benar
ensure_chain_data_directory() {
    echo "Memastikan direktori ./chain-data dan izin yang benar..."
    if ! mkdir -p ./chain-data; then
        echo "Error: Gagal membuat direktori ./chain-data."
        exit 1
    fi

    if ! sudo chown -R $USER:$USER ./chain-data; then
        echo "Error: Gagal mengubah kepemilikan direktori ./chain-data."
        exit 1
    fi

    if ! sudo chmod -R 755 ./chain-data; then
        echo "Error: Gagal memberikan izin yang benar untuk direktori ./chain-data."
        exit 1
    fi
    echo "Direktori ./chain-data dan izin telah disiapkan."
}

# Membuat file docker-compose.yml untuk Production Setup
create_docker_compose_file() {
    echo "Membuat file docker-compose.yml untuk Production Setup..."
    cat <<EOF >./docker-compose.yml
version: '3.8'

# Production Setup
services:
  zenchain-prod:
    image: ghcr.io/zenchain-protocol/zenchain-testnet:latest
    platform: linux/amd64
    container_name: zenchain-prod
    ports:
      - "9944:9944"
    volumes:
      - ./chain-data:/chain-data
    command:
      - "./usr/bin/zenchain-node"
      - "--base-path=/chain-data"
      - "--rpc-cors=all"
      - "--validator"
      - "--name=${VALIDATOR_NAME}"
      - "--bootnodes=/dns4/node-7242611732906999808-0.p2p.onfinality.io/tcp/26266/p2p/12D3KooWLAH3GejHmmchsvJpwDYkvacrBeAQbJrip5oZSymx5yrE"
      - "--chain=zenchain_testnet"
EOF

    echo "File docker-compose.yml untuk Production Setup berhasil dibuat di direktori saat ini."
}

# Memastikan berada di direktori yang benar sebelum menjalankan docker-compose
run_docker_compose() {
    echo "Menjalankan Docker Compose untuk ZenChain Node..."
    CURRENT_DIR=$(pwd)

    if [[ ! -f ./docker-compose.yml ]]; then
        echo "Error: File docker-compose.yml tidak ditemukan di direktori ini!"
        exit 1
    fi

    if ! docker-compose down; then
        echo "Error: Gagal menurunkan Docker Compose."
        exit 1
    fi

    if ! docker-compose up -d; then
        echo "Error: Gagal menjalankan Docker Compose."
        exit 1
    fi
    echo "ZenChain Node berhasil dijalankan."
}

# Menunggu 60 detik untuk memastikan RPC aktif
wait_for_rpc() {
    echo "Menunggu 60 detik untuk memastikan RPC aktif..."
    sleep 60
}

# Mendapatkan session keys
get_session_keys() {
    echo "Mendapatkan Session Keys..."
    SESSION_KEYS=$(curl --max-time 10 --silent --retry 5 --retry-delay 5 --url http://localhost:9944 -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"author_rotateKeys","params":[],"id":1}' | jq -r .result)
    if [[ -z "$SESSION_KEYS" ]]; then
        echo "Error: Gagal mendapatkan Session Keys. Pastikan port 9944 terbuka."
    else
        echo "Session Keys berhasil didapatkan: ${SESSION_KEYS}"
        echo "$SESSION_KEYS" > session_keys.txt
        echo "Session Keys disimpan di file session_keys.txt."
    fi
}

# Melihat logs dari kontainer Docker Zenchain
view_logs() {
    echo "Melihat logs dari Docker container Zenchain..."
    docker logs -f zenchain-prod
}

# Menanyakan apakah ingin melihat logs setelah setup selesai
view_logs_option() {
    echo "Apakah Anda ingin melihat logs dari ZenChain Node? (y/n)"
    read -p "Pilih opsi: " VIEW_LOGS
    if [[ "$VIEW_LOGS" == "y" || "$VIEW_LOGS" == "Y" ]]; then
        view_logs
    else
        echo "Proses selesai. Session Keys telah disimpan di session_keys.txt."
    fi
}

# Menampilkan ajakan bergabung dengan Channel Telegram
join_telegram_channel() {
    echo "Terima kasih telah mengikuti proses ini. Jangan lupa untuk bergabung dengan Channel Telegram AirdropNode untuk update lebih lanjut:"
    echo "👉 https://t.me/airdrop_node"
}

# Menjalankan semua langkah
install_dependencies
check_docker_installation
ensure_chain_data_directory
create_docker_compose_file
run_docker_compose
wait_for_rpc
get_session_keys

# Menampilkan opsi untuk melihat logs
view_logs_option

# Menampilkan ajakan bergabung Channel Telegram
join_telegram_channel
