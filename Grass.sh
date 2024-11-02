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

# Ensure data directory exists
mkdir -p data

# Check and install Docker if not installed
install_docker() {
    if ! command -v docker &> /dev/null; then
        log "Docker tidak ditemukan. Menginstal Docker..."
        if sudo apt update && sudo apt install -y docker.io; then
            sudo systemctl start docker
            sudo systemctl enable docker
            log "Docker sudah diinstal dan dijalankan."
        else
            log "Gagal menginstal Docker."
            exit 1
        fi
    else
        log "Docker sudah terinstal."
    fi
}

# Check and install Docker Compose if not installed
install_docker_compose() {
    DOCKER_COMPOSE_VERSION="v2.20.2"
    if ! command -v docker-compose &> /dev/null; then
        log "Docker Compose tidak ditemukan. Menginstal Docker Compose..."
        if sudo curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; then
            sudo chmod +x /usr/local/bin/docker-compose
            log "Docker Compose sudah diinstal."
        else
            log "Gagal mendownload Docker Compose."
            exit 1
        fi
    else
        log "Docker Compose sudah terinstal."
    fi
}

# Function to validate email format
is_valid_email() {
    [[ "$1" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]
}

# Function to create or replace accounts.txt
create_accounts_file() {
    echo "Masukkan email dan password dalam format email:password"
    while true; do
        read -p "Email: " email
        if is_valid_email "$email"; then
            read -sp "Password: " password
            echo "$email:$password" > data/accounts.txt
            echo ""  # For newline after password input
            log "File accounts.txt telah diperbarui."
            break
        else
            log "Format email tidak valid. Silakan coba lagi."
        fi
    done
}

# Function to create or replace proxies.txt
create_proxies_file() {
    echo "Masukkan proxy dalam format proxy:port"
    while true; do
        read -p "Masukkan proxy (atau ketik 'selesai' untuk mengakhiri): " proxy
        if [[ "$proxy" == "selesai" ]]; then
            break
        fi
        echo "$proxy" >> data/proxies.txt
    done
    log "File proxies.txt telah diperbarui."
}

# Function to update config.py
update_config_file() {
    cat <<EOF > data/config.py
THREADS = 1
MIN_PROXY_SCORE = 50

APPROVE_EMAIL = False
CONNECT_WALLET = False
SEND_WALLET_APPROVE_LINK_TO_EMAIL = False
APPROVE_WALLET_ON_EMAIL = False
SEMI_AUTOMATIC_APPROVE_LINK = False
SINGLE_IMAP_ACCOUNT = False

EMAIL_FOLDER = ""
IMAP_DOMAIN = ""

CLAIM_REWARDS_ONLY = False
STOP_ACCOUNTS_WHEN_SITE_IS_DOWN = True
CHECK_POINTS = False
SHOW_LOGS_RARELY = False

MINING_MODE = True

REGISTER_ACCOUNT_ONLY = False
REGISTER_DELAY = (3, 7)

TWO_CAPTCHA_API_KEY = ""
ANTICAPTCHA_API_KEY = ""
CAPMONSTER_API_KEY = ""
CAPSOLVER_API_KEY = ""
CAPTCHAAI_API_KEY = ""

CAPTCHA_PARAMS = {
    "captcha_type": "v2",
    "invisible_captcha": False,
    "sitekey": "6LeeT-0pAAAAAFJ5JnCpNcbYCBcAerNHlkK4nm6y",
    "captcha_url": "https://app.getgrass.io/register"
}

ACCOUNTS_FILE_PATH = "data/accounts.txt"
PROXIES_FILE_PATH = "data/proxies.txt"
WALLETS_FILE_PATH = "data/wallets.txt"
EOF
    log "File config.py telah diperbarui."
}

# Run installation functions
install_docker
install_docker_compose

# Clone the repository
REPO_URL="https://github.com/MsLolita/grass.git"
if output=$(git clone "$REPO_URL" 2>&1); then
    log "Repository berhasil dikloning."
else
    log "Gagal mengkloning repository: $output"
    exit 1
fi

# Navigate to the grass directory
if cd grass; then
    # Create or update accounts.txt and proxies.txt
    create_accounts_file
    create_proxies_file

    # Update config.py
    update_config_file

    # Start Docker containers and build the application
    if docker-compose up -d && docker build -t grass-app . && docker run grass-app; then
        log "Aplikasi berhasil dibangun dan dijalankan."
    else
        log "Gagal membangun atau menjalankan aplikasi."
        exit 1
    fi
else
    log "Gagal masuk ke direktori grass."
    exit 1
fi

log "Proses instalasi selesai."
