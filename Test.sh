#!/bin/bash

# Logfile
LOGFILE="$HOME/celestia-node.log"
MAX_LOG_SIZE=52428800  # 50MB

log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Rotate log file if it exceeds 50MB
rotate_log_file() {
    if [ -f "$LOGFILE" ] && [ $(stat -c%s "$LOGFILE") -ge $MAX_LOG_SIZE ]; then
        mv "$LOGFILE" "$LOGFILE.bak"
        touch "$LOGFILE"
        log_message "Log file rotated. Previous log archived as $LOGFILE.bak"
    fi
}

# Cleanup
cleanup() {
    log_message "Cleaning up temporary files and removing script..."
    rm -f "$0"  # Remove the script itself
    log_message "Cleanup completed."
}

# Github Version API
VERSION=$(curl -s "https://api.github.com/repos/celestiaorg/celestia-node/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

# Check if VERSION is empty
if [ -z "$VERSION" ]; then
    echo "Failed to fetch the latest version. Exiting."
    log_message "Failed to fetch the latest version."
    cleanup
    exit 1
fi

log_message "Fetched latest version: $VERSION"

# Check if Light Node is already installed
check_existing_installation() {
    if [ -d "$HOME/airdropnode_tia" ] || [ ! -z "$(sudo docker ps -q --filter ancestor=ghcr.io/celestiaorg/celestia-node:$VERSION)" ]; then
        echo "Celestia Light Node is already installed. Aborting installation."
        log_message "Celestia Light Node is already installed. Installation aborted."
        cleanup
        exit 0
    fi
}

# Install dependencies
install_dependencies() {
    log_message "Installing system updates and dependencies..."
    echo "Installing System Updates and Dependencies... (This may take a few minutes)"
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu screen >/dev/null 2>&1
    echo "System Updates and Dependencies installed successfully."
    log_message "System updates and dependencies installed successfully."
}

# Install Docker
install_docker() {
    log_message "Checking for Docker installation..."
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        sudo docker run hello-world >/dev/null 2>&1
        echo "Docker installed successfully."
        log_message "Docker installed successfully."
    else
        echo "Docker is already installed."
        log_message "Docker is already installed."
    fi
}

# Install Node.js
install_nodejs() {
    log_message "Checking for Node.js installation..."
    if ! command -v node &> /dev/null; then
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs >/dev/null 2>&1
        echo "Node.js installed successfully."
        log_message "Node.js installed successfully."
    else
        echo "Node.js is already installed."
        log_message "Node.js is already installed."
    fi
}

# Install Docker Compose
install_docker_compose() {
    log_message "Checking for Docker Compose installation..."
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose installed successfully."
        log_message "Docker Compose installed successfully."
    else
        echo "Docker Compose is already installed."
        log_message "Docker Compose is already installed."
    fi
}

# Set up Celestia Light Node
log_message "Setting up Celestia Light Node..."
export NETWORK=celestia
export NODE_TYPE=light
export RPC_URL=http://public-celestia-consensus.numia.xyz

cd $HOME
mkdir -p airdropnode_tia
sudo chown 10001:10001 $HOME/airdropnode_tia

OUTPUT=$(sudo docker run -e NODE_TYPE=$NODE_TYPE -e P2P_NETWORK=$NETWORK \
    -v $HOME/airdropnode_tia:/home/celestia \
    ghcr.io/celestiaorg/celestia-node:$VERSION \
    celestia light init --p2p.network $NETWORK)

echo "Please save your wallet information and mnemonics securely."
echo "NAME and ADDRESS:"
echo "$(echo "$OUTPUT" | grep -E 'NAME|ADDRESS')"
echo "MNEMONIC (save this somewhere safe!!!):"
echo "$(echo "$OUTPUT" | sed -n '/MNEMONIC (save this somewhere safe!!!):/,$p' | tail -n +2)"
echo "This information will not be saved automatically. Make sure to record it manually."

log_message "Celestia Light Node initialized."

# Confirm wallet information saved
while true; do
    read -p "Did you save your wallet information and mnemonics? (yes/no): " yn
    case $yn in
        [Yy]*)
            log_message "User confirmed wallet information saved."
            break
            ;;
        [Nn]*)
            echo "Please save your wallet information and mnemonics before continuing."
            ;;
        *)
            echo "Please answer yes or no."
            ;;
    esac
done

start_celestia_node() {
    log_message "Starting Celestia Light Node..."
    screen -S celestia-node -dm bash -c "sudo docker run -e NODE_TYPE=$NODE_TYPE -e P2P_NETWORK=$NETWORK \
        -v $HOME/airdropnode_tia:/home/celestia \
        ghcr.io/celestiaorg/celestia-node:$VERSION \
        celestia light start --core.ip $RPC_URL --p2p.network $NETWORK"

    echo "Celestia Light Node started successfully."
    echo "To view the logs, use: screen -r celestia-node"
    echo "To detach from screen, press Ctrl+A, then D."

    log_message "Celestia Light Node started successfully."
}

# Execute installation functions
install_dependencies
install_docker
install_nodejs
install_docker_compose
check_existing_installation

# Start node after installation
start_celestia_node
