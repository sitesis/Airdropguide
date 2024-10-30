#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Define the project directory and Docker image version
PROJECT_DIR="$HOME/blockmesh_node"
DOCKER_IMAGE="dknodes/blockmesh-cli_x86_64:v0.0.316"

# Function to create the project directory
create_directory() {
    if [[ ! -d "$PROJECT_DIR" ]]; then
        echo "Creating project directory at $PROJECT_DIR..."
        mkdir -p "$PROJECT_DIR" || { echo "Failed to create project directory."; return; }
    else
        echo "Project directory already exists at $PROJECT_DIR."
    fi
}

# Function to create the docker-compose.yml file
create_docker_compose() {
    cat <<EOF > "$PROJECT_DIR/docker-compose.yml"
version: '3.8'

services:
  blockmesh-cli:
    image: $DOCKER_IMAGE
    container_name: blockmesh-cli
    environment:
      - USER_EMAIL=\${USER_EMAIL}
      - USER_PASSWORD=\$(openssl enc -aes-256-cbc -base64 -d <<< \${USER_PASSWORD_ENC})
    restart: on-failure
EOF
    echo "Created docker-compose.yml file in $PROJECT_DIR."
}

# Function to validate email format
validate_email() {
    if ! [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid email format."
        exit 1
    fi
}

# Prompt for user input with hidden password for added security
prompt_credentials() {
    while [[ -z "$USER_EMAIL" ]]; do
        read -p "Enter your email: " USER_EMAIL
        validate_email "$USER_EMAIL"
    done
    while [[ -z "$USER_PASSWORD" ]]; do
        read -s -p "Enter your password: " USER_PASSWORD
        echo
    done
}

# Encrypt and save credentials to .env file with restricted permissions
save_credentials() {
    {
        echo "USER_EMAIL=${USER_EMAIL}"
        echo "USER_PASSWORD_ENC=$(echo "$USER_PASSWORD" | openssl enc -aes-256-cbc -base64)"
    } > "$PROJECT_DIR/.env"
    chmod 600 "$PROJECT_DIR/.env"
    echo "Credentials saved securely in $PROJECT_DIR/.env."
}

# Install node function with registration link and check
install_node() {
    echo "To continue, please register at the following link:"
    echo "https://app.blockmesh.xyz/register?invite_code=airdropnode"
    read -p "Have you completed registration? (y/n): " registered

    if [[ "$registered" != "y" && "$registered" != "Y" ]]; then
        echo "Please complete the registration and use referral code airdropnode to continue."
        return
    fi

    echo "Installing node..."

    # Create the project directory
    create_directory

    # Change to project directory
    cd "$PROJECT_DIR" || { echo "Failed to change directory to $PROJECT_DIR."; return; }

    # Create the docker-compose.yml file
    create_docker_compose

    # Update package list and install dependencies
    sudo apt update -y
    sudo apt install -y docker.io openssl

    # Start and enable Docker service
    sudo systemctl enable --now docker

    # Install Docker Compose if not present
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
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
    cd "$PROJECT_DIR" || { echo "Failed to change directory to $PROJECT_DIR."; return; }
    docker-compose logs
}

# Start node function
start_node() {
    if [[ ! -f "$PROJECT_DIR/.env" ]]; then
        echo ".env file not found. Please run 'install' or 'change-account' to set up your account."
        return
    fi

    echo "Starting node..."
    cd "$PROJECT_DIR" || { echo "Failed to change directory to $PROJECT_DIR."; return; }
    docker-compose up -d || { echo "Failed to start the node."; return; }
    echo "Node started."
}

# Cleanup function to stop and remove the node
cleanup_node() {
    echo "Stopping and removing the node..."
    cd "$PROJECT_DIR" || { echo "Failed to change directory to $PROJECT_DIR."; return; }
    docker-compose down || { echo "Failed to stop the node."; return; }
    echo "Node cleaned up successfully."
}

# View account function
view_account() {
    if [[ -f "$PROJECT_DIR/.env" ]]; then
        echo "Current account details:"
        cat "$PROJECT_DIR/.env"
    else
        echo ".env file not found."
    fi
}

# Interactive menu function
interactive_menu() {
    echo "===================="
    echo " Blockmesh Node CLI "
    echo "===================="
    echo "Please select an option:"
    echo "1) Install Node"
    echo "2) View Logs"
    echo "3) Start Node"
    echo "4) View Account"
    echo "5) Cleanup Node"
    echo "6) Exit"

    read -p "Enter your choice [1-6]: " choice
    case "$choice" in
        1) install_node ;;
        2) view_logs ;;
        3) start_node ;;
        4) view_account ;;
        5) cleanup_node ;;
        6) exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
}

# Main script flow
if [[ $# -eq 0 ]]; then
    # Run interactive menu if no arguments are provided
    interactive_menu
else
    # Command-line arguments support for automation
    case "$1" in
        install) install_node ;;
        view_logs) view_logs ;;
        start) start_node ;;
        view_account) view_account ;;
        cleanup) cleanup_node ;;
        *) echo "Usage: $0 {install|view_logs|start|view_account|cleanup}" ;;
    esac
fi
