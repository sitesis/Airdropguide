#!/bin/bash

# Variabel global
NODE_REGISTRY_URL="https://rpc.pipedev.network"
INSTALL_DIR="/opt/dcdn"
OUTPUT_DIR="$HOME/.permissionless"
CREDENTIALS_FILE="$OUTPUT_DIR/credentials.json"
KEYPAIR_PATH="$OUTPUT_DIR/keypair.json"
REGISTRATION_TOKEN_PATH="$OUTPUT_DIR/registration_token.txt"  # Lokasi untuk menyimpan token pendaftaran

# Fungsi untuk menginstal curl dan jq jika belum ada
install_dependencies() {
    echo -e "${CYAN}=== MEMERIKSA DAN MENGINSTAL CURL & JQ ===${RESET}"
    
    # Memeriksa apakah curl sudah terinstal
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}curl tidak ditemukan. Menginstal curl...${RESET}"
        sudo apt-get update
        sudo apt-get install -y curl
        echo -e "${LIGHT_GREEN}curl berhasil diinstal.${RESET}"
    else
        echo -e "${LIGHT_GREEN}curl sudah terinstal.${RESET}"
    fi
    
    # Memeriksa apakah jq sudah terinstal
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}jq tidak ditemukan. Menginstal jq...${RESET}"
        sudo apt-get install -y jq
        echo -e "${LIGHT_GREEN}jq berhasil diinstal.${RESET}"
    else
        echo -e "${LIGHT_GREEN}jq sudah terinstal.${RESET}"
    fi
}

# Instalasi curl dan jq
install_dependencies

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Warna
RESET="\033[0m"
BOLD="\033[1m"
LIGHT_GREEN="\033[1;32m"   # Light green
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"

# Meminta URL dari pengguna
prompt_urls() {
    echo -e "${CYAN}=== MEMASUKKAN URL ===${RESET}"
    read -p "Masukkan URL untuk pipe-tool: " PIPE_TOOL_URL
    read -p "Masukkan URL untuk dcdnd: " DCDND_URL

    # Memastikan URL tidak kosong
    if [ -z "$PIPE_TOOL_URL" ] || [ -z "$DCDND_URL" ]; then
        echo -e "${RED}URL tidak boleh kosong. Proses dibatalkan.${RESET}"
        exit 1
    fi
}

# Setup pipe-tool dan dcdnd binary
setup_binaries() {
    echo -e "${CYAN}=== SETUP BINARIES ===${RESET}"
    sudo mkdir -p "$INSTALL_DIR"

    echo -e "${YELLOW}1.${RESET} Mengunduh pipe-tool binary dari $PIPE_TOOL_URL..."
    sudo curl -L "$PIPE_TOOL_URL" -o "$INSTALL_DIR/pipe-tool"

    echo -e "${YELLOW}2.${RESET} Mengunduh dcdnd binary dari $DCDND_URL..."
    sudo curl -L "$DCDND_URL" -o "$INSTALL_DIR/dcdnd"

    echo -e "${YELLOW}3.${RESET} Memberikan izin eksekusi pada binary..."
    sudo chmod +x "$INSTALL_DIR/pipe-tool"
    sudo chmod +x "$INSTALL_DIR/dcdnd"

    echo -e "${LIGHT_GREEN}Setup binaries selesai.${RESET}"
}

# Fungsi untuk membuat dompet baru dan mendaftarkannya
generate_and_register_wallet() {
    echo -e "${CYAN}=== MEMERIKSA STATUS LOGIN ===${RESET}"

    # Periksa apakah pengguna sudah login
    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        echo -e "${RED}Anda belum login. Silakan login terlebih dahulu.${RESET}"
        echo -e "${YELLOW}Menjalankan login sekarang...${RESET}"
        $INSTALL_DIR/pipe-tool login --node-registry-url="$NODE_REGISTRY_URL"

        # Validasi login
        if [[ ! -f "$CREDENTIALS_FILE" ]]; then
            echo -e "${RED}Login gagal. Proses dihentikan.${RESET}"
            exit 1
        fi
    fi

    echo -e "${LIGHT_GREEN}Login berhasil. Melanjutkan pembuatan wallet.${RESET}"

    # Membuat wallet baru
    echo -e "${YELLOW}Membuat wallet baru...${RESET}"
    $INSTALL_DIR/pipe-tool generate-wallet --node-registry-url="$NODE_REGISTRY_URL"

    # Verifikasi keypair
    if [[ -f "$KEYPAIR_PATH" ]]; then
        echo -e "${LIGHT_GREEN}Wallet berhasil dibuat. File keypair.json ditemukan.${RESET}"
    else
        echo -e "${RED}Gagal membuat wallet atau file keypair.json tidak ditemukan.${RESET}"
        exit 1
    fi
}

