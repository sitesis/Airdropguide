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

install_dependencies() {
    echo -e "${COLOR_BLUE}\nInstalling system dependencies...${COLOR_RESET}"
    log_message "Installing system dependencies..."
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu npm >/dev/null 2>&1
    echo -e "${COLOR_GREEN}System dependencies installed successfully.${COLOR_RESET}"
    log_message "System dependencies installed."
}

install_nvm() {
    echo -e "${COLOR_BLUE}\nInstalling NVM (Node Version Manager)...${COLOR_RESET}"
    log_message "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    echo -e "${COLOR_GREEN}NVM installed successfully.${COLOR_RESET}"
    log_message "NVM installed."
}

install_node() {
    echo -e "${COLOR_BLUE}\nInstalling Node.js using NVM...${COLOR_RESET}"
    log_message "Installing Node.js..."
    nvm install 20 >/dev/null 2>&1
    nvm use 20 >/dev/null 2>&1
    echo -e "${COLOR_GREEN}Node.js 20 installed successfully.${COLOR_RESET}"
    log_message "Node.js installed."
}

install_docker() {
    echo -e "${COLOR_BLUE}\nChecking Docker installation...${COLOR_RESET}"
    if ! command -v docker &> /dev/null; then
        echo -e "${COLOR_YELLOW}Docker not found. Installing Docker...${COLOR_RESET}"
        log_message "Installing Docker..."
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

install_foundry() {
    echo -e "${COLOR_BLUE}\nInstalling Foundry...${COLOR_RESET}"
    log_message "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    source "$HOME/.foundry/env"
    export PATH="$HOME/.foundry/bin:$PATH"
    log_message "Foundry installed and PATH updated."
}

generate_evm_wallet() {
    echo -e "${COLOR_BLUE}\nCreating your EVM Wallet...${COLOR_RESET}"
    log_message "Creating EVM Wallet..."
    cast wallet new | tee /dev/null
    echo -e "${COLOR_YELLOW}\nMake sure to save your EVM address and private key in a secure location!${COLOR_RESET}"
    log_message "EVM Wallet generated."
}

run_hyperlane_node() {
    echo -e "${COLOR_CYAN}\nPlease provide the following details:${COLOR_RESET}"
    read -p "Enter blockchain name (e.g., base): " CHAIN
    read -p "Enter validator name: " NAME
    read -p "Enter private key: " PRIVATE_KEY
    read -p "Enter RPC URL: " RPC_CHAIN

    # Create directory for the Hyperlane node's database with chain-specific name
    DB_DIR="/root/hyperlane_db_$CHAIN"
    echo -e "${COLOR_BLUE}\nCreating database directory at $DB_DIR...${COLOR_RESET}"
    mkdir -p "$DB_DIR" && chmod -R 777 "$DB_DIR"
    log_message "Created database directory at $DB_DIR and set permissions."

    # Run Hyperlane Node with Docker
    log_message "Running Hyperlane Node for $CHAIN..."
    docker run -d \
      --name hyperlane \
      --mount type=bind,source="$DB_DIR",target=/hyperlane_db \
      gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
      ./validator \
      --db /hyperlane_db \
      --originChainName "$CHAIN" \
      --validator.id "$NAME" \
      --validator.key "$PRIVATE_KEY" \
      --chains."$CHAIN".customRpcUrls "$RPC_CHAIN"

    echo -e "${COLOR_GREEN}Hyperlane node is running.${COLOR_RESET}"
    log_message "Hyperlane node started."
}

# ================================
# Instalasi
# ================================
install_dependencies
install_nvm
install_node
install_docker
install_foundry
generate_evm_wallet
run_hyperlane_node

echo -e "${COLOR_BLUE}\nInstallation completed.${COLOR_RESET}"
log_message "Installation completed."

echo -e "${COLOR_MAGENTA}\nJoin Telegram channel for updates:${COLOR_RESET}"
echo -e "${COLOR_BLUE}https://t.me/airdrop_node${COLOR_RESET}"
log_message "Displayed Telegram channel link."
