#!/bin/bash

# Update and upgrade packages
sudo apt update -y && sudo apt upgrade -y

# Remove old versions of Docker if installed
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
done

# Update the package list and install required packages
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

# Setup Docker's APT repository
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and upgrade again to reflect new Docker repository
sudo apt update -y && sudo apt upgrade -y

# Install Docker and its components
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Ensure Docker Compose is executable
sudo chmod +x /usr/local/bin/docker-compose

# Check Docker version
docker --version

# Create the 'vanagpt' folder and navigate into it
mkdir vanagpt
cd vanagpt

# Prompt for private key input
read -p "Enter your private key: " VANA_PRIVATE_KEY

# Set environment variables
export VANA_PRIVATE_KEY=$VANA_PRIVATE_KEY
export VANA_NETWORK=satori

# Print the environment variables
echo "Docker installation complete. You are now in the vanagpt folder."
echo "Private Key set: $VANA_PRIVATE_KEY"
echo "Network set to: $VANA_NETWORK"

# Create docker-compose.yml file
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:0.3.12
    ports:
      - "11435:11434"
    volumes:
      - ollama:/root/.ollama
    restart: unless-stopped

  sixgpt3:
    image: sixgpt/miner:latest
    ports:
      - "3015:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=\${VANA_PRIVATE_KEY}
      - VANA_NETWORK=\${VANA_NETWORK}
    restart: always

volumes:
  ollama:
EOF

echo "docker-compose.yml file has been created."
