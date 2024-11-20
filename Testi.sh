#!/bin/bash

# Define colors for output
BLUE='\033[1;34m'
LIGHT_GREEN='\033[1;32m'
LIGHT_YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

# Nama chain yang sudah ditentukan (menggunakan "base")
CHAIN_NAME="base"

# Log function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> installation.log
}

install_dependencies() {
    echo -e "\n${BLUE}Installing system dependencies...${NC}"
    log_message "Installing system dependencies..."
    sudo apt-get update -y >/dev/null 2>&1
    sudo apt-get install -y curl tar wget aria2 clang pkg-config libssl-dev jq build-essential git make ncdu screen \
    >/dev/null 2>&1 || { 
        echo -e "${RED}Failed to install dependencies.${NC}"; 
        log_message "Failed to install system dependencies."; 
        exit 1; 
    }
    echo -e "${LIGHT_GREEN}System dependencies installed successfully.${NC}"
    log_message "System dependencies installed."
}

install_docker() {
    echo -e "\n${BLUE}Checking Docker installation...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Docker not found. Installing Docker...${NC}"
        sudo apt-get update -y >/dev/null 2>&1
        sudo apt-get install -y ca-certificates curl gnupg >/dev/null 2>&1
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt-get update -y >/dev/null 2>&1
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1 || { 
            echo -e "${RED}Failed to install Docker.${NC}"; 
            log_message "Failed to install Docker."; 
            exit 1; 
        }
        echo -e "${LIGHT_GREEN}Docker installed successfully.${NC}"
        log_message "Docker installed."
    else
        echo -e "${LIGHT_GREEN}Docker is already installed.${NC}"
        log_message "Docker already installed."
    fi
}

install_docker_compose() {
    echo -e "\n${BLUE}Checking Docker Compose installation...${NC}"
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${LIGHT_YELLOW}Docker Compose not found. Installing Docker Compose...${NC}"
        curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose >/dev/null 2>&1 || { 
            echo -e "${RED}Failed to install Docker Compose.${NC}"; 
            log_message "Failed to install Docker Compose."; 
            exit 1; 
        }
        sudo chmod +x /usr/local/bin/docker-compose || { 
            echo -e "${RED}Failed to set execute permissions for Docker Compose.${NC}"; 
            log_message "Failed to set execute permissions for Docker Compose."; 
            exit 1; 
        }
        echo -e "${LIGHT_GREEN}Docker Compose installed successfully.${NC}"
        log_message "Docker Compose installed."
    else
        echo -e "${LIGHT_GREEN}Docker Compose is already installed.${NC}"
        log_message "Docker Compose already installed."
    fi
}

install_nvm_and_node() {
    echo -e "\n${BLUE}Installing NVM and Node.js...${NC}"
    log_message "Installing NVM and Node.js..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash >/dev/null 2>&1
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install 20 >/dev/null 2>&1 || { 
        echo -e "${RED}Failed to install Node.js.${NC}"; 
        log_message "Failed to install Node.js."; 
        exit 1; 
    }
    echo -e "${LIGHT_GREEN}NVM and Node.js installed successfully.${NC}"
    log_message "NVM and Node.js installed."
}

install_foundry() {
    echo -e "\n${BLUE}Installing Foundry...${NC}"
    log_message "Installing Foundry..."
    curl -L https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh | bash >/dev/null 2>&1 || { 
        echo -e "${RED}Failed to install Foundry.${NC}"; 
        log_message "Failed to install Foundry."; 
        exit 1; 
    }
    echo -e "${LIGHT_GREEN}Foundry installed successfully.${NC}"
    log_message "Foundry installed."
}

create_evm_wallet() {
    echo -e "\n${BLUE}Creating a new EVM wallet...${NC}"
    log_message "Creating a new EVM wallet..."
    foundryup
    export PATH="$HOME/.foundry/bin:$PATH"
    if ! command -v cast &> /dev/null; then
        echo -e "${RED}Cast is not installed. Please check Foundry installation.${NC}"
        log_message "Cast command not found."
        exit 1
    fi
    echo -e "${LIGHT_GREEN}Generating EVM wallet. Please save the credentials securely!${NC}"
    echo -e "${LIGHT_YELLOW}Foundry will generate an EVM address and a private key.${NC}"
    echo -e "${LIGHT_YELLOW}Make sure to save these credentials in a secure location!${NC}"
    cast wallet new || { 
        echo -e "${RED}Failed to create EVM wallet.${NC}"; 
        log_message "Failed to create EVM wallet."; 
        exit 1; 
    }
    echo -e "${LIGHT_GREEN}EVM wallet created successfully.${NC}"
    log_message "EVM wallet created."
}

