#!/bin/bash

# Prompt for user input with hidden password for added security
prompt_credentials() {
    while [[ -z "$USER_EMAIL" ]]; do
        echo -n "Enter your email: "
        read USER_EMAIL
    done
    while [[ -z "$USER_PASSWORD" ]]; do
        echo -n "Enter your password: "
        read -s USER_PASSWORD
        echo
    done
}

# Save credentials to .env file with restricted permissions
save_credentials() {
    {
        echo "USER_EMAIL=${USER_EMAIL}"
        echo "USER_PASSWORD=${USER_PASSWORD}"
    } > .env
    chmod 600 .env
}

# Install node function with registration link and check
install_node() {
    echo "To continue, please register at the following link:"
    echo "https://app.blockmesh.xyz/register?invite_code=airdropnode"
    echo -n "Have you completed registration? (y/n): "
    read -r registered

    if [[ "$registered" != "y" && "$registered" != "Y" ]]; then
        echo "Please complete the registration and use referral code airdropnode to continue."
        return
    fi

    echo "Installing node..."

    # Update package list
    sudo apt update -y

    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt install docker.io -y || { echo "Failed to install Docker."; return; }
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        echo "Docker is already installed."
    fi

    # Install Docker Compose if not present
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
        sudo chmod +x /usr/local/bin/docker-compose || { echo "Failed to install Docker Compose."; return; }
    else
        echo "Docker Compose is already installed."
    fi

    # Prompt for credentials after installations
    prompt_credentials
    save_credentials

    # Start the node
    docker-compose up -d || { echo "Failed to start the node."; return; }
    echo "Node installed successfully. Check the logs to confirm authentication."
}

# View logs function
view_logs() {
    echo "Viewing logs..."
    docker-compose logs
}

# Start node function
start_node() {
    if [[ ! -f .env ]]; then
        echo ".env file not found. Please run 'install' or 'change-account' to set up your account."
        return
    fi

    echo "Starting node..."
    docker-compose up -d || { echo "Failed to start the node."; return; }
    echo "Node started."
} 

# View account function
view_account() {
    if [[ -f .env ]]; then
        echo "Current account details:"
        cat .env
    else
        echo ".env file not found."
    fi
}

# Main script flow to handle command-line arguments
case "$1" in
    install)
        install_node
        ;;
    view_logs)
        view_logs
        ;;
    start)
        start_node
        ;;
    view_account)
        view_account
        ;;
    *)
        echo "Usage: $0 {install|view_logs|start|view_account}"
        ;;
esac
