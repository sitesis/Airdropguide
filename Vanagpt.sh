#!/bin/bash

# Function to check if Docker is installed
check_docker_installed() {
  if command -v docker &> /dev/null; then
    echo "Docker is already installed. Skipping installation."
    return 0
  else
    return 1
  fi
}

# Create and navigate into the 'sixgpt' directory if not already there
if [ ! -d "sixgpt" ]; then
  mkdir sixgpt
fi
cd sixgpt

# Check if Docker is installed, if not, proceed with the installation
if ! check_docker_installed; then
  # Update and upgrade the system
  sudo apt update -y && sudo apt upgrade -y

  # Remove old Docker and related packages
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
  done

  # Install necessary dependencies
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg

  # Set up Docker's official GPG key
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  # Add Docker repository
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Update and upgrade after adding Docker repository
  sudo apt update -y && sudo apt upgrade -y

  # Install Docker
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

  # Make Docker Compose executable
  sudo chmod +x /usr/local/bin/docker-compose

  # Verify Docker installation
  docker --version
fi

# Create .gitignore and add entries to it
echo -e "# Ignore environment files\n.env\n# Ignore Docker files\ndocker-compose.yml\n# Ignore private key file\n*.key\n" > .gitignore

# Create docker-compose.yml with the provided content
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
      - VANA_PRIVATE_KEY=${VANA_PRIVATE_KEY}
      - VANA_NETWORK=${VANA_NETWORK}
    restart: always

volumes:
  ollama:
EOF

# Set environment variables
echo "Enter your VANA_PRIVATE_KEY:"
read VANA_PRIVATE_KEY
export VANA_PRIVATE_KEY

export VANA_NETWORK=satori

# Confirm the variables are set
echo "VANA_PRIVATE_KEY is set."
echo "VANA_NETWORK is set to $VANA_NETWORK."
