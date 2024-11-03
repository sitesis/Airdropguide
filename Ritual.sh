#!/bin/bash

set -e  # Exit immediately on error

# Redirect output to a log file
exec > >(tee -i setup.log) 2>&1

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
    if sudo apt install -qy curl git jq lz4 build-essential screen; then
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
    STABLE_COMPOSE_VERSION="v2.10.2"  # Specify a stable version
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose not found. Installing Docker Compose..."
        if sudo curl -L "https://github.com/docker/compose/releases/download/${STABLE_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
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

# Function to install Docker CLI Plugin for Docker Compose if not already installed
install_docker_cli_plugin() {
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    if [ ! -f "$DOCKER_CONFIG/cli-plugins/docker-compose" ]; then
        echo "Docker CLI plugin for Docker Compose not found. Installing plugin..."
        mkdir -p "$DOCKER_CONFIG/cli-plugins"
        if curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" -o "$DOCKER_CONFIG/cli-plugins/docker-compose"; then
            chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"
            echo "Docker CLI plugin for Docker Compose installed successfully."
        else
            echo "Failed to install Docker CLI plugin for Docker Compose."
            exit 1
        fi
    else
        echo "Docker CLI plugin for Docker Compose is already installed. Skipping installation."
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

# Function to deploy the container using a screen session
deploy_container() {
    if screen -list | grep -q "ritual"; then
        echo "Screen session 'ritual' already exists. Please detach or remove it before proceeding."
        exit 1
    fi

    echo "Starting screen session named 'ritual' to deploy the container..."

    # Run all commands in a single screen session
    screen -S ritual -d -m bash -c "
        echo 'Pulling Docker image ritualnetwork/hello-world-infernet:latest...' &&
        docker pull ritualnetwork/hello-world-infernet:latest &&
        echo 'Image pulled successfully.' &&
        echo 'Deploying the container...' &&
        project=hello-world make deploy-container &&
        echo 'Deployment complete. Press Ctrl+A then D to detach from this session.'
    "

    echo "You can reattach to the screen session using: screen -r ritual"
    echo "To view the container logs, use: docker logs -f <container_id_or_name>"
}

# Main function to run all installations and configurations
main() {
    echo "Starting installation and setup..."
    update_system
    install_build_tools
    install_docker
    install_docker_compose
    install_docker_cli_plugin
    clone_repository
    deploy_container

    # Display Docker and Docker Compose versions
    echo "Installation, repository setup, and container deployment complete."
    docker --version
    docker-compose --version
}

# Execute the main function
main
