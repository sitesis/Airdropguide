#!/bin/bash

# Load logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# ANSI escape codes for colors
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a grass/setup_log.txt
}

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)." 
    exit 1
fi

# Create grass directory
mkdir -p grass
cd grass || { echo "Failed to enter the grass directory"; exit 1; }

# Main installation function
install_dependencies() {
    log "Checking and installing dependencies..."

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log "Docker is not installed. Installing Docker..."
        curl -sSL -k https://get.docker.com | sh || { log "Failed to install Docker"; exit 1; }
        sudo systemctl start docker
        sudo systemctl enable docker
        log "Docker installed and started successfully."
    else
        log "Docker is already installed."
    fi

    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { log "Failed to download Docker Compose"; exit 1; }
        chmod +x /usr/local/bin/docker-compose || { log "Failed to set permissions for Docker Compose"; exit 1; }
        log "Docker Compose installed successfully."
    else
        log "Docker Compose is already installed."
    fi
}

# Create docker-compose.yml file
create_docker_compose() {
    log "Creating docker-compose.yml file..."

    # Prompt for email, password, and proxy
    read -p "Enter your email: " USER_EMAIL
    read -sp "Enter your password: " USER_PASSWORD
    echo  # For a new line after password input
    read -p "Enter your proxy (format: http://username:password@IP:PORT): " PROXY

    cat <<EOL > docker-compose.yml
version: "3.9"

services:
  grass-node:
    container_name: grass-node
    hostname: my_device
    image: mrcolorrain/grass-node
    environment:
      USER_EMAIL: $USER_EMAIL  # User-provided email
      USER_PASSWORD: $USER_PASSWORD  # User-provided password
      HTTP_PROXY: $PROXY  # User-provided proxy
      HTTPS_PROXY: $PROXY  # Use the same proxy for HTTPS
    ports:
      - "5900:5900"
      - "6080:6080"
    restart: unless-stopped  # Automatically restart the container unless it was manually stopped
    volumes:
      - grass-node-data:/data  # Persist data in a named volume

volumes:
  grass-node-data:  # Define a volume for persistent storage
EOL

    log "docker-compose.yml file created successfully."
}

# Start the Docker service
start_services() {
    log "Checking if grass-node service is already running..."
    if [ $(docker ps -q -f name=grass-node) ]; then
        log "grass-node service is already running."
    else
        log "Starting the grass-node service..."
        docker-compose up -d || { log "Failed to start the service"; exit 1; }
        log "grass-node service started successfully."
    fi
}

# Call the installation and setup functions
install_dependencies
create_docker_compose
start_services
