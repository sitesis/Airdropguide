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
COLOR_GREEN="\033[1;32m"

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

# ================================
# Fungsi Instalasi dan Konfigurasi
# ================================

install_nvm() {
    echo -e "${COLOR_BLUE}\nInstalling NVM (Node Version Manager)...${COLOR_RESET}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    echo -e "${COLOR_GREEN}NVM installed successfully.${COLOR_RESET}"
    log_message "NVM installed."
}

install_node() {
    echo -e "${COLOR_BLUE}\nInstalling Node.js using NVM...${COLOR_RESET}"
    nvm install 20
    nvm use 20
    echo -e "${COLOR_GREEN}Node.js 20 installed successfully.${COLOR_RESET}"
    log_message "Node.js installed."
}

install_dependencies() {
    echo -e "${COLOR_BLUE}\nInstalling system dependencies...${COLOR_RESET}"
    log_message "Installing system dependencies..."
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu npm >/dev/null 2>&1
    echo -e "${COLOR_GREEN}System dependencies installed successfully.${COLOR_RESET}"
    log_message "System dependencies installed."
}

install_docker() {
    echo -e "${COLOR_BLUE}\nChecking Docker installation...${COLOR_RESET}"
    if ! command -v docker &> /dev/null; then
        echo -e "${COLOR_YELLOW}Docker not found. Installing Docker...${COLOR_RESET}"
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        echo -e "${COLOR_GREEN}Docker installed successfully.${COLOR_RESET}"
        log_message "Docker installed."
    else
        echo -e "${COLOR_GREEN}Docker is already installed.${COLOR_RESET}"
        log_message "Docker already installed."
    fi
}

install_docker_compose() {
    echo -e "${COLOR_BLUE}\nChecking Docker Compose installation...${COLOR_RESET}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${COLOR_YELLOW}Docker Compose not found. Installing Docker Compose...${COLOR_RESET}"
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${COLOR_GREEN}Docker Compose installed successfully.${COLOR_RESET}"
        log_message "Docker Compose installed."
    else
        echo -e "${COLOR_GREEN}Docker Compose is already installed.${COLOR_RESET}"
        log_message "Docker Compose already installed."
    fi
}

install_hyperlane_cli() {
    echo -e "${COLOR_BLUE}\nInstalling Hyperlane CLI...${COLOR_RESET}"
    if ! command -v hyperlane &> /dev/null; then
        echo -e "${COLOR_YELLOW}Hyperlane CLI not found. Installing Hyperlane CLI...${COLOR_RESET}"
        sudo npm install -g @hyperlane-xyz/cli >/dev/null 2>&1
        echo -e "${COLOR_GREEN}Hyperlane CLI installed successfully.${COLOR_RESET}"
        log_message "Hyperlane CLI installed."
    else
        echo -e "${COLOR_GREEN}Hyperlane CLI is already installed.${COLOR_RESET}"
        log_message "Hyperlane CLI already installed."
    fi
}

install_foundry() {
    echo -e "${COLOR_BLUE}\nInstalling Foundry...${COLOR_RESET}"
    curl -L https://foundry.paradigm.xyz | bash
    source /root/.bashrc
    foundryup
    echo -e "${COLOR_GREEN}Foundry installed successfully.${COLOR_RESET}"
    log_message "Foundry installed."
}

generate_evm_wallet() {
    echo -e "${COLOR_BLUE}\nCreating your EVM Wallet...${COLOR_RESET}"
    log_message "Creating EVM Wallet..."
    
    # Menghasilkan EVM Wallet tanpa menyimpan private key dalam log atau output
    cast wallet new | tee /dev/null

    # Memberikan peringatan untuk menyimpan private key secara manual
    echo -e "${COLOR_YELLOW}\nMake sure to save your EVM address and private key in a secure location!${COLOR_RESET}"
    log_message "EVM Wallet generated, private key not saved."
}

install_hyperlane_project() {
    echo -e "${COLOR_BLUE}\nPulling Hyperlane Docker image...${COLOR_RESET}"
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${COLOR_GREEN}Hyperlane Docker image pulled successfully.${COLOR_RESET}"
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
        echo -e "${COLOR_GREEN}Hyperlane database directory created successfully.${COLOR_RESET}"
        log_message "Hyperlane database directory created."
    else
        echo -e "${COLOR_RED}Failed to create Hyperlane database directory.${COLOR_RESET}"
        log_message "Failed to create Hyperlane database directory."
    fi
}

run_hyperlane_node() {
    echo -e "${COLOR_CYAN}\nPlease provide the following details:${COLOR_RESET}"

    read -p "Enter blockchain name (e.g., Base): " CHAIN
    read -p "Enter validator name: " NAME
    read -p "Enter private key: " PRIVATE_KEY
    read -p "Enter RPC URL: " RPC_CHAIN

    docker run -d \
      -it \
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
      --chains."$CHAIN".signer.key "$PRIVATE_KEY" \
      --chains."$CHAIN".customRpcUrls "$RPC_CHAIN"

    echo -e "${COLOR_GREEN}Hyperlane node is running.${COLOR_RESET}"
    log_message "Hyperlane node is running."
}

# ================================
# Instalasi dan konfigurasi
# ================================
install_nvm
install_node
install_dependencies
install_docker
install_docker_compose
install_hyperlane_cli
install_foundry
generate_evm_wallet
install_hyperlane_project
create_hyperlane_db_directory
run_hyperlane_node
