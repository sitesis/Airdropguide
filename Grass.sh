#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# ANSI escape codes for colors
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" >> setup_log.txt
}

# Check and install Docker if not installed
install_docker() {
    if ! command -v docker &> /dev/null; then
        log "Docker tidak ditemukan. Menginstal Docker..."
        sudo apt update
        sudo apt install -y docker.io || { log "Gagal menginstal Docker"; exit 1; }
        sudo systemctl start docker
        sudo systemctl enable docker
        log "Docker sudah diinstal dan dijalankan."
    else
        log "Docker sudah terinstal."
    fi
}

# Check and install Docker Compose if not installed
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        log "Docker Compose tidak ditemukan. Menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { log "Gagal mendownload Docker Compose"; exit 1; }
        sudo chmod +x /usr/local/bin/docker-compose || { log "Gagal mengatur izin untuk Docker Compose"; exit 1; }
        log "Docker Compose sudah diinstal."
    else
        log "Docker Compose sudah terinstal."
    fi
}

# Function to set up and run the grass node
setup_grass_node() {
    # Set up working directory
    DIRECTORY="grass_node_directory"
    mkdir -p "$DIRECTORY"
    cd "$DIRECTORY" || { log "Gagal mengakses direktori $DIRECTORY"; exit 1; }

    # Prompt for credentials
    read -p "Masukkan email Anda: " USER_EMAIL
    read -sp "Masukkan kata sandi Anda: " USER_PASSWORD
    echo

    # Prompt for proxy input
    echo "Masukkan static proxy IP:PORT (HTTP) jika ada, pisahkan dengan spasi untuk lebih dari satu, tekan Enter untuk melewati:"
    read -r PROXY_INPUT

    # Create array from proxy input
    PROXIES=($PROXY_INPUT)

    # Create docker-compose.yml file
    {
        echo "version: '3.9'"
        echo "services:"
        echo "  grass-node:"
        echo "    container_name: grass-node"
        echo "    hostname: my_device"
        echo "    image: mrcolorrain/grass-node"
        echo "    environment:"
        echo "      USER_EMAIL: \"$USER_EMAIL\""
        echo "      USER_PASSWORD: \"$USER_PASSWORD\""

        # Append proxies if any
        if [ -n "$PROXY_INPUT" ]; then
            for PROXY in "${PROXIES[@]}"; do
                if [ -n "$PROXY" ]; then
                    echo "      PROXY: ${PROXY}" # Ensure correct format with ':'
                fi
            done
        fi

        # Append ports to the docker-compose.yml file
        echo "    ports:"
        echo "      - \"5900:5900\""
        echo "      - \"6080:6080\""
    } > docker-compose.yml

    # Run Docker Compose
    docker-compose up -d || { log "Gagal menjalankan Docker Compose"; exit 1; }
    log "Node berhasil diinstal dan dijalankan."

    # Show specific logs from grass node
    log "Menampilkan log spesifik dari node grass..."
    docker-compose logs grass-node
}

# Execute main functions
install_docker
install_docker_compose
setup_grass_node
