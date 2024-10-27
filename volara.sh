#!/bin/bash

# Function to update and upgrade the system
update_system() {
  sudo apt update -y && sudo apt upgrade -y
}

# Function to remove any existing Docker-related packages
remove_old_docker() {
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg
  done
}

# Function to install prerequisites for Docker
install_prerequisites() {
  sudo apt-get install -y ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
}

# Function to add Docker's official GPG key and set up the repository
setup_docker_repo() {
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
}

# Function to install Docker
install_docker() {
  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

# Function to check Docker version
check_docker_version() {
  docker --version
}

# Function to pull and run Docker container with VANA_PRIVATE_KEY
run_volara_miner() {
  local VANA_PRIVATE_KEY="$1"
  docker pull volara/miner
  docker run -it -e VANA_PRIVATE_KEY="${VANA_PRIVATE_KEY}" volara/miner
}

# Main script execution
echo "Enter your VANA_PRIVATE_KEY:"
read -s VANA_PRIVATE_KEY

screen -S volara -dm bash -c "
  $(declare -f update_system remove_old_docker install_prerequisites setup_docker_repo install_docker check_docker_version run_volara_miner)
  update_system;
  remove_old_docker;
  install_prerequisites;
  setup_docker_repo;
  install_docker;
  check_docker_version;
  run_volara_miner '${VANA_PRIVATE_KEY}';
  exec bash
"
