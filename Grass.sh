#!/bin/bash

# ANSI escape codes for colors
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
UNDERLINE_YELLOW='\033[1;4;33m'
NC='\033[0m' # No Color

# Function to display logo
display_logo() {
    echo -e "${YELLOW}
           _         _                   _   _           _      
     /\   (_)       | |                 | \ | |         | |     
    /  \   _ _ __ __| |_ __ ___  _ __   |  \| | ___   __| | ___ 
   / /\ \ | | '__/ _\` | '__/ _ \| '_ \  | . \` |/ _ \ / _\` |/ _ \\
  / ____ \| | | | (_| | | | (_) | |_) | | |\  | (_) | (_| |  __/
 /_/    \_\_|_|  \__,_|_|  \___/| .__/  |_| \_|\___/ \__,_|\___|
                                | |                             
                                |_|                             
${BLUE}
               Join the Airdrop Node Now!${GREEN}
        ──────────────────────────────────────
        🚀 Telegram Group: ${UNDERLINE_YELLOW}https://t.me/airdrop_node${NC}
        ──────────────────────────────────────"
}

# Enable error handling
set -e

# Function to install Docker if not present
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker not found. Installing Docker..."
        sudo apt update
        sudo apt install -y docker.io
        sudo systemctl start docker
        sudo systemctl enable docker
        echo "Docker installed and running."
    else
        echo "Docker already installed."
    fi
}

# Function to install Docker Compose if not present
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        echo "Docker Compose not found. Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed."
    else
        echo "Docker Compose already installed."
    fi
}

# Function to install the node and generate docker-compose.yml
install_node() {
    echo "To continue, please register using the following link:"
    echo -e "${YELLOW}https://app.getgrass.io/register/?referralCode=2G4AzIQX87ObykI${NC}"
    echo -n "Have you completed the registration? (y/n): "
    read -r registered

    if [[ "$registered" != "y" && "$registered" != "Y" ]]; then
        echo "Please complete the registration and use referral code airdropnode to continue."
        return
    fi

    # Create a directory for the grass container
    mkdir -p "$HOME/grass_data"

    # Prompt for user credentials
    read -p "Enter your email: " USER_EMAIL
    read -sp "Enter your password: " USER_PASSWORD
    echo

    # Prompt for WebSocket proxy URL
    read -p "Enter WebSocket Proxy URL (leave blank if not needed): " WEBSOCKET_PROXY

    # Create the docker-compose.yml file with the user credentials and optional WebSocket proxy
    cat <<EOF > docker-compose.yml
version: "3.9"
services:
  grass-node:
    container_name: grass-node
    hostname: my_device
    image: airdropnode/grass-node
    environment:
      USER_EMAIL: ${USER_EMAIL}
      USER_PASSWORD: ${USER_PASSWORD}
EOF

    # Add WebSocket proxy to docker-compose.yml if provided
    if [[ -n "$WEBSOCKET_PROXY" ]]; then
        echo "      WEBSOCKET_PROXY: ${WEBSOCKET_PROXY}" >> docker-compose.yml
    fi

    cat <<EOF >> docker-compose.yml
    ports:
      - "5900:5900"
      - "6080:6080"
    volumes:
      - ./grass_data:/app/data
EOF

    # Run Docker Compose to start the container
    docker-compose up -d

    echo "Node installed successfully. Check the logs to confirm authentication."
}

# Function to view logs
view_logs() {
    echo "Viewing logs..."
    docker logs grass-node
    echo
}

# Function to display account details
display_account() {
    echo "Current account details:"
    echo "Email: $USER_EMAIL"
    echo "Password: $USER_PASSWORD"
    echo "WebSocket Proxy: ${WEBSOCKET_PROXY:-None}"
}

# Main menu
show_menu() {
    clear
    display_logo  # Call the function to display the logo
    echo "Please select an option:"
    echo "1.  Install Node"
    echo "2.  View Logs"
    echo "3.  View Account Details"
    echo "0.  Exit"
    echo -n "Enter your choice [0-3]: "
    read -r choice
}

# Main loop
while true; do
    install_docker
    install_docker_compose
    show_menu
    case $choice in
        1) install_node ;;
        2) view_logs ;;
        3) display_account ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid input. Please try again."; read -p "Press Enter to continue..." ;;
    esac
done
