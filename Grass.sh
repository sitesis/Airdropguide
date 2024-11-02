#!/bin/bash

# Load logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# ANSI escape codes for colors
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" >> setup_log.txt
}

# Main installation function
install_dependencies() {
    log "Checking and installing dependencies..."

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log "Docker is not installed. Installing Docker..."
        curl -sSL -k https://get.docker.com | sh || { log "Failed to install Docker"; exit 1; }
        sudo systemctl start docker
        sudo systemctl enable docker
        log "Docker installed and started successfully."
    else
        log "Docker is already installed."
    fi

    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { log "Failed to download Docker Compose"; exit 1; }
        chmod +x /usr/local/bin/docker-compose || { log "Failed to set permissions for Docker Compose"; exit 1; }
        log "Docker Compose installed successfully."
    else
        log "Docker Compose is already installed."
    fi

    # Clone the grass repository
    if [ ! -d "grass" ]; then
        log "Cloning the grass repository..."
        git clone https://github.com/MsLolita/grass.git || { log "Failed to clone repository"; exit 1; }
        log "Grass repository cloned successfully."
    else
        log "Grass repository already exists."
    fi
}

# Update accounts.txt and proxies.txt with user input
update_account_and_proxy_files() {
    # Navigate to the cloned grass repository and data folder
    cd grass/data || { log "Failed to access grass/data directory"; exit 1; }

    # Remove accounts.txt, proxies.txt, and config.py if they exist
    rm -f accounts.txt proxies.txt config.py

    # Get email and password from the user
    read -p "Enter your email: " user_email_input
    read -sp "Enter your password: " user_password_input
    echo

    # Save email and password to accounts.txt
    echo "$user_email_input:$user_password_input" > accounts.txt
    log "accounts.txt created and updated successfully in grass/data."

    # Get SOCKS5 proxy input from the user
    read -p "Enter your SOCKS5 proxy (format: socks5://username:password@IP:PORT): " socks5_proxy_input

    # Save the input to proxies.txt
    echo "$socks5_proxy_input" > proxies.txt
    log "proxies.txt created and updated successfully in grass/data."

    # Create new config.py file with specified content
    cat << EOF > config.py
THREADS = 1  # for register account / claim rewards mode / approve email mode
MIN_PROXY_SCORE = 50  # for mining mode

#########################################
APPROVE_EMAIL = False  # approve email (NEEDED IMAP AND ACCESS TO EMAIL)
CONNECT_WALLET = False  # connect wallet (put private keys in wallets.txt)
SEND_WALLET_APPROVE_LINK_TO_EMAIL = False  # send approve link to email
APPROVE_WALLET_ON_EMAIL = False  # get approve link from email (NEEDED IMAP AND ACCESS TO EMAIL)
SEMI_AUTOMATIC_APPROVE_LINK = False # if True - allow to manual paste approve link from email to cli
# If you have possibility to forward all approve mails to single IMAP address:
SINGLE_IMAP_ACCOUNT = False # usage "name@domain.com:password"

# skip for auto chosen
EMAIL_FOLDER = ""  # folder where mails comes
IMAP_DOMAIN = ""  # not always works

#########################################

CLAIM_REWARDS_ONLY = False  # claim tiers rewards only (https://app.getgrass.io/dashboard/referral-program)

STOP_ACCOUNTS_WHEN_SITE_IS_DOWN = True  # stop account for 20 minutes, to reduce proxy traffic usage
CHECK_POINTS = False  # show point for each account every nearly 10 minutes
SHOW_LOGS_RARELY = False  # not always show info about actions to decrease pc influence

# Mining mode
MINING_MODE = True  # False - not mine grass, True - mine grass

# REGISTER PARAMETERS ONLY
REGISTER_ACCOUNT_ONLY = False
REGISTER_DELAY = (3, 7)

TWO_CAPTCHA_API_KEY = ""
ANTICAPTCHA_API_KEY = ""
CAPMONSTER_API_KEY = ""
CAPSOLVER_API_KEY = ""
CAPTCHAAI_API_KEY = ""

# Captcha params, left empty
CAPTCHA_PARAMS = {
    "captcha_type": "v2",
    "invisible_captcha": False,
    "sitekey": "6LeeT-0pAAAAAFJ5JnCpNcbYCBcAerNHlkK4nm6y",
    "captcha_url": "https://app.getgrass.io/register"
}

########################################

ACCOUNTS_FILE_PATH = "data/accounts.txt"
PROXIES_FILE_PATH = "data/proxies.txt"
WALLETS_FILE_PATH = "data/wallets.txt"
EOF

    log "config.py created successfully in grass/data."
}

# Run Docker Compose to start the container
start_container() {
    cd .. # Go back to the grass directory
    docker-compose up -d || { log "Failed to start Docker Compose"; exit 1; }
    log "Docker container started successfully."
}

# Display setup logs
display_logs() {
    echo -e "${YELLOW}=== Setup Log ===${NC}"
    cat setup_log.txt
}

# Execute main functions
install_dependencies
update_account_and_proxy_files
start_container

log "Setup completed."

# Display the logs after completion
display_logs
