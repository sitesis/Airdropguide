#!/bin/bash
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5
# ================================
# Hyperlane Node Installer with User Inputs
# ================================

# Log file path dan ukuran maksimum log
LOGFILE="$HOME/hyperlane-node.log"
MAX_LOG_SIZE=52428800  # 50MB

# Kode warna
COLOR_RESET="\033[0m"
COLOR_BLUE="\033[1;34m"
COLOR_MAGENTA="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_CYAN="\033[1;36m"
COLOR_RED="\033[1;31m"

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
    echo -e "${COLOR_BLUE}\nInstalling system dependencies...${COLOR_RESET}"
    log_message "Installing system dependencies..."
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu screen npm >/dev/null 2>&1
    echo -e "${COLOR_MAGENTA}System dependencies installed successfully.${COLOR_RESET}"
    log_message "System dependencies installed."
}

install_screen() {
    echo -e "${COLOR_BLUE}\nChecking screen installation...${COLOR_RESET}"
    if ! command -v screen &> /dev/null; then
        echo -e "${COLOR_YELLOW}Screen not found. Installing Screen...${COLOR_RESET}"
        sudo apt-get install -y screen >/dev/null 2>&1
        echo -e "${COLOR_MAGENTA}Screen installed successfully.${COLOR_RESET}"
        log_message "Screen installed."
    else
        echo -e "${COLOR_MAGENTA}Screen is already installed.${COLOR_RESET}"
        log_message "Screen already installed."
    fi
}

install_docker() {
    echo -e "${COLOR_BLUE}\nChecking Docker installation...${COLOR_RESET}"
    if ! command -v docker &> /dev/null; then
        echo -e "${COLOR_YELLOW}Docker not found. Installing Docker...${COLOR_RESET}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        echo -e "${COLOR_MAGENTA}Docker installed successfully.${COLOR_RESET}"
        log_message "Docker installed."
    else
        echo -e "${COLOR_MAGENTA}Docker is already installed.${COLOR_RESET}"
        log_message "Docker already installed."
    fi
}

install_nodejs() {
    echo -e "${COLOR_BLUE}\nChecking Node.js installation...${COLOR_RESET}"
    if ! command -v node &> /dev/null; then
        echo -e "${COLOR_YELLOW}Node.js not found. Installing Node.js...${COLOR_RESET}"
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs >/dev/null 2>&1
        echo -e "${COLOR_MAGENTA}Node.js installed successfully.${COLOR_RESET}"
        log_message "Node.js installed."
    else
        echo -e "${COLOR_MAGENTA}Node.js is already installed.${COLOR_RESET}"
        log_message "Node.js already installed."
    fi
}

install_docker_compose() {
    echo -e "${COLOR_BLUE}\nChecking Docker Compose installation...${COLOR_RESET}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${COLOR_YELLOW}Docker Compose not found. Installing Docker Compose...${COLOR_RESET}"
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${COLOR_MAGENTA}Docker Compose installed successfully.${COLOR_RESET}"
        log_message "Docker Compose installed."
    else
        echo -e "${COLOR_MAGENTA}Docker Compose is already installed.${COLOR_RESET}"
        log_message "Docker Compose already installed."
    fi
}

install_hyperlane_cli() {
    echo -e "${COLOR_BLUE}\nInstalling Hyperlane CLI...${COLOR_RESET}"
    if ! command -v hyperlane &> /dev/null; then
        echo -e "${COLOR_YELLOW}Hyperlane CLI not found. Installing Hyperlane CLI...${COLOR_RESET}"
        sudo npm install -g @hyperlane-xyz/cli >/dev/null 2>&1
        echo -e "${COLOR_MAGENTA}Hyperlane CLI installed successfully.${COLOR_RESET}"
        log_message "Hyperlane CLI installed."
    else
        echo -e "${COLOR_MAGENTA}Hyperlane CLI is already installed.${COLOR_RESET}"
        log_message "Hyperlane CLI already installed."
    fi
}

install_hyperlane_project() {
    echo -e "${COLOR_BLUE}\nPulling Hyperlane Docker image...${COLOR_RESET}"
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_MAGENTA}Hyperlane Docker image pulled successfully.${COLOR_RESET}"
        log_message "Hyperlane Docker image pulled."
    else
        echo -e "${COLOR_RED}Failed to pull Hyperlane Docker image.${COLOR_RESET}"
        log_message "Failed to pull Hyperlane Docker image."
    fi
}

create_hyperlane_db_directory() {
    echo -e "${COLOR_BLUE}\nCreating Hyperlane database directory...${COLOR_RESET}"
    mkdir -p /root/hyperlane_db_base && chmod -R 777 /root/hyperlane_db_base
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_MAGENTA}Hyperlane database directory created and permissions set successfully.${COLOR_RESET}"
        log_message "Hyperlane database directory created and permissions set."
    else
        echo -e "${COLOR_RED}Failed to create Hyperlane database directory.${COLOR_RESET}"
        log_message "Failed to create Hyperlane database directory."
    fi
}

run_hyperlane_node() {
    # Prompt the user for required inputs
    echo -e "${COLOR_CYAN}\nPlease provide the following details to configure your Hyperlane Node:${COLOR_RESET}"

    read -p "Enter the blockchain name (e.g., Base): " CHAIN
    read -p "Enter a unique name for your validator: " NAME
    read -p "Enter your private key: " PRIVATE_KEY
    read -p "Enter the RPC URL for the blockchain (e.g., RPC for Base): " RPC_CHAIN

    echo -e "${COLOR_YELLOW}\nRunning Hyperlane node with the specified options...${COLOR_RESET}"

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

    echo -e "${COLOR_MAGENTA}Hyperlane node is running in the background with screen session.${COLOR_RESET}"
    log_message "Hyperlane node started in screen session."
}

check_logs() {
    echo -e "${COLOR_CYAN}\nChecking Hyperlane node logs...${COLOR_RESET}"
    screen -r airdropnode_hyperlane
}

# ================================
# Main Process
# ================================

# Install dependencies
install_dependencies
install_screen
install_docker
install_nodejs
install_docker_compose
install_hyperlane_cli
install_hyperlane_project
create_hyperlane_db_directory

# Run Hyperlane Node
run_hyperlane_node

# Log and final message
log_message "Hyperlane installation completed successfully."
echo -e "${COLOR_MAGENTA}\nInstallation completed successfully. The Hyperlane node is running.${COLOR_RESET}"

# Optionally, check logs
check_logs
