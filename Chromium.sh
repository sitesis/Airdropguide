#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Function to check if script is run as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root. Exiting..."
        exit 1
    fi
}

# Function to check and install Docker
install_docker() {
    echo "Installing Docker..."
    sudo apt update -y && sudo apt upgrade -y || { echo "Failed to update packages. Exiting..."; exit 1; }

    # Remove conflicting packages
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg || echo "Failed to remove $pkg, it may not be installed."
    done

    # Install necessary dependencies
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common || { echo "Failed to install dependencies. Exiting..."; exit 1; }
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - || { echo "Failed to add Docker GPG key. Exiting..."; exit 1; }
    
    # Set up the Docker stable repository
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" || { echo "Failed to add Docker repository. Exiting..."; exit 1; }
    
    # Install Docker
    sudo apt update -y && sudo apt install -y docker-ce || { echo "Failed to install Docker. Exiting..."; exit 1; }
    
    # Start and enable Docker service
    sudo systemctl start docker || { echo "Failed to start Docker service. Exiting..."; exit 1; }
    sudo systemctl enable docker || { echo "Failed to enable Docker service. Exiting..."; exit 1; }

    echo "Docker installed successfully."
}

# Function to check and install Docker Compose
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { echo "Failed to download Docker Compose. Exiting..."; exit 1; }
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully."
    else
        echo "Docker Compose is already installed."
    fi
}

# Check if script is run as root
check_root

# Check and install Docker
if ! command -v docker &> /dev/null; then
    install_docker
else
    echo "Docker is already installed."
fi

# Check and install Docker Compose
install_docker_compose

# Get server timezone
TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -z "$TIMEZONE" ]; then
    read -p "Enter your timezone (default: Asia/Jakarta): " user_timezone
    TIMEZONE=${user_timezone:-Asia/Jakarta}
fi
echo "Server timezone detected: $TIMEZONE"

# Generate random username and password
CUSTOM_USER=$(openssl rand -hex 4)
PASSWORD=$(openssl rand -hex 12)
echo "Generated username: $CUSTOM_USER"
echo "Generated password: $PASSWORD"

# Set up Chromium with Docker Compose
echo "Setting up Chromium with Docker Compose..."
mkdir -p $HOME/chromium && cd $HOME/chromium

cat <<EOF > docker-compose.yaml
---
services:
  chromium:
    image: lscr.io/linuxserver/chromium:latest
    container_name: chromium
    security_opt:
      - seccomp:unconfined
    environment:
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
      - PUID=1000
      - PGID=1000
      - TZ=$TIMEZONE
      - LANG=en_US.UTF-8
      - CHROME_CLI=https://google.com/
    volumes:
      - /root/chromium/config:/config
    ports:
      - 3010:3000
      - 3011:3001
    shm_size: "1gb"
    restart: unless-stopped
EOF

# Verify that docker-compose.yaml was created successfully
if [ ! -f "docker-compose.yaml" ]; then
    echo "Failed to create docker-compose.yaml. Exiting..."
    exit 1
fi

# Run Chromium container
echo "Running Chromium container..."
docker-compose up -d || { echo "Failed to run Docker container. Exiting..."; exit 1; }

# Get VPS IP address
IPVPS=$(curl -s ifconfig.me)

# Output access information
echo "Access Chromium in your browser at: http://$IPVPS:3010/ or https://$IPVPS:3011/"
echo "Username: $CUSTOM_USER"
echo "Password: $PASSWORD"
echo "Please save your data, or you will lose access!"

# Cleanup unused Docker resources
docker system prune -f
echo "Docker system pruned.
echo -e "\n🎉 **Rampung! ** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
