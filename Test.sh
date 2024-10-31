#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
    echo "Docker installed successfully."
}

# Function to install Docker Compose
install_docker_compose() {
    echo "Installing Docker Compose..."
    DOCKER_COMPOSE_VERSION="1.29.2" # You can change this to the latest version
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully."
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    install_docker
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    install_docker_compose
fi

# Prompt for USER_EMAIL and USER_PASSWORD
read -p "Masukkan email pengguna (USER_EMAIL): " USER_EMAIL
read -s -p "Masukkan password pengguna (USER_PASSWORD): " USER_PASSWORD
echo

# Prompt for SOCKS5 proxy with example format
read -p "Masukkan alamat SOCKS5 proxy (contoh: socks5://username:password@127.0.0.1:1080), atau biarkan kosong jika tidak menggunakan proxy: " SOCKS5_PROXY

# Create docker-compose.yml file
cat <<EOF > docker-compose.yml
version: "3.9"
services:
  grass-node:
    container_name: grass-node
    hostname: my_device
    image: airdropnode/grass-node
    environment:
      USER_EMAIL: $USER_EMAIL
      USER_PASSWORD: $USER_PASSWORD
EOF

# Add proxy configuration if SOCKS5_PROXY is provided
if [ -n "$SOCKS5_PROXY" ]; then
  echo "      ALL_PROXY: $SOCKS5_PROXY" >> docker-compose.yml
fi

# Add port mappings to docker-compose.yml
cat <<EOF >> docker-compose.yml
    ports:
      - "5900:5900"
      - "6080:6080"
EOF

# Run container with Docker Compose and handle potential errors
if ! docker-compose up -d; then
    echo "Failed to start the Docker container. Please check your configuration."
    exit 1
fi

echo "Docker container started successfully."
