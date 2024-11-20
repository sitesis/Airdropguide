#!/bin/bash
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5
# ================================
# Hyperlane Node Installer with User Inputs
# ================================

# Warna untuk tampilan
RED='\033[0;31m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
BLUE='\033[1;34m'
WHITE='\033[1;37m'
LIGHT_CYAN='\033[1;36m'  # Warna cyan muda
LIGHT_MAGENTA='\033[1;35m'  # Warna magenta muda
NC='\033[0m' # Reset warna

# Log file path dan ukuran maksimum log
LOGFILE="$HOME/hyperlane-node.log"
MAX_LOG_SIZE=52428800  # 50MB

# Fungsi untuk log pesan ke file
log_message() {
    echo -e "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

# Rotasi file log jika ukurannya melebihi batas
rotate_log_file() {
    if [ -f "$LOGFILE" ] && [ $(stat -c%s "$LOGFILE") -ge $MAX_LOG_SIZE ]; then
        mv "$LOGFILE" "$LOGFILE.bak"
        touch "$LOGFILE"
        log_message "Log file rotated. Previous log archived as $LOGFILE.bak"
    fi
}

# Cleanup file sementara dan skrip
cleanup() {
    log_message "Cleaning up temporary files and removing script..."
    rm -f "$0"
    log_message "Cleanup completed."
}

# ================================
# Fungsi Instalasi dan Konfigurasi
# ================================

install_dependencies() {
    echo -e "\n${BLUE}Installing system dependencies...${NC}"
    log_message "Installing system dependencies..."
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu screen npm >/dev/null 2>&1
    echo -e "${LIGHT_GREEN}System dependencies installed successfully.${NC}"
    log_message "System dependencies installed."
}

install_screen() {
    echo -e "\n${BLUE}Checking screen installation...${NC}"
    if ! command -v screen &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Screen not found. Installing Screen...${NC}"
        sudo apt-get install -y screen >/dev/null 2>&1
        echo -e "${LIGHT_GREEN}Screen installed successfully.${NC}"
        log_message "Screen installed."
    else
        echo -e "${LIGHT_GREEN}Screen is already installed.${NC}"
        log_message "Screen already installed."
    fi
}

install_docker() {
    echo -e "\n${BLUE}Checking Docker installation...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Docker not found. Installing Docker...${NC}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        echo -e "${LIGHT_GREEN}Docker installed successfully.${NC}"
        log_message "Docker installed."
    else
        echo -e "${LIGHT_GREEN}Docker is already installed.${NC}"
        log_message "Docker already installed."
    fi
}

install_nodejs() {
    echo -e "\n${BLUE}Checking Node.js installation...${NC}"
    if ! command -v node &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Node.js not found. Installing Node.js...${NC}"
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs >/dev/null 2>&1
        echo -e "${LIGHT_GREEN}Node.js installed successfully.${NC}"
        log_message "Node.js installed."
    else
        echo -e "${LIGHT_GREEN}Node.js is already installed.${NC}"
        log_message "Node.js already installed."
    fi
}

install_docker_compose() {
    echo -e "\n${BLUE}Checking Docker Compose installation...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Docker Compose not found. Installing Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${LIGHT_GREEN}Docker Compose installed successfully.${NC}"
        log_message "Docker Compose installed."
    else
        echo -e "${LIGHT_GREEN}Docker Compose is already installed.${NC}"
        log_message "Docker Compose already installed."
    fi
}

install_hyperlane_cli() {
    echo -e "\n${BLUE}Installing Hyperlane CLI...${NC}"
    if ! command -v hyperlane &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Hyperlane CLI not found. Installing Hyperlane CLI...${NC}"
        sudo npm install -g @hyperlane-xyz/cli >/dev/null 2>&1
        echo -e "${LIGHT_GREEN}Hyperlane CLI installed successfully.${NC}"
        log_message "Hyperlane CLI installed."
    else
        echo -e "${LIGHT_GREEN}Hyperlane CLI is already installed.${NC}"
        log_message "Hyperlane CLI already installed."
    fi
}

install_hyperlane_project() {
    echo -e "\n${BLUE}Pulling Hyperlane Docker image...${NC}"
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${LIGHT_GREEN}Hyperlane Docker image pulled successfully.${NC}"
        log_message "Hyperlane Docker image pulled."
    else
        echo -e "${RED}Failed to pull Hyperlane Docker image.${NC}"
        log_message "Failed to pull Hyperlane Docker image."
    fi
}

create_hyperlane_db_directory() {
    echo -e "\n${BLUE}Creating Hyperlane database directory...${NC}"
    mkdir -p /root/hyperlane_db_base && chmod -R 777 /root/hyperlane_db_base
    if [ $? -eq 0 ]; then
        echo -e "${LIGHT_GREEN}Hyperlane database directory created and permissions set successfully.${NC}"
        log_message "Hyperlane database directory created and permissions set."
    else
        echo -e "${RED}Failed to create Hyperlane database directory.${NC}"
        log_message "Failed to create Hyperlane database directory."
    fi
}

run_hyperlane_node() {
    # Prompt the user for required inputs with colored prompt
    read -p "${LIGHT_CYAN}Enter the blockchain name (e.g., Base): ${NC}" CHAIN
    read -p "${LIGHT_CYAN}Enter a unique name for your validator: ${NC}" NAME
    read -p "${LIGHT_CYAN}Enter your private key: ${NC}" PRIVATE_KEY
    read -p "${LIGHT_CYAN}Enter the RPC URL for the blockchain (e.g., RPC for Base): ${NC}" RPC_CHAIN

    echo -e "\n${BLUE}Running Hyperlane node with the specified options...${NC}"

    # Start screen session to run docker in background
    screen -dmS airdropnode_hyperlane docker run -d \
      --name hyperlane \
      --mount type=bind,source=/root/hyperlane_db_"$CHAIN",target=/hyperlane_db_"$CHAIN" \
      gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
      ./validator \
      --db /hyperlane_db_"$CHAIN" \
      --originChainName "$CHAIN" \
      --reorgPeriod 1 \
      --validator.id "$NAME" \
      --checkpointSyncer.type localStorage \
      --checkpointSyncer.folder "$CHAIN" \
      --checkpointSyncer.path /hyperlane_db_"$CHAIN"/"$CHAIN"_checkpoints \
      --validator.key "$PRIVATE_KEY" \
      --chains."$CHAIN".rpcUrl "$RPC_CHAIN" \
      --hyperlane.legacyChain $CHAIN \
      --rpcPort 8080

    echo -e "${LIGHT_GREEN}Hyperlane node is running in the background with screen session.${NC}"
    log_message "Hyperlane node started in screen session."
}

telegram_channel() {
    echo -e "\n${BLUE}Join the Telegram Channel for more information: ${LIGHT_CYAN}https://t.me/airdrop_node${NC}"
}

cleanup

rotate_log_file
install_dependencies
install_screen
install_docker
install_nodejs
install_docker_compose
install_hyperlane_cli
install_hyperlane_project
create_hyperlane_db_directory
run_hyperlane_node
telegram_channel
