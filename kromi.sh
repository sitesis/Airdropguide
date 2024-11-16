#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 3

# Function to display styled messages
show() {
  echo -e "\n\033[1;35m$1\033[0m\n"
}

# Function to display a loading animation
loading() {
  message=$1
  duration=$2
  echo -ne "\033[1;34m$message\033[0m"
  for ((i = 0; i < duration; i++)); do
    echo -ne "."
    sleep 0.3
  done
  echo -e "\n"
}

# Check if curl is installed
if ! [ -x "$(command -v curl)" ]; then
  show "curl is not installed. Please install curl to proceed."
  exit 1
else
  loading "Checking curl installation" 3
  show "✅ curl is installed."
fi

# Fetch public IP
loading "Fetching your public IP" 2
IP=$(curl -s ifconfig.me)
USERNAME=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()_+' | head -c 5; echo)
PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()_+' | head -c 10; echo)
CREDENTIALS_FILE="$HOME/airdropnode-browser-credentials.json"

# Create credentials file
loading "Generating credentials file" 2
cat <<EOL > "$CREDENTIALS_FILE"
{
  "username": "$USERNAME",
  "password": "$PASSWORD"
}
EOL
show "✅ Credentials saved in: $CREDENTIALS_FILE"

# Check if Docker is installed
if ! [ -x "$(command -v docker)" ]; then
  show "Docker is not installed. Installing Docker..."
  loading "Downloading and installing Docker" 5
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  if [ -x "$(command -v docker)" ]; then
    show "✅ Docker installation successful."
  else
    show "❌ Docker installation failed. Exiting."
    exit 1
  fi
else
  loading "Checking Docker installation" 2
  show "✅ Docker is installed."
fi

# Pull Chromium Docker image
loading "Downloading the latest Chromium Docker image" 4
if ! sudo docker pull linuxserver/chromium:latest; then
  show "❌ Failed to download the Chromium Docker image. Exiting."
  exit 1
else
  show "✅ Chromium Docker image downloaded successfully."
fi

# Create configuration directory
loading "Setting up Chromium configuration directory" 2
mkdir -p "$HOME/chromium/config"

# Start Docker container
if [ "$(docker ps -q -f name=browser)" ]; then
  show "✅ Chromium Docker container is already running."
else
  loading "Starting Chromium Docker container" 4
  sudo docker run -d --name browser \
    -e TITLE=AirdropNode \
    -e DISPLAY=:1 \
    -e PUID=1000 \
    -e PGID=1000 \
    -e CUSTOM_USER="$USERNAME" \
    -e PASSWORD="$PASSWORD" \
    -e LANGUAGE=en_US.UTF-8 \
    -v "$HOME/chromium/config:/config" \
    -p 3000:3000 -p 3001:3001 \
    --shm-size="1gb" --restart unless-stopped \
    lscr.io/linuxserver/chromium:latest
  
  if [ $? -eq 0 ]; then
    show "✅ Chromium Docker container started successfully."
  else
    show "❌ Failed to start the Chromium Docker container."
    exit 1
  fi
fi

# Display access information
loading "Setting up external access for the browser" 3
show "🌐 Access the external browser at:
  - http://$IP:3000/
  - https://$IP:3001/

📝 Use the following credentials:
  - Username: \033[1;32m$USERNAME\033[0m
  - Password: \033[1;32m$PASSWORD\033[0m

📁 Credentials are also saved in:
  $CREDENTIALS_FILE"
