#!/bin/bash

# Ritual Infernet Node Setup Script
# Ensure you have root access or use sudo to run this script.

log_file="setup.log"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logo display
show_logo() {
  echo -e "${BLUE}"
  curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
  echo -e "${NC}"
  sleep 5
}

# Log function to record actions and errors
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

# Display menu
show_menu() {
  echo -e "${BLUE}------------------------------------"
  echo -e " Ritual Infernet Node Setup Menu"
  echo -e "------------------------------------${NC}"
  echo -e "${YELLOW}1. Update Packages"
  echo -e "2. Install Build Tools"
  echo -e "3. Install Docker"
  echo -e "4. Install Docker Compose and Set Permissions"
  echo -e "5. Clone Starter Repository and Pull Container"
  echo -e "6. Configure Node Settings"
  echo -e "7. Restart Docker Containers"
  echo -e "8. Install Foundry"
  echo -e "9. Deploy Consumer Contract"
  echo -e "10. Initiate Request to Infernet Node"
  echo -e "0. Exit"
  echo -e "------------------------------------${NC}"
  echo -n "Please choose an option [0-10]: "
}

# Functions for each step
update_packages() {
  log "Updating system packages..."
  if ! sudo apt update && sudo apt upgrade -y; then
    log "Failed to update packages."
    echo -e "${RED}Failed to update packages. Check setup.log for details.${NC}"
    exit 1
  fi
  log "Packages updated successfully."
  echo -e "${GREEN}Packages updated successfully.${NC}"
}

install_build_tools() {
  log "Installing required build tools..."
  if ! sudo apt -qy install curl git jq lz4 build-essential screen; then
    log "Failed to install build tools."
    echo -e "${RED}Failed to install build tools. Check setup.log for details.${NC}"
    exit 1
  fi
  log "Build tools installed successfully."
  echo -e "${GREEN}Build tools installed successfully.${NC}"
}

install_docker() {
  log "Installing Docker..."
  # Set up the Docker repository
  if ! sudo apt-get remove docker docker-engine docker.io containerd runc; then
    log "Failed to remove old Docker versions."
    echo -e "${RED}Failed to remove old Docker versions. Check setup.log for details.${NC}"
    exit 1
  fi
  if ! sudo apt-get update; then
    log "Failed to update package list."
    echo -e "${RED}Failed to update package list. Check setup.log for details.${NC}"
    exit 1
  fi
  if ! sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release; then
    log "Failed to install prerequisites for Docker."
    echo -e "${RED}Failed to install prerequisites for Docker. Check setup.log for details.${NC}"
    exit 1
  fi
  if ! curl -fsSL https://download.docker.com/linux/$(lsb_release -si | tr '[:upper:]' '[:lower:]')/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
    log "Failed to add Docker GPG key."
    echo -e "${RED}Failed to add Docker GPG key. Check setup.log for details.${NC}"
    exit 1
  fi
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -si | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  
  if ! sudo apt-get update; then
    log "Failed to update package list after adding Docker repository."
    echo -e "${RED}Failed to update package list after adding Docker repository. Check setup.log for details.${NC}"
    exit 1
  fi
  if ! sudo apt-get install docker-ce docker-ce-cli containerd.io -y; then
    log "Docker installation failed!"
    echo -e "${RED}Docker installation failed. Check setup.log for details.${NC}"
    exit 1
  fi
  log "Docker installed successfully."
  echo -e "${GREEN}Docker installed successfully.${NC}"
}

install_docker_compose() {
  log "Installing Docker Compose..."
  if ! sudo curl -L "https://github.com/docker/compose/releases/download/v2.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
    log "Failed to download Docker Compose."
    echo -e "${RED}Failed to download Docker Compose. Check setup.log for details.${NC}"
    exit 1
  fi
  sudo chmod +x /usr/local/bin/docker-compose

  log "Installing Docker CLI plugin..."
  DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
  mkdir -p $DOCKER_CONFIG/cli-plugins
  if ! curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose; then
    log "Failed to download Docker CLI plugin."
    echo -e "${RED}Failed to download Docker CLI plugin. Check setup.log for details.${NC}"
    exit 1
  fi
  chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

  log "Verifying Docker Compose installation..."
  if ! docker compose version; then
    log "Docker Compose installation verification failed."
    echo -e "${RED}Docker Compose installation verification failed. Check setup.log for details.${NC}"
    exit 1
  fi

  log "Adding user to Docker group (if non-root)..."
  if ! sudo usermod -aG docker $USER; then
    log "Failed to add user to Docker group."
    echo -e "${RED}Failed to add user to Docker group. Check setup.log for details.${NC}"
    exit 1
  fi
  log "User added to Docker group successfully. Please log out and log back in for changes to take effect."
  echo -e "${GREEN}User added to Docker group successfully. Please log out and log back in for changes to take effect.${NC}"
}