install_hyperlane_client() {
    echo -e "\n${BLUE}Installing Hyperlane client...${NC}"
    log_message "Installing Hyperlane client..."
    npm install -g @hyperlane-xyz/cli >/dev/null 2>&1 || { 
        echo -e "${RED}Failed to install Hyperlane client.${NC}"; 
        log_message "Failed to install Hyperlane client."; 
        exit 1; 
    }
    echo -e "${LIGHT_GREEN}Hyperlane client installed successfully.${NC}"
    log_message "Hyperlane client installed."
}

install_hyperlane_project() {
    echo -e "\n${BLUE}Installing the Hyperlane project from the GitHub repository...${NC}"
    log_message "Installing Hyperlane project from GitHub repository..."
    
    docker pull --platform linux/amd64 gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 >/dev/null 2>&1 || { 
        echo -e "${RED}Failed to pull the Hyperlane Docker image.${NC}"; 
        log_message "Failed to pull Hyperlane Docker image."; 
        exit 1; 
    }

    echo -e "${LIGHT_GREEN}Hyperlane project installed successfully from GitHub repository.${NC}"
    log_message "Hyperlane project installed."
}

create_hyperlane_db_directory() {
    echo -e "\n${BLUE}Creating the directory to store the node's database...${NC}"
    log_message "Creating the directory for Hyperlane node's database..."
    
    mkdir -p /root/hyperlane_db_base && chmod -R 777 /root/hyperlane_db_base >/dev/null 2>&1 || { 
        echo -e "${RED}Failed to create Hyperlane database directory.${NC}"; 
        log_message "Failed to create Hyperlane database directory."; 
        exit 1; 
    }

    echo -e "${LIGHT_GREEN}Hyperlane database directory created successfully.${NC}"
    log_message "Hyperlane database directory created."
}

# Menjalankan Docker container dengan parameter yang diinputkan
run_hyperlane_container() {
    echo -e "\n${BLUE}Running Hyperlane Docker container with provided parameters...${NC}"
    log_message "Running Hyperlane Docker container..."
    
    docker run -d \
      -it \
      --name hyperlane \
      --mount type=bind,source=/root/hyperlane_db_$CHAIN_NAME,target=/hyperlane_db_$CHAIN_NAME \
      gcr.io/abacus-labs-dev/hyperlane-agent:agents-v1.0.0 \
      ./validator \
      --db /hyperlane_db_$CHAIN_NAME \
      --originChainName $CHAIN_NAME \
      --reorgPeriod 1 \
      --validator.id $VALIDATOR_NAME \
      --checkpointSyncer.type localStorage \
      --checkpointSyncer.folder $CHAIN_NAME \
      --checkpointSyncer.path /hyperlane_db_$CHAIN_NAME/$CHAIN_NAME_checkpoints \
      --validator.key $PRIVATE_KEY \
      --chains.$CHAIN_NAME.signer.key $PRIVATE_KEY \
      --chains.$CHAIN_NAME.customRpcUrls $RPC_URL

    echo -e "${LIGHT_GREEN}Hyperlane Docker container started successfully.${NC}"
    log_message "Hyperlane Docker container started."

    # Invite to join Telegram channel
    echo -e "\n${LIGHT_YELLOW}Join our Telegram channel for updates and support: ${NC}https://t.me/airdrop_node"
    log_message "User invited to join Telegram channel."
}

# Get inputs from user at the end
echo -e "\n${LIGHT_YELLOW}Please provide the following configuration details:${NC}"

read -p "Enter your RPC URL: " RPC_URL
read -p "Enter your private key: " PRIVATE_KEY
read -p "Enter your validator name: " VALIDATOR_NAME

# Proceed with installations and configurations
install_dependencies
install_docker
install_docker_compose
install_nvm_and_node
install_foundry
create_evm_wallet
install_hyperlane_client
install_hyperlane_project
create_hyperlane_db_directory
run_hyperlane_container
