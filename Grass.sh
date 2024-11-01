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

# Check and install Docker if not installed
install_docker() {
    if ! command -v docker &> /dev/null; then
        log "Docker tidak ditemukan. Menginstal Docker..."
        sudo apt update
        sudo apt install -y docker.io || { log "Gagal menginstal Docker"; exit 1; }
        sudo systemctl start docker
        sudo systemctl enable docker
        log "Docker sudah diinstal dan dijalankan."
    else
        log "Docker sudah terinstal."
    fi
}

# Check and install Docker Compose if not installed
install_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        log "Docker Compose tidak ditemukan. Menginstal Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose || { log "Gagal mendownload Docker Compose"; exit 1; }
        sudo chmod +x /usr/local/bin/docker-compose || { log "Gagal mengatur izin untuk Docker Compose"; exit 1; }
        log "Docker Compose sudah diinstal."
    else
        log "Docker Compose sudah terinstal."
    fi
}

# Clone the grass repository and enter it
clone_grass_repo() {
    log "Mengkloning repositori grass..."
    git clone https://github.com/MsLolita/grass.git || { log "Gagal mengkloning repositori"; exit 1; }

    # Check if the 'grass' directory exists and enter it
    if [ -d "grass" ]; then
        cd grass || { log "Gagal masuk ke direktori grass setelah kloning"; exit 1; }
        log "Berhasil masuk ke direktori grass."
    else
        log "Direktori grass tidak ditemukan setelah kloning."
        exit 1
    fi
}

# Update accounts.txt with email and password
update_accounts() {
    # Ensure we are in the grass directory, then enter data
    cd grass/data || { log "Gagal mengakses direktori grass/data"; exit 1; }

    # Clear accounts.txt and write new email and password
    echo "Masukkan email Anda: "
    read -r USER_EMAIL
    echo "Masukkan kata sandi Anda: "
    read -r USER_PASSWORD

    echo "$USER_EMAIL:$USER_PASSWORD" > accounts.txt
    log "accounts.txt berhasil diperbarui."
}

# Update proxies.txt with static proxy
update_proxies() {
    # Ensure we are in the grass directory, then enter data
    cd grass/data || { log "Gagal mengakses direktori grass/data"; exit 1; }

    # Clear proxies.txt and write new proxy
    echo "Masukkan static proxy IP:PORT: "
    read -r STATIC_PROXY

    echo "$STATIC_PROXY" > proxies.txt
    log "proxies.txt berhasil diperbarui."
}

# Update main.py with specified content
update_main_py() {
    cd grass || { log "Gagal mengakses direktori grass"; exit 1; }

    # Clear main.py and write the new configuration
    cat << EOF > main.py
# Configuration for Grass Mining Script

THREADS = 1  # Number of threads for account registration, claiming rewards, and email approval
MIN_PROXY_SCORE = 50  # Minimum proxy score for mining mode

#########################################
APPROVE_EMAIL = False  # Approve email (requires IMAP and email access)
CONNECT_WALLET = False  # Connect wallet (add private keys to wallets.txt)
SEND_WALLET_APPROVE_LINK_TO_EMAIL = True  # Send approval link to email
APPROVE_WALLET_ON_EMAIL = False  # Approve wallet from email (requires IMAP and email access)
SEMI_AUTOMATIC_APPROVE_LINK = False  # If True, allows manual pasting of approval links from email

# Use a single IMAP account for email approvals if possible:
SINGLE_IMAP_ACCOUNT = False  # e.g., "name@domain.com:password"

# Skip for automatic selection
EMAIL_FOLDER = ""  # Folder for incoming emails
IMAP_DOMAIN = ""  # IMAP domain, might not work with all setups

#########################################

CLAIM_REWARDS_ONLY = False  # Claim rewards only (https://app.getgrass.io/dashboard/referral-program)

STOP_ACCOUNTS_WHEN_SITE_IS_DOWN = True  # Pause accounts for 20 minutes if site is down to reduce proxy traffic
CHECK_POINTS = True  # Show points for each account approximately every 10 minutes
SHOW_LOGS_RARELY = True  # Limit log display to reduce impact on performance

# Mining Mode
MINING_MODE = True  # Set to True for mining grass, False to disable

# Registration Parameters
REGISTER_ACCOUNT_ONLY = False
REGISTER_DELAY = (3, 7)  # Random delay in seconds between registrations

# Captcha API Keys
TWO_CAPTCHA_API_KEY = ""
ANTICAPTCHA_API_KEY = ""
CAPMONSTER_API_KEY = ""
CAPSOLVER_API_KEY = ""
CAPTCHAAI_API_KEY = ""

# Captcha Parameters (leave empty if not needed)
CAPTCHA_PARAMS = {
    "captcha_type": "v2",
    "invisible_captcha": False,
    "sitekey": "6LeeT-0pAAAAAFJ5JnCpNcbYCBcAerNHlkK4nm6y",
    "captcha_url": "https://app.getgrass.io/register"
}

########################################

# File Paths
ACCOUNTS_FILE_PATH = "data/accounts.txt"
PROXIES_FILE_PATH = "data/proxies.txt"
WALLETS_FILE_PATH = "data/wallets.txt"
EOF
    log "Isi main.py berhasil dihapus dan diganti dengan konfigurasi baru."
}

# Execute main functions
install_docker
install_docker_compose
clone_grass_repo
update_accounts
update_proxies
update_main_py

# Run Docker Compose
docker-compose up -d || { log "Gagal menjalankan Docker Compose"; exit 1; }
log "Docker Compose berhasil dijalankan."

# Build and run the Docker image
docker build -t grass-app . || { log "Gagal membangun Docker image"; exit 1; }
docker run grass-app || { log "Gagal menjalankan Docker"; exit 1; }
log "Aplikasi grass berhasil dijalankan."
