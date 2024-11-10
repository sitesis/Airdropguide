#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

set -e

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "-----------------------------------------------------"
    case $level in
        "SUCCESS") echo -e "[SUCCESS] ${timestamp} - ${message}" ;;
        "ERROR") echo -e "[ERROR] ${timestamp} - ${message}" ;;
        "WARNING") echo -e "[WARNING] ${timestamp} - ${message}" ;;
        *) echo -e "[LOG] ${timestamp} - ${message}" ;;
    esac
    echo -e "-----------------------------------------------------\n"
}

cleanup() {
    rm -f blockmesh-cli.tar.gz
}
trap cleanup EXIT

log "SUCCESS" "Memulai Pengaturan Docker dan BlockMesh CLI..."
sleep 2

if docker ps -a | grep -q "blockmesh-cli-container"; then
    docker stop blockmesh-cli-container || true
    docker rm blockmesh-cli-container || true
else
    log "SUCCESS" "Tidak ditemukan kontainer BlockMesh CLI yang ada."
fi

log "SUCCESS" "Memperbarui daftar paket dan menginstal paket dasar..."
apt update && apt upgrade -y

if ! command -v docker &> /dev/null; then
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL $DOCKER_GPG_URL | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
fi

log "SUCCESS" "Menginstal Docker Compose..."
curl -L $DOCKER_COMPOSE_URL -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
log "SUCCESS" "Instalasi Docker Compose selesai."

log "SUCCESS" "Mendapatkan rilis terbaru BlockMesh CLI..."
LATEST_VERSION=$(curl -s $BLOCKMESH_API_URL | grep -Po '"tag_name": "\K.*?(?=")')

DOWNLOAD_URL="https://github.com/block-mesh/block-mesh-monorepo/releases/download/${LATEST_VERSION}/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
curl -L "$DOWNLOAD_URL" -o blockmesh-cli.tar.gz

if file blockmesh-cli.tar.gz | grep -q 'gzip compressed data'; then
    mkdir -p target/release
    tar -xzf blockmesh-cli.tar.gz -C target/release
    CLI_PATH=$(find target/release -name 'blockmesh-cli' -type f | head -n 1)
    
    if [[ -f "$CLI_PATH" ]]; then
        chmod +x "$CLI_PATH"
    else
        log "ERROR" "Eksekutabel blockmesh-cli tidak ditemukan setelah ekstraksi."
        exit 1
    fi
else
    log "ERROR" "File yang didownload bukan format gzip yang valid."
    exit 1
fi

read -p "Masukkan Email: " email
read -sp "Masukkan Password: " password
echo

docker run -d \
    --name blockmesh-cli-container \
    --restart unless-stopped \
    -v "$(pwd)/$CLI_PATH:/app/blockmesh-cli" \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 "./blockmesh-cli" --email "$email" --password "$password"

log "SUCCESS" "Memeriksa status kontainer BlockMesh CLI..."
docker ps -a | grep blockmesh-cli-container

log "SUCCESS" "Mengambil log untuk kontainer BlockMesh CLI (tekan Ctrl+C untuk berhenti)..."
docker logs -f blockmesh-cli-container

log "SUCCESS" "Pengaturan selesai dengan sukses."
