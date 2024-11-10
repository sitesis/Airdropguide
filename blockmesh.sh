#!/bin/bash

set -e

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "-----------------------------------------------------"
    case $level in
        "LANCAR") echo -e "[LANCAR] ${timestamp} - ${message}" ;;
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

log "LANCAR" "Memulai Pengaturan Docker dan BlockMesh CLI..."
sleep 2

# Set URLs
DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)"
BLOCKMESH_API_URL="https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest"

# Debug: Print the URLs to verify they are set correctly
log "LOG" "DOCKER_GPG_URL: $DOCKER_GPG_URL"
log "LOG" "DOCKER_COMPOSE_URL: $DOCKER_COMPOSE_URL"
log "LOG" "BLOCKMESH_API_URL: $BLOCKMESH_API_URL"

# Check if BlockMesh CLI container exists and stop/remove it if so
if docker ps -a | grep -q "blockmesh-cli-container"; then
    log "LANCAR" "Menghentikan dan menghapus kontainer BlockMesh CLI lama..."
    docker stop blockmesh-cli-container || true
    docker rm blockmesh-cli-container || true
else
    log "LANCAR" "Tidak ditemukan kontainer BlockMesh CLI yang ada."
fi

# Update packages
log "LANCAR" "Memperbarui daftar paket dan menginstal paket dasar..."
apt update && apt upgrade -y

# Skip Docker installation if it's already installed
if ! command -v docker &> /dev/null; then
    log "LANCAR" "Menginstal Docker..."
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL $DOCKER_GPG_URL | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
else
    log "LANCAR" "Docker sudah terinstal, melewati proses instalasi..."
fi

# Install Docker Compose
log "LANCAR" "Menginstal Docker Compose..."
curl -L $DOCKER_COMPOSE_URL -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
log "LANCAR" "Instalasi Docker Compose selesai."

# Fetch the latest BlockMesh CLI release
log "LANCAR" "Mendapatkan rilis terbaru BlockMesh CLI..."
LATEST_VERSION=$(curl -s $BLOCKMESH_API_URL | grep -Po '"tag_name": "\K.*?(?=")')

# Check if the version was retrieved successfully
if [ -z "$LATEST_VERSION" ]; then
    log "ERROR" "Gagal mendapatkan rilis terbaru dari BlockMesh API."
    exit 1
fi

# Download the latest BlockMesh CLI release
DOWNLOAD_URL="https://github.com/block-mesh/block-mesh-monorepo/releases/download/${LATEST_VERSION}/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
log "LANCAR" "Mendownload BlockMesh CLI dari: ${DOWNLOAD_URL}..."
curl -L "$DOWNLOAD_URL" -o blockmesh-cli.tar.gz

# Verify if the downloaded file is a valid gzip file
if file blockmesh-cli.tar.gz | grep -q 'gzip compressed data'; then
    mkdir -p target/release
    tar -xzf blockmesh-cli.tar.gz -C target/release
    CLI_PATH=$(find target/release -name 'blockmesh-cli' -type f | head -n 1)
    
    if [[ -f "$CLI_PATH" ]]; then
        chmod +x "$CLI_PATH"
        log "LANCAR" "BlockMesh CLI berhasil didownload dan diekstraksi."
    else
        log "ERROR" "Eksekutabel blockmesh-cli tidak ditemukan setelah ekstraksi."
        exit 1
    fi
else
    log "ERROR" "File yang didownload bukan format gzip yang valid."
    exit 1
fi

# User input for email and password
read -p "Masukkan Email: " email
read -sp "Masukkan Password: " password
echo

# Create Docker container for BlockMesh CLI
log "LANCAR" "Membuat kontainer Docker untuk BlockMesh CLI..."
docker run -d \
    --name blockmesh-cli-container \
    --restart unless-stopped \
    -v "$(pwd)/$CLI_PATH:/app/blockmesh-cli" \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 "./blockmesh-cli" --email "$email" --password "$password"

# Check BlockMesh CLI container status
log "LANCAR" "Memeriksa status kontainer BlockMesh CLI..."
docker ps -a | grep blockmesh-cli-container

# Fetch logs for BlockMesh CLI container
log "LANCAR" "Mengambil log untuk kontainer BlockMesh CLI (tekan Ctrl+C untuk berhenti)..."
docker logs -f blockmesh-cli-container

log "LANCAR" "Pengaturan selesai dengan sukses."
