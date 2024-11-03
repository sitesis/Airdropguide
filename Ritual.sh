#!/bin/bash

set -e  # Exit immediately on error

# Function to update and upgrade the system
update_system() {
    echo "Updating and upgrading the system..."
    if sudo apt update && sudo apt upgrade -y; then
        echo "System updated successfully."
    else
        echo "Failed to update or upgrade the system."
        exit 1
    fi
}

# Function to install build tools
install_build_tools() {
    echo "Installing build tools..."
    if sudo apt install -qy curl git jq lz4 build-essential; then
        echo "Build tools installed successfully."
    else
        echo "Failed to install build tools."
        exit 1
    fi
}

# Function to install Docker if not already installed
install_docker() {
    echo "Checking for Docker installation..."
    if command -v docker &> /dev/null; then
        echo "Docker is already installed. Skipping installation."
        return
    fi

    echo "Docker not found. Installing Docker..."
    
    # Install required packages
    sudo apt install -qy apt-transport-https ca-certificates curl software-properties-common
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    # Set up the stable repository
    echo "Adding Docker's official repository..."
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update the package database again
    echo "Updating package database..."
    sudo apt update

    # Install Docker
    if sudo apt install -qy docker-ce docker-ce-cli containerd.io; then
        echo "Docker installed successfully."
    else
        echo "Failed to install Docker."
        exit 1
    fi

    # Enable and start Docker service
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "Docker service started and enabled to run on boot."
}

# Function to install Docker Compose if not already installed
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose not found. Installing Docker Compose..."
        LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
        if sudo curl -L "https://github.com/docker/compose/releases/download/${LATEST_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
            sudo chmod +x /usr/local/bin/docker-compose
            echo "Docker Compose installed successfully."
        else
            echo "Failed to install Docker Compose."
            exit 1
        fi
    else
        echo "Docker Compose is already installed. Skipping installation."
    fi
}

# Function to clone the starter repository if not already cloned
clone_repository() {
    REPO_URL="https://github.com/ritual-net/infernet-container-starter"
    REPO_DIR="infernet-container-starter"

    if [ ! -d "$REPO_DIR" ]; then
        echo "Cloning starter repository..."
        if git clone "$REPO_URL"; then
            echo "Repository cloned successfully."
        else
            echo "Failed to clone the repository."
            exit 1
        fi
    else
        echo "Repository already cloned. Updating repository..."
        cd "$REPO_DIR" && git pull || { echo "Failed to update the repository."; exit 1; }
    fi

    # Move into the repository directory
    cd "$REPO_DIR" || exit
    echo "Moved into directory: $(pwd)"
}

# Function to update configuration files
update_configurations() {
    echo "Updating configuration files..."

    # Prompt for the private key securely
    read -sp "Enter your private key: " PRIVATE_KEY
    echo

    # Update the first config.json
    CONFIG_FILE1=~/infernet-container-starter/deploy/config.json
    echo "Updating $CONFIG_FILE1..."
    jq --arg pk "$PRIVATE_KEY" '.RPC_URL = "https://mainnet.base.org/" | .Private_Key = $pk | .Registry = "0xe2F36C4E23D67F81fE0B278E80ee85Cf0ccA3c8d"' "$CONFIG_FILE1" | sponge "$CONFIG_FILE1"

    # Update the second config.json
    CONFIG_FILE2=~/infernet-container-starter/projects/hello-world/container/config.json
    echo "Updating $CONFIG_FILE2..."
    jq --arg pk "$PRIVATE_KEY" '.RPC_URL = "https://mainnet.base.org/" | .Private_Key = $pk | .Registry = "0xe2F36C4E23D67F81fE0B278E80ee85Cf0ccA3c8d" | .trail_head_blocks = 3 | .snapshot_sync.sleep = 3 | .snapshot_sync.starting_sub_id = 160000 | .snapshot_sync.batch_size = 800 | .snapshot_sync.sync_period = 30' "$CONFIG_FILE2" | sponge "$CONFIG_FILE2"

    # Update Deploy.s.sol for node version
    DEPLOY_FILE=~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol
    echo "Updating node version in $DEPLOY_FILE..."
    sed -i 's/^pragma solidity .*;$/pragma solidity 1.4.0;/' "$DEPLOY_FILE"

    # Update Deploy.s.sol for sender's address
    echo "Updating sender's address in $DEPLOY_FILE..."
    sed -i "s/address sender = address(uint160(uint256(keccak256(abi.encodePacked(\"0xYOUR_PRIVATE_KEY\")))))/address sender = \"$PRIVATE_KEY\"/" "$DEPLOY_FILE"

    # Update docker-compose.yaml
    DOCKER_COMPOSE_FILE=~/infernet-container-starter/deploy/docker-compose.yaml
    echo "Updating $DOCKER_COMPOSE_FILE..."
    sed -i 's/image: my-image-name/image: your-new-image-name/' "$DOCKER_COMPOSE_FILE" # Replace with the correct image name
}

# Function to restart Docker containers
restart_containers() {
    echo "Restarting Docker containers..."
    docker restart infernet-anvil || echo "Failed to restart infernet-anvil"
    docker restart hello-world || echo "Failed to restart hello-world"
    docker restart infernet-node || echo "Failed to restart infernet-node"
    docker restart deploy-fluentbit-1 || echo "Failed to restart deploy-fluentbit-1"
    docker restart deploy-redis-1 || echo "Failed to restart deploy-redis-1"
    echo "Docker containers restarted successfully."
}

# Main function to run all installations and configurations
main() {
    echo "Starting installation and setup..."
    update_system
    install_build_tools
    install_docker
    install_docker_compose
    clone_repository
    update_configurations
    restart_containers

    # Display Docker and Docker Compose versions
    echo "Installation, repository setup, configuration updates, and container restarts complete."
    docker --version
    docker-compose --version
}

# Execute the main function
main
