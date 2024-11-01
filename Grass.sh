#!/bin/bash

# Load logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# ANSI escape codes for colors
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" >> setup_log.txt
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log "Docker is not installed."
        return 1
    else
        log "Docker is already installed."
        return 0
    fi
}

# Install Docker-CE
install_docker() {
    log "Installing Docker CE..."
    curl -sSL -k https://get.docker.com | sh || { log "Failed to install Docker"; exit 1; }
    sudo systemctl start docker
    sudo systemctl enable docker
    log "Docker CE installed and started successfully."
}

# Install Docker Compose
install_docker_compose() {
    log "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { log "Failed to download Docker Compose"; exit 1; }
    chmod +x /usr/local/bin/docker-compose || { log "Failed to set permissions for Docker Compose"; exit 1; }
    log "Docker Compose installed successfully."
}

# Clone the grass repository
clone_grass_repo() {
    log "Cloning the grass repository..."
    git clone https://github.com/MsLolita/grass.git || { log "Failed to clone repository"; exit 1; }
    log "Grass repository cloned successfully."

    # Navigate to the grass directory
    cd grass || { log "Failed to enter grass directory"; exit 1; }
}

# Update accounts.txt with email and password
update_accounts() {
    # Navigate to the data directory
    cd data || { log "Failed to access grass/data directory"; exit 1; }

    # Clear accounts.txt and write new email and password
    read -p "Enter your email: " user_email_input
    read -sp "Enter your password: " user_password_input
    echo
    echo "$user_email_input:$user_password_input" > accounts.txt
    log "accounts.txt updated successfully."
}

# Update proxies.txt with static proxy
update_proxies() {
    # Navigate to the data directory
    cd data || { log "Failed to access grass/data directory"; exit 1; }

    # Clear proxies.txt and write new proxy
    read -p "Enter static proxy IP:PORT: " static_proxy_input
    echo "$static_proxy_input" > proxies.txt
    log "proxies.txt updated successfully."
}

# Run Docker Compose
start_container() {
    cd .. # Go back to the grass directory
    docker-compose up -d || { log "Failed to start Docker Compose"; exit 1; }
    log "Docker container started successfully."
}

# Execute main functions
check_docker || install_docker
install_docker_compose
clone_grass_repo
update_accounts
update_proxies
start_container

log "Setup completed."
