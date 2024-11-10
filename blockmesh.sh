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

# Ask user if they have already registered on BlockMesh
read -p "Apakah Anda sudah terdaftar di BlockMesh? (y/n): " is_registered

if [[ "$is_registered" != "y" ]]; then
    log "LANCAR" "Silakan daftar terlebih dahulu di https://app.blockmesh.xyz/register?invite_code=airdropnode"
    read -p "Tekan Enter setelah selesai mendaftar atau N untuk keluar."
    read -p "Setelah mendaftar, tekan 'y' untuk melanjutkan: " continue_registration
    if [[ "$continue_registration" != "y" ]]; then
        log "ERROR" "Proses dihentikan. Anda harus mendaftar terlebih dahulu."
        exit 1
    fi
fi

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

# Confirm before proceeding
read -p "Apakah Anda ingin melanjutkan proses pemasangan BlockMesh CLI dengan email $email? (y/n): " confirm_continue

if [[ "$confirm_continue" != "y" ]]; then
    log "ERROR" "Proses dihentikan. Anda memilih untuk tidak melanjutkan."
    exit 1
fi

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
log "LANCAR" "Mengambil log untuk kontainer BlockMesh CLI (tekan N untuk berhenti)..."
while true; do
    read -p "Tekan 'N' untuk berhenti dari log: " user_input
    if [[ "$user_input" == "N" || "$user_input" == "n" ]]; then
        log "LANCAR" "Berhenti mengambil log BlockMesh CLI."
        break
    fi
done
docker logs -f blockmesh-cli-container

log "LANCAR" "Pengaturan selesai dengan sukses."
