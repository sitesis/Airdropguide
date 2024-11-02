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

# Clone the grass repository
clone_grass_repo() {
    log "Mengkloning repositori grass..."
    git clone https://github.com/MsLolita/grass.git || { log "Gagal mengkloning repositori"; exit 1; }
    log "Repositori berhasil dikloning."
}

# Navigate to grass directory
navigate_to_grass() {
    cd grass || { log "Gagal masuk ke direktori grass"; exit 1; }
}

# Validate email format
validate_email() {
    [[ $1 =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] || { log "Format email tidak valid."; exit 1; }
}

# Validate proxy format
validate_proxy() {
    [[ $1 =~ ^http://[a-zA-Z0-9._%+-]+:[0-9]+$ ]] || { log "Format proxy tidak valid. Gunakan format http://username:password@ip_address:port"; exit 1; }
}

# Update accounts.txt with email and password
update_accounts() {
    # Check if accounts.txt exists and remove it
    [ -f "data/accounts.txt" ] && rm -f "data/accounts.txt"

    echo "Masukkan email Anda: "
    read -r USER_EMAIL
    validate_email "$USER_EMAIL"

    echo "Masukkan kata sandi Anda: "
    read -r USER_PASSWORD

    # Create data directory if it doesn't exist
    mkdir -p data

    echo "$USER_EMAIL:$USER_PASSWORD" > data/accounts.txt
    log "accounts.txt berhasil diperbarui."
}

# Update proxies.txt with static proxy
update_proxies() {
    # Check if proxies.txt exists and remove it
    [ -f "data/proxies.txt" ] && rm -f "data/proxies.txt"

    echo "Masukkan static proxy (format: http://username:password@ip_address:port): "
    read -r STATIC_PROXY
    validate_proxy "$STATIC_PROXY"

    # Ensure data directory exists
    mkdir -p data

    echo "$STATIC_PROXY" > data/proxies.txt
    log "proxies.txt berhasil diperbarui."
}

# Update main.py with specified content
update_main_py() {
    cat << EOF > main.py
THREADS = 1  # untuk mode pendaftaran akun / klaim hadiah / persetujuan email
MIN_PROXY_SCORE = 50  # untuk mode penambangan

#########################################
APPROVE_EMAIL = False  # menyetujui email (MEMBUTUHKAN IMAP DAN AKSES EMAIL)
CONNECT_WALLET = False  # menghubungkan dompet (masukkan private keys ke wallets.txt)
SEND_WALLET_APPROVE_LINK_TO_EMAIL = True  # mengirim link persetujuan ke email
APPROVE_WALLET_ON_EMAIL = False  # mendapatkan link persetujuan dari email (MEMBUTUHKAN IMAP DAN AKSES EMAIL)
SEMI_AUTOMATIC_APPROVE_LINK = False  # jika True - izinkan untuk menempelkan link persetujuan secara manual dari email ke CLI
SINGLE_IMAP_ACCOUNT = False  # gunakan "name@domain.com:password"

EMAIL_FOLDER = ""  # folder tempat email masuk
IMAP_DOMAIN = ""  # tidak selalu berfungsi

#########################################

CLAIM_REWARDS_ONLY = False  # hanya klaim hadiah (https://app.getgrass.io/dashboard/referral-program)

STOP_ACCOUNTS_WHEN_SITE_IS_DOWN = True  # hentikan akun selama 20 menit untuk mengurangi penggunaan lalu lintas proxy
CHECK_POINTS = True  # tampilkan poin untuk setiap akun hampir setiap 10 menit
SHOW_LOGS_RARELY = True  # tidak selalu menunjukkan info untuk mengurangi pengaruh pada PC

# Mode Penambangan
MINING_MODE = True  # False - tidak menambang grass, True - menambang grass

# Hanya Parameter Pendaftaran
REGISTER_ACCOUNT_ONLY = False
REGISTER_DELAY = (3, 7)

TWO_CAPTCHA_API_KEY = "${TWO_CAPTCHA_API_KEY:-}"
ANTICAPTCHA_API_KEY = "${ANTICAPTCHA_API_KEY:-}"
CAPMONSTER_API_KEY = "${CAPMONSTER_API_KEY:-}"
CAPSOLVER_API_KEY = "${CAPSOLVER_API_KEY:-}"
CAPTCHAAI_API_KEY = "${CAPTCHAAI_API_KEY:-}"

# Parameter Captcha, biarkan kosong
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
    log "Isi main.py berhasil dihapus dan diganti dengan konfigurasi baru."
}

# Execute main functions
install_docker
install_docker_compose
clone_grass_repo
navigate_to_grass

# Ensure data directory exists
mkdir -p data
log "Direktori grass/data berhasil dibuat."

update_accounts
update_proxies
update_main_py

# Run Docker Compose
docker-compose up -d || { log "Gagal menjalankan Docker Compose"; exit 1; }
log "Docker Compose berhasil dijalankan."

# Build and run the Docker image
if [ -f Dockerfile ]; then
    docker build -t grass-app . || { log "Gagal membangun Docker image"; exit 1; }
    docker run grass-app || { log "Gagal menjalankan Docker"; exit 1; }
    log "Aplikasi grass berhasil dijalankan."
else
    log "Dockerfile tidak ditemukan. Pastikan Anda berada di direktori yang benar."
    exit 1
fi