clone_repository_and_pull_container() {
  if [ ! -d "infernet-container-starter" ]; then
    log "Cloning Ritual Infernet starter repository..."
    if ! git clone https://github.com/ritual-net/infernet-container-starter; then
      log "Failed to clone the repository."
      echo -e "${RED}Failed to clone the repository. Check setup.log for details.${NC}"
      exit 1
    fi
  else
    log "Repository already exists. Pulling latest changes..."
    cd infernet-container-starter && git pull || { log "Failed to pull the latest changes."; echo -e "${RED}Failed to pull the latest changes. Check setup.log for details.${NC}"; exit 1; }
  fi
  cd infernet-container-starter || exit

  log "Setting up screen session and pulling hello-world container..."
  screen -S ritual -d -m bash -c "docker pull ritualnetwork/hello-world-infernet:latest; exec bash"
  screen -r ritual -X stuff "project=hello-world make deploy-container\n"
  log "Container setup initiated."
  echo -e "${GREEN}Container setup initiated.${NC}"
}

configure_node_settings() {
  echo -e "${YELLOW}Please enter your private key for node configuration:${NC}"
  read -s PRIVATE_KEY
  if [[ -z "$PRIVATE_KEY" ]]; then
    echo -e "${RED}Private key cannot be empty.${NC}"
    return
  fi

  CONFIG_PATH=~/infernet-container-starter/deploy/config.json
  HELLO_WORLD_CONFIG=~/infernet-container-starter/projects/hello-world/container/config.json

  log "Configuring node settings in config.json..."
  sed -i 's|"rpc_url":.*|"rpc_url": "https://mainnet.base.org/",|' "$CONFIG_PATH"
  sed -i "s|\"private_key\":.*|\"private_key\": \"$PRIVATE_KEY\",|" "$CONFIG_PATH"
  sed -i 's|"registry":.*|"registry": "0xe2F36C4E23D67F81fE0B278E80ee85Cf0ccA3c8d",|' "$CONFIG_PATH"
  sed -i 's|"trail_head_blocks":.*|"trail_head_blocks": 3,|' "$CONFIG_PATH"

  sed -i 's|"rpc_url":.*|"rpc_url": "https://mainnet.base.org/",|' "$HELLO_WORLD_CONFIG"
  sed -i "s|\"private_key\":.*|\"private_key\": \"$PRIVATE_KEY\",|" "$HELLO_WORLD_CONFIG"
  sed -i 's|"registry":.*|"registry": "0xe2F36C4E23D67F81fE0B278E80ee85Cf0ccA3c8d",|' "$HELLO_WORLD_CONFIG"
  sed -i 's|"trail_head_blocks":.*|"trail_head_blocks": 3,|' "$HELLO_WORLD_CONFIG"

  log "Node settings configured successfully."
  echo -e "${GREEN}Node settings configured successfully.${NC}"
}

restart_docker_containers() {
  log "Restarting Docker containers..."
  if ! docker-compose restart; then
    log "Failed to restart Docker containers."
    echo -e "${RED}Failed to restart Docker containers. Check setup.log for details.${NC}"
    exit 1
  fi
  log "Docker containers restarted successfully."
  echo -e "${GREEN}Docker containers restarted successfully.${NC}"
}

install_foundry() {
  log "Installing Foundry..."
  if ! curl -L https://foundry.paradigm.xyz | bash; then
    log "Failed to install Foundry."
    echo -e "${RED}Failed to install Foundry. Check setup.log for details.${NC}"
    exit 1
  fi
  log "Foundry installed successfully."
  echo -e "${GREEN}Foundry installed successfully.${NC}"
}

deploy_consumer_contract() {
  log "Deploying consumer contract..."
  cd ~/infernet-container-starter/projects/hello-world || exit
  if ! forge create src/Consumer.sol:Consumer --constructor-args "0xYourAddress" --private-key "$PRIVATE_KEY"; then
    log "Failed to deploy consumer contract."
    echo -e "${RED}Failed to deploy consumer contract. Check setup.log for details.${NC}"
    exit 1
  fi
  log "Consumer contract deployed successfully."
  echo -e "${GREEN}Consumer contract deployed successfully.${NC}"
}

initiate_request_to_infernet_node() {
  log "Initiating request to Infernet Node..."
  cd ~/infernet-container-starter/projects/hello-world || exit
  if ! curl -X POST http://localhost:8080/infernet/hello; then
    log "Failed to initiate request to Infernet Node."
    echo -e "${RED}Failed to initiate request to Infernet Node. Check setup.log for details.${NC}"
    exit 1
  fi
  log "Request to Infernet Node initiated successfully."
  echo -e "${GREEN}Request to Infernet Node initiated successfully.${NC}"
}

# Main script execution
show_logo

while true; do
  show_menu
  read -r option
  case $option in
    1) update_packages ;;
    2) install_build_tools ;;
    3) install_docker ;;
    4) install_docker_compose ;;
    5) clone_repository_and_pull_container ;;
    6) configure_node_settings ;;
    7) restart_docker_containers ;;
    8) install_foundry ;;
    9) deploy_consumer_contract ;;
    10) initiate_request_to_infernet_node ;;
    0) echo -e "${GREEN}Exiting...${NC}"; exit ;;
    *) echo -e "${RED}Invalid option. Please try again.${NC}" ;;
  esac
done
