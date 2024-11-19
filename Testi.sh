#!/bin/bash

# ================================
# Fungsi untuk log pesan
# ================================
log_message() {
    echo "[LOG] $1" >> install_log.txt
}

# ================================
# Memeriksa Arsitektur Sistem
# ================================
check_system_architecture() {
    echo -e "\n${BLUE}Checking system architecture...${NC}"
    ARCH=$(uname -m)

    if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
        echo -e "${RED}Incompatible system architecture: $ARCH. Blockless CLI requires x86_64 or aarch64 architecture.${NC}"
        log_message "Incompatible system architecture: $ARCH."
        exit 1
    fi

    echo -e "${LIGHT_GREEN}System architecture is compatible.${NC}"
    log_message "System architecture is compatible."
}

# ================================
# Fungsi Instalasi Dependensi
# ================================
install_dependencies() {
    echo -e "\n${BLUE}Installing system dependencies...${NC}"
    log_message "Installing system dependencies..."
    sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu screen >/dev/null 2>&1
    echo -e "${LIGHT_GREEN}System dependencies installed successfully.${NC}"
    log_message "System dependencies installed."
}

# ================================
# Instalasi Docker
# ================================
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

# ================================
# Meminta Input Email dan Password
# ================================
get_email_password() {
    echo -e "\n${BLUE}Please enter your Blockless email: ${NC}"
    read -r EMAIL
    echo -e "${BLUE}Please enter your Blockless password: ${NC}"
    read -r -s PASSWORD  # -s flag to hide input
}

# ================================
# Menjalankan Blockless CLI dalam Docker
# ================================
run_blockless_cli_in_docker() {
    echo -e "\n${BLUE}Running Blockless CLI in Docker...${NC}"

    # Pastikan email dan password sudah dimasukkan
    if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
        echo -e "${RED}Email or password is missing. Please enter valid credentials.${NC}"
        exit 1
    fi

    # Jalankan Docker container dengan variabel lingkungan untuk email dan password
    docker run -it --rm \
        -e EMAIL="$EMAIL" \
        -e PASSWORD="$PASSWORD" \
        --name blockless-cli \
        blocklessnetwork/cli:latest \
        bash -c "blockless-cli --email \$EMAIL --password \$PASSWORD"

    echo -e "${LIGHT_GREEN}Blockless CLI executed successfully.${NC}"
}

# ================================
# Eksekusi Langkah-langkah
# ================================
check_system_architecture
install_dependencies
install_docker
get_email_password
run_blockless_cli_in_docker

echo -e "${LIGHT_GREEN}Installation and setup completed.${NC}"
