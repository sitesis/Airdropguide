#!/bin/bash

set -e

PUTIH='\033[1;37m'
COKLAT='\033[0;33m'
ORANGE='\033[1;38;5;214m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m'

curl -s https://file.winsnip.xyz/file/uploads/Logo-winsip.sh | bash
echo -e "${CYAN}Memulai Docker dan Block-Mesh...${NC}"
sleep 2

DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_COMPOSE_URL="https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)"
BLOCKMESH_API_URL="https://api.github.com/repos/block-mesh/block-mesh-monorepo/releases/latest"

log() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo -e "-----------------------------------------------------"
    case $level in
        "INFO") echo -e "${CYAN}[INFO] ${timestamp} - ${message}${NC}" ;;
        "SUCCESS") echo -e "${COKLAT}[SUCCESS] ${timestamp} - ${message}${NC}" ;;
        "ERROR") echo -e "${PUTIH}[ERROR] ${timestamp} - ${message}${NC}" ;;
        "WARNING") echo -e "${ORANGE}[WARNING] ${timestamp} - ${message}${NC}" ;;
        *) echo -e "${MAGENTA}[LOG] ${timestamp} - ${message}${NC}" ;;
    esac
    echo -e "-----------------------------------------------------\n"
}

cleanup() {
    rm -f blockmesh-cli.tar.gz
}
trap cleanup EXIT

log "INFO" "Memulai Pengaturan Docker dan BlockMesh CLI..."
sleep 2

if docker ps -a | grep -q "blockmesh-cli-container"; then
    log "INFO" "Menghentikan dan menghapus kontainer BlockMesh CLI lama..."
    docker stop blockmesh-cli-container || true
    docker rm blockmesh-cli-container || true
    log "SUCCESS" "Kontainer lama dihentikan dan dihapus."
else
    log "INFO" "Tidak ditemukan kontainer BlockMesh CLI yang ada."
fi

log "INFO" "Memperbarui daftar paket dan menginstal paket dasar..."
apt update && apt upgrade -y

if ! command -v docker &> /dev/null; then
    log "INFO" "Menginstal Docker..."
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL $DOCKER_GPG_URL | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
else
    log "SUCCESS" "Docker sudah terinstal, melewati proses instalasi..."
fi

log "INFO" "Menginstal Docker Compose..."
curl -L $DOCKER_COMPOSE_URL -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
log "SUCCESS" "Instalasi Docker Compose selesai."

log "INFO" "Mendapatkan rilis terbaru BlockMesh CLI..."
LATEST_VERSION=$(curl -s $BLOCKMESH_API_URL | grep -Po '"tag_name": "\K.*?(?=")')

DOWNLOAD_URL="https://github.com/block-mesh/block-mesh-monorepo/releases/download/${LATEST_VERSION}/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz"
log "INFO" "Mendownload BlockMesh CLI dari: ${DOWNLOAD_URL}..."

curl -L "$DOWNLOAD_URL" -o blockmesh-cli.tar.gz

if file blockmesh-cli.tar.gz | grep -q 'gzip compressed data'; then
    mkdir -p target/release
    tar -xzf blockmesh-cli.tar.gz -C target/release
    CLI_PATH=$(find target/release -name 'blockmesh-cli' -type f | head -n 1)
    
    if [[ -f "$CLI_PATH" ]]; then
        chmod +x "$CLI_PATH"
        log "SUCCESS" "BlockMesh CLI berhasil didownload dan diekstraksi."
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

log "INFO" "Membuat kontainer Docker untuk BlockMesh CLI..."
docker run -d \
    --name blockmesh-cli-container \
    --restart unless-stopped \
    -v "$(pwd)/$CLI_PATH:/app/blockmesh-cli" \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 "./blockmesh-cli" --email "$email" --password "$password"

log "INFO" "Memeriksa status kontainer BlockMesh CLI..."
docker ps -a | grep blockmesh-cli-container

log "INFO" "Mengambil log untuk kontainer BlockMesh CLI (tekan Ctrl+C untuk berhenti)..."
docker logs -f blockmesh-cli-container

log "SUCCESS" "Pengaturan selesai dengan sukses."