# Memvalidasi dan memperbaiki keypair.json setelah wallet dibuat
validate_keypair() {
    echo -e "${CYAN}=== VALIDASI KEYPAIR ===${RESET}"

    # Cek apakah file keypair.json ada
    if [[ ! -f "$KEYPAIR_PATH" ]]; then
        echo -e "${RED}File keypair.json tidak ditemukan. Proses dihentikan.${RESET}"
        exit 1
    fi

    # Cek jika keypair.json berupa array
    if jq -e 'type == "array"' "$KEYPAIR_PATH" >/dev/null 2>&1; then
        echo -e "${LIGHT_GREEN}Format keypair.json valid (array).${RESET}"

        # Cek jika setiap elemen dalam array memiliki 'pubkey' dan 'privkey'
        invalid_keypair=$(jq '[.[] | select(.pubkey == null or .privkey == null)]' "$KEYPAIR_PATH")

        if [[ "$invalid_keypair" != "[]" ]]; then
            echo -e "${RED}Beberapa elemen dalam keypair.json tidak memiliki 'pubkey' atau 'privkey'.${RESET}"
            echo -e "${YELLOW}Memperbaiki keypair.json dengan menambahkan 'pubkey' dan 'privkey' yang valid...${RESET}"

            # Memperbaiki keypair.json untuk memastikan setiap elemen memiliki pubkey dan privkey
            jq '[.[] | {pubkey: .pubkey, privkey: .privkey}]' "$KEYPAIR_PATH" > "$KEYPAIR_PATH.fixed"
            mv "$KEYPAIR_PATH.fixed" "$KEYPAIR_PATH"

            echo -e "${LIGHT_GREEN}Keypair.json telah diperbaiki.${RESET}"
        else
            echo -e "${LIGHT_GREEN}Semua elemen dalam keypair.json sudah valid (memiliki 'pubkey' dan 'privkey').${RESET}"
        fi
    elif jq -e 'type == "object"' "$KEYPAIR_PATH" >/dev/null 2>&1; then
        echo -e "${YELLOW}Format keypair.json adalah objek. Mengonversi ke array...${RESET}"
        # Mengonversi objek menjadi array yang berisi pubkey dan privkey
        jq -n '[{pubkey: .pubkey, privkey: .privkey}]' "$KEYPAIR_PATH" > "$KEYPAIR_PATH"
        echo -e "${LIGHT_GREEN}Keypair.json berhasil diperbaiki ke format array dengan pubkey dan privkey.${RESET}"
    else
        echo -e "${RED}Format keypair.json tidak valid. Proses dihentikan.${RESET}"
        exit 1
    fi
}

# Generate Registration Token
generate_registration_token() {
    echo -e "${CYAN}=== GENERATE REGISTRATION TOKEN ===${RESET}"
    $INSTALL_DIR/pipe-tool generate-registration-token --node-registry-url="$NODE_REGISTRY_URL" > "$REGISTRATION_TOKEN_PATH"

    if [ -f "$REGISTRATION_TOKEN_PATH" ]; then
        echo -e "${LIGHT_GREEN}Token pendaftaran berhasil dibuat!${RESET}"
        echo -e "Token pendaftaran telah disimpan di: ${YELLOW}$REGISTRATION_TOKEN_PATH${RESET}"
    else
        echo -e "${RED}Gagal membuat token pendaftaran.${RESET}"
        exit 1
    fi
}

# Fungsi systemd untuk DCDND
setup_systemd_service() {
    echo -e "${CYAN}=== MENYETEL LAYANAN SYSTEMD UNTUK DCDND ===${RESET}"

    # Membuat layanan systemd untuk dcdnd
    echo -e "[Unit]
Description=DCDND Service
After=network.target

[Service]
ExecStart=$INSTALL_DIR/dcdnd
Restart=always
User=root

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/dcdnd.service

    # Reload systemd dan mulai layanan
    sudo systemctl daemon-reload
    sudo systemctl enable dcdnd
    sudo systemctl start dcdnd
    echo -e "${LIGHT_GREEN}Layanan DCDND berhasil diatur dan dimulai.${RESET}"
}

# Menjalankan seluruh proses
install_dependencies
prompt_urls
setup_binaries
generate_and_register_wallet
validate_keypair  # Memvalidasi keypair setelah wallet dibuat
generate_registration_token
setup_systemd_service
