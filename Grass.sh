#!/bin/bash

# Load logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if user is root
if [ "$(id -u)" != "0" ]; then
    echo -e "${RED}This script requires root privileges. Please run as root or use 'sudo'.${NC}"
    exit 1
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker is already installed. Skipping Docker installation.${NC}"
    docker --version
else
    # Update and install required dependencies
    echo -e "${GREEN}Updating system and installing dependencies...${NC}"
    if ! apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release; then
        echo -e "${RED}Failed to update and install dependencies.${NC}"
        exit 1
    fi

    # Add Docker’s official GPG key
    echo -e "${GREEN}Adding Docker's official GPG key...${NC}"
    mkdir -p /etc/apt/keyrings
    if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
        echo -e "${RED}Failed to add Docker's GPG key.${NC}"
        exit 1
    fi

    # Set up the Docker repository
    echo -e "${GREEN}Adding Docker repository...${NC}"
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine and components
    echo -e "${GREEN}Installing Docker Engine...${NC}"
    if ! apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io; then
        echo -e "${RED}Failed to install Docker Engine.${NC}"
        exit 1
    fi

    # Verify Docker installation
    echo -e "${GREEN}Verifying Docker installation...${NC}"
    if docker --version; then
        echo -e "${GREEN}Docker successfully installed!${NC}"
    else
        echo -e "${RED}Error occurred during Docker installation.${NC}"
        exit 1
    fi
fi

# Check if Docker Compose is already installed
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}Docker Compose is already installed. Skipping Docker Compose installation.${NC}"
    docker-compose --version
else
    # Install Docker Compose
    echo -e "${GREEN}Installing Docker Compose...${NC}"
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    # Make Docker Compose executable
    chmod +x /usr/local/bin/docker-compose
    
    # Verify Docker Compose installation
    echo -e "${GREEN}Verifying Docker Compose installation...${NC}"
    if docker-compose --version; then
        echo -e "${GREEN}Docker Compose successfully installed!${NC}"
    else
        echo -e "${RED}Error occurred during Docker Compose installation.${NC}"
        exit 1
    fi
fi

# Clone the repository if it doesn't already exist
if [ ! -d "grass" ]; then
    echo -e "${GREEN}Cloning the grass repository...${NC}"
    git clone https://github.com/MsLolita/grass.git
else
    echo -e "${GREEN}The grass repository already exists. Skipping clone.${NC}"
fi

# Navigate to the grass/data directory
echo -e "${GREEN}Navigating to the grass/data directory...${NC}"
cd grass/data || { echo -e "${RED}Failed to navigate to the grass/data directory.${NC}"; exit 1; }

# Prompt for email and password
echo -e "${GREEN}Please enter your email:${NC}"
read -r email
echo -e "${GREEN}Please enter your password:${NC}"
read -sr password  # -s hides the input for security

# Save the email and password to accounts.txt
echo -e "${GREEN}Updating accounts.txt with the provided email and password...${NC}"
echo "email=$email" > ./accounts.txt
echo "password=$password" >> ./accounts.txt
echo -e "${GREEN}accounts.txt has been updated successfully!${NC}"

# Prompt for multiple proxies
echo -e "${GREEN}Please enter your proxies (one per line). Type 'done' when you are finished:${NC}"
> ./proxies.txt  # Clear proxies.txt before adding new entries
while true; do
    read -r proxy
    if [[ $proxy == "done" ]]; then
        break
    fi
    echo "$proxy" >> ./proxies.txt
done

echo -e "${GREEN}proxies.txt has been updated successfully with the provided proxies!${NC}"

# Modify config.py
CONFIG_FILE_PATH="../config.py"  # Adjust path if necessary
echo -e "${GREEN}Modifying config.py...${NC}"
{
    echo "THREADS = 5  # for register account / claim rewards mode / approve email mode"
    echo "MIN_PROXY_SCORE = 50  # Put MIN_PROXY_SCORE = 0 not to check proxy score (if site is down)"
    echo
    echo "#########################################"
    echo "APPROVE_EMAIL = False  # approve email (NEEDED IMAP AND ACCESS TO EMAIL)"
    echo "CONNECT_WALLET = False  # connect wallet (put private keys in wallets.txt)"
    echo "SEND_WALLET_APPROVE_LINK_TO_EMAIL = False  # send approve link to email"
    echo "APPROVE_WALLET_ON_EMAIL = False  # get approve link from email (NEEDED IMAP AND ACCESS TO EMAIL)"
    echo "SEMI_AUTOMATIC_APPROVE_LINK = False # if True - allow to manual paste approve link from email to cli"
    echo "# If you have possibility to forward all approve mails to single IMAP address:"
    echo "SINGLE_IMAP_ACCOUNT = False # usage \"name@domain.com:password\""
    echo
    echo "# skip for auto chosen"
    echo "EMAIL_FOLDER = \"\"  # folder where mails comes"
    echo "IMAP_DOMAIN = \"\"  # not always works"
    echo
    echo "#########################################"
    echo "CLAIM_REWARDS_ONLY = False  # claim tiers rewards only (https://app.getgrass.io/dashboard/referral-program)"
    echo "STOP_ACCOUNTS_WHEN_SITE_IS_DOWN = True  # stop account for 20 minutes, to reduce proxy traffic usage"
    echo "CHECK_POINTS = False  # show point for each account every nearly 10 minutes"
    echo "SHOW_LOGS_RARELY = False  # not always show info about actions to decrease pc influence"
    echo
    echo "# Mining mode"
    echo "MINING_MODE = True  # False - not mine grass, True - mine grass | Remove all True on approve \\ register section"
    echo
    echo "# REGISTER PARAMETERS ONLY"
    echo "REGISTER_ACCOUNT_ONLY = False"
    echo "REGISTER_DELAY = (3, 7)"
    echo
    echo "TWO_CAPTCHA_API_KEY = \"\""
    echo "ANTICAPTCHA_API_KEY = \"\""
    echo "CAPMONSTER_API_KEY = \"\""
    echo "CAPSOLVER_API_KEY = \"\""
    echo "CAPTCHAAI_API_KEY = \"\""
    echo
    echo "# Captcha params, left empty"
    echo "CAPTCHA_PARAMS = {"
    echo "    \"captcha_type\": \"v2\","
    echo "    \"invisible_captcha\": False,"
    echo "    \"sitekey\": \"6LeeT-0pAAAAAFJ5JnCpNcbYCBcAerNHlkK4nm6y\","
    echo "    \"captcha_url\": \"https://app.getgrass.io/register\""
    echo "}"
    echo
    echo "########################################"
    echo "ACCOUNTS_FILE_PATH = \"data/accounts.txt\""
    echo "PROXIES_FILE_PATH = \"data/proxies.txt\""
    echo "WALLETS_FILE_PATH = \"data/wallets.txt\""
} > "$CONFIG_FILE_PATH"

echo -e "${GREEN}config.py has been updated successfully!${NC}"

# Navigate back to the grass directory to run Docker commands
cd ../.. || { echo -e "${RED}Failed to navigate back to the grass directory.${NC}"; exit 1; }

# Run Docker Compose
echo -e "${GREEN}Starting Docker containers with Docker Compose...${NC}"
docker-compose up -d

# Build Docker image
echo -e "${GREEN}Building the Docker image...${NC}"
docker build -t grass-app .

# Run the Docker container
echo -e "${GREEN}Running the Docker container...${NC}"
docker run grass-app

echo -e "${GREEN}All operations completed successfully!${NC}"
