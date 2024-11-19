#!/bin/bash

# Define colors and styles
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"
BOLD="\033[1m"
ITALIC="\033[3m"

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
    if [ -d "$HOME/my-node-store" ] || [ ! -z "$(sudo docker ps -q --filter ancestor=ghcr.io/celestiaorg/celestia-node:$VERSION)" ]; then
        echo -e "${GREEN}Celestia Light Node is already installed. Aborting installation.${NORMAL}"
        log_message "Celestia Light Node is already installed. Installation aborted."
        cleanup
        exit 0
    fi
}

# Install dependencies
install_dependencies() {
    log_message "Installing system updates and dependencies..."
    echo -e "${YELLOW}Installing System Updates and Dependencies...${NORMAL} (This may take a few minutes)"
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu screen >/dev/null 2>&1
    echo -e "${GREEN}System Updates and Dependencies installed successfully.${NORMAL}"
    log_message "System updates and dependencies installed successfully."
}

# Install Docker
install_docker() {
    log_message "Checking for Docker installation..."
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Installing Docker...${NORMAL}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        sudo docker run hello-world >/dev/null 2>&1
        echo -e "${GREEN}Docker installed successfully.${NORMAL}"
        log_message "Docker installed successfully."
    else
        echo -e "${GREEN}Docker is already installed.${NORMAL}"
        log_message "Docker is already installed."
    fi
}

# Install Node.js
install_nodejs() {
    log_message "Checking for Node.js installation..."
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}Installing Node.js...${NORMAL}"
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs >/dev/null 2>&1
        echo -e "${GREEN}Node.js installed successfully.${NORMAL}"
        log_message "Node.js installed successfully."
    else
        echo -e "${GREEN}Node.js is already installed.${NORMAL}"
        log_message "Node.js is already installed."
    fi
}

# Install Docker Compose
install_docker_compose() {
    log_message "Checking for Docker Compose installation..."
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${YELLOW}Installing Docker Compose...${NORMAL}"
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${GREEN}Docker Compose installed successfully.${NORMAL}"
        log_message "Docker Compose installed successfully."
    else
        echo -e "${GREEN}Docker Compose is already installed.${NORMAL}"
        log_message "Docker Compose is already installed."
    fi
}

# Setting up Celestia Light Node
log_message "Setting up Celestia Light Node..."
if [ "$lang" == "EN" ];then
    echo -e "${YELLOW}Setting up Celestia Light Node...${NORMAL}"
fi
export NETWORK=celestia
export NODE_TYPE=light
export RPC_URL=http://public-celestia-consensus.numia.xyz

cd $HOME
mkdir -p my-node-store
sudo chown 10001:10001 $HOME/my-node-store

if [ "$lang" == "EN" ];then
    echo -e "${YELLOW}Initializing Celestia Light Node...${NORMAL}"
fi
OUTPUT=$(sudo docker run -e NODE_TYPE=$NODE_TYPE -e P2P_NETWORK=$NETWORK \
    -v $HOME/my-node-store:/home/celestia \
    ghcr.io/celestiaorg/celestia-node:$VERSION \
    celestia light init --p2p.network $NETWORK)

if [ "$lang" == "EN" ];then
    echo -e "${RED}Please save your wallet information and mnemonics securely.${NORMAL}"
    echo -e "${RED}NAME and ADDRESS:${NORMAL}"
    echo -e "${NORMAL}$(echo "$OUTPUT" | grep -E 'NAME|ADDRESS')${NORMAL}"
    echo -e "${RED}MNEMONIC (save this somewhere safe!!!):${NORMAL}"
    echo -e "${NORMAL}$(echo "$OUTPUT" | sed -n '/MNEMONIC (save this somewhere safe!!!):/,$p' | tail -n +2)${NORMAL}"
    echo -e "${RED}This information will not be saved automatically. Make sure to record it manually.${NORMAL}"
fi

log_message "Celestia Light Node initialized."

while true; do
    if [ "$lang" == "EN" ];then
        read -p "Did you save your wallet information and mnemonics? (yes/no): " yn
    fi
    case $yn in
        [Yy]* | [Ee]*)
            log_message "User confirmed that wallet information and mnemonics were saved."
            break
            ;;
        [Nn]*)
            if [ "$lang" == "EN" ];then
                echo -e "${RED}Please save your wallet information and mnemonics before continuing.${NORMAL}"
            fi
            ;;
        *)
            if [ "$lang" == "EN" ];then
                echo "Please answer yes or no."
            fi
            ;;
    esac
done
start_celestia_node() {
    log_message "Starting Celestia Light Node..."
    if [ "$lang" == "EN" ]; then
        echo -e "${YELLOW}Starting Celestia Light Node...${NORMAL}"
    fi

    # Start Celestia Node using Docker with necessary environment variables
    screen -S celestia-node -dm bash -c "sudo docker run -e NODE_TYPE=$NODE_TYPE -e P2P_NETWORK=$NETWORK \
        -v $HOME/my-node-store:/home/celestia \
        ghcr.io/celestiaorg/celestia-node:$VERSION \
        celestia light start --core.ip $RPC_URL --p2p.network $NETWORK"

    # User feedback
    if [ "$lang" == "EN" ]; then
        echo -e "${GREEN}Celestia Light Node started successfully.${NORMAL}"
        echo -e "${YELLOW}To view the logs, use: screen -r celestia-node${NORMAL}"
        echo -e "${YELLOW}To detach from screen, press Ctrl+A, then D.${NORMAL}"
    fi

    log_message "Celestia Light Node started successfully."
}



# Execute installation functions
install_dependencies
install_docker
install_nodejs
install_docker_compose
check_existing_installation
