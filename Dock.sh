#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script requires root privileges. Please run as root or use 'sudo'.${NC}"
    exit 1
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is already installed. Skipping installation.${NC}"
    docker --version
    exit 0
fi

# Update and install required dependencies
echo -e "${GREEN}Updating system and installing dependencies...${NC}"
if ! apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release; then
    echo -e "${RED}Failed to update and install dependencies.${NC}"
    exit 1
fi

# Add Docker’s official GPG key
echo -e "${GREEN}Adding Docker's official GPG key...${NC}"
mkdir -p /etc/apt/keyrings
if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
    echo -e "${RED}Failed to add Docker's GPG key.${NC}"
    exit 1
fi

# Set up the Docker repository
echo -e "${GREEN}Adding Docker repository...${NC}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and components
echo -e "${GREEN}Installing Docker Engine...${NC}"
if ! apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
    echo -e "${RED}Failed to install Docker Engine.${NC}"
    exit 1
fi

# Verify Docker installation
echo -e "${GREEN}Verifying Docker installation...${NC}"
if docker --version; then
    echo -e "${GREEN}Docker successfully installed!${NC}"
else
    echo -e "${RED}Error occurred during Docker installation.${NC}"
    exit 1
fi
