#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Fungsi untuk menambahkan warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Pastikan script dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Silakan jalankan script ini sebagai root.${NC}\n"
    exit 1
fi

# Fungsi untuk memeriksa dan menginstal Docker
install_docker() {
    echo -e "${YELLOW}Memeriksa instalasi Docker...${NC}"
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker tidak ditemukan.${NC} ${YELLOW}Menginstal Docker...${NC}"
        apt update && apt install -y docker.io
        systemctl start docker
        systemctl enable docker
        echo -e "${GREEN}Docker berhasil diinstal.${NC}\n"
    else
        echo -e "${GREEN}Docker sudah terinstal.${NC}\n"
    fi
}

# Fungsi untuk memeriksa dan menginstal Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}Memeriksa instalasi Docker Compose...${NC}"
    if ! command -v docker-compose &>/dev/null; then
        echo -e "${RED}Docker Compose tidak ditemukan.${NC} ${YELLOW}Menginstal Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K[^"]*')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}Docker Compose berhasil diinstal.${NC}\n"
    else
        echo -e "${GREEN}Docker Compose sudah terinstal.${NC}\n"
    fi
}

# Fungsi untuk meminta nama validator dari pengguna
prompt_validator_name() {
    echo -e "${CYAN}Silakan masukkan nama validator Anda:${NC}"
    read -p "> " VALIDATOR_NAME
    if [[ -z "$VALIDATOR_NAME" ]]; then
        echo -e "${RED}Nama validator tidak boleh kosong. Silakan coba lagi.${NC}\n"
        prompt_validator_name
    else
        echo -e "${GREEN}Nama validator disimpan sebagai:${NC} ${VALIDATOR_NAME}\n"
    fi
}

# Membuat file docker-compose.yml di direktori kerja saat ini
create_docker_compose_file() {
    echo -e "${YELLOW}Membuat file docker-compose.yml...${NC}"
    cat <<EOF >./docker-compose.yml
version: '3.8'
services:
  zenchain:
    image: ghcr.io/zenchain-protocol/zenchain-testnet:latest
    container_name: zenchain
    ports:
      - "9944:9944"
    volumes:
      - ./chain-data:/chain-data
      - ./zenchain-config:/config
    command: >
      ./usr/bin/zenchain-node
      --base-path=/chain-data
      --rpc-cors=all
      --rpc-methods=unsafe
      --unsafe-rpc-external
      --validator
      --name=${VALIDATOR_NAME}
      --bootnodes=/dns4/node-7242611732906999808-0.p2p.onfinality.io/tcp/26266/p2p/12D3KooWLAH3GejHmmchsvJpwDYkvacrBeAQbJrip5oZSymx5yrE
      --chain=zenchain_testnet
EOF
    echo -e "${GREEN}File docker-compose.yml berhasil dibuat di direktori saat ini.${NC}\n"
}

# Menjalankan Docker Compose dari folder yang sesuai
start_docker_compose() {
    echo -e "${YELLOW}Menjalankan ZenChain Node dengan Docker Compose...${NC}"
    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}ZenChain Node berhasil dijalankan.${NC}\n"
    else
        echo -e "${RED}Gagal menjalankan ZenChain Node.${NC}\n"
        restart_docker_compose
    fi
}

# Mengulang perintah docker-compose jika gagal
restart_docker_compose() {
    echo -e "${YELLOW}Gagal menjalankan ZenChain Node. Mencoba untuk memulai ulang container...${NC}"
    docker-compose down
    docker-compose up -d
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}ZenChain Node berhasil dijalankan setelah restart.${NC}\n"
    else
        echo -e "${RED}Gagal menjalankan ZenChain Node setelah restart.${NC}\n"
        exit 1
    fi
}

# Mendapatkan session keys
get_session_keys() {
    echo -e "${YELLOW}Menunggu 60 detik untuk memastikan RPC aktif...${NC}\n"
    sleep 60
    echo -e "${YELLOW}Mendapatkan Session Keys...${NC}"
    SESSION_KEYS=$(curl -s -H "Content-Type: application/json" \
        -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys", "params":[]}' \
        http://localhost:9944)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Session Keys berhasil didapatkan:${NC}\n"
        echo $SESSION_KEYS
        echo -e "${CYAN}Apakah Anda ingin menyimpan Session Keys ke file? (y/n)${NC}"
        read -p "> " SAVE_KEYS
        if [[ "$SAVE_KEYS" == "y" || "$SAVE_KEYS" == "Y" ]]; then
            echo $SESSION_KEYS > session_keys.txt
            echo -e "${GREEN}Session Keys disimpan di file 'session_keys.txt'.${NC}\n"
        else
            echo -e "${YELLOW}Session Keys tidak disimpan.${NC}\n"
        fi
    else
        echo -e "${RED}Gagal mendapatkan Session Keys. Pastikan port 9944 terbuka.${NC}\n"
    fi
}

# Mendapatkan ID container ZenChain
get_container_id() {
    CONTAINER_ID=$(docker ps -q -f "name=zenchain")
    if [ -z "$CONTAINER_ID" ]; then
        echo -e "${RED}Tidak dapat menemukan ID container ZenChain.${NC}\n"
        exit 1
    else
        echo -e "${GREEN}ID container ZenChain ditemukan: ${CYAN}$CONTAINER_ID${NC}\n"
    fi
}

# Memberikan informasi tentang log ZenChain Node
show_log_info() {
    echo -e "${CYAN}Jika Anda ingin melihat log ZenChain Node, Anda dapat menjalankan perintah berikut:${NC}"
    echo -e "${YELLOW}docker logs -f $CONTAINER_ID${NC}\n"
    echo -e "${CYAN}Perintah ini akan menampilkan log secara real-time untuk ZenChain Node.${NC}"
}

# Mengajak pengguna bergabung dengan channel Telegram AirdropNode
invite_to_telegram_channel() {
    echo -e "${CYAN}Jangan lupa bergabung dengan channel Telegram AirdropNode untuk mendapatkan informasi terbaru dan dukungan:${NC}"
    echo -e "${YELLOW}https://t.me/airdrop_node${NC}\n"
}

# Eksekusi script
install_docker
install_docker_compose
prompt_validator_name
create_docker_compose_file
start_docker_compose
get_session_keys
get_container_id
show_log_info
invite_to_telegram_channel
