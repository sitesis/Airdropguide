#!/bin/bash

# Variabel global
NODE_REGISTRY_URL="https://rpc.pipedev.network"
INSTALL_DIR="/opt/dcdn"
OUTPUT_DIR="$HOME/.permissionless"
CREDENTIALS_FILE="$OUTPUT_DIR/credentials.json"
KEYPAIR_PATH="$OUTPUT_DIR/keypair.json"
REGISTRATION_TOKEN_PATH="$OUTPUT_DIR/registration_token.txt"

# Warna
RESET="\033[0m"
BOLD="\033[1m"
LIGHT_GREEN="\033[1;32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"

# Meminta URL dari pengguna
prompt_urls() {
    echo -e "${CYAN}=== MEMASUKKAN URL ===${RESET}"
    read -p "Masukkan URL untuk pipe-tool: " PIPE_TOOL_URL
    read -p "Masukkan URL untuk dcdnd: " DCDND_URL

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

# Login ke jaringan Pipe
perform_login() {
    echo -e "${CYAN}=== MASUK KE JARINGAN PIPE ===${RESET}"
    $INSTALL_DIR/pipe-tool login --node-registry-url="$NODE_REGISTRY_URL"

    if [ -f "$CREDENTIALS_FILE" ]; then
        echo -e "${LIGHT_GREEN}Login berhasil! File 'credentials.json' telah dibuat di $OUTPUT_DIR.${RESET}"
    else
        echo -e "${RED}Login gagal. Pastikan kredensial Anda benar.${RESET}"
        exit 1
    fi
}

# Validasi dan konversi keypair.json
validate_and_fix_keypair() {
    if jq -e 'type == "array"' "$KEYPAIR_PATH" >/dev/null 2>&1; then
        echo -e "${YELLOW}File keypair.json berisi array. Mengonversi ke format publicKey dan privateKey...${RESET}"
        HEX_KEY=$(jq -r '. | map(tohex) | join("")' "$KEYPAIR_PATH")
        jq -n --arg key "$HEX_KEY" '{publicKey: $key, privateKey: $key}' > "$KEYPAIR_PATH"
        echo -e "${LIGHT_GREEN}Format file keypair.json berhasil diperbaiki.${RESET}"
    elif ! jq -e '.publicKey and .privateKey' "$KEYPAIR_PATH" >/dev/null 2>&1; then
        echo -e "${RED}Format file keypair.json tidak valid. Proses dihentikan.${RESET}"
        exit 1
    else
        echo -e "${LIGHT_GREEN}Format file keypair.json valid.${RESET}"
    fi
}

# Membuat wallet baru dan mendaftarkannya
generate_and_register_wallet() {
    echo -e "${CYAN}=== MEMBUAT WALLET BARU ===${RESET}"

    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        echo -e "${RED}Anda belum login. Silakan login terlebih dahulu.${RESET}"
        exit 1
    fi

    $INSTALL_DIR/pipe-tool generate-wallet --node-registry-url="$NODE_REGISTRY_URL"

    if [[ -f "$KEYPAIR_PATH" ]]; then
        echo -e "${LIGHT_GREEN}Wallet berhasil dibuat. File keypair.json ditemukan.${RESET}"
        validate_and_fix_keypair
    else
        echo -e "${RED}Gagal membuat wallet atau file keypair.json tidak ditemukan.${RESET}"
        exit 1
    fi

    $INSTALL_DIR/pipe-tool link-wallet --node-registry-url="$NODE_REGISTRY_URL" --keypair="$KEYPAIR_PATH"
    if [[ $? -eq 0 ]]; then
        echo -e "${LIGHT_GREEN}Wallet berhasil dihubungkan.${RESET}"
    else
        echo -e "${RED}Gagal menghubungkan wallet.${RESET}"
        exit 1
    fi
}

# Generate Registration Token
generate_registration_token() {
    echo -e "${CYAN}=== GENERATE REGISTRATION TOKEN ===${RESET}"
    $INSTALL_DIR/pipe-tool generate-registration-token --node-registry-url="$NODE_REGISTRY_URL" > "$REGISTRATION_TOKEN_PATH"

    if [ -f "$REGISTRATION_TOKEN_PATH" ]; then
        echo -e "${LIGHT_GREEN}Token pendaftaran berhasil dibuat.${RESET}"
    else
        echo -e "${RED}Gagal menghasilkan token pendaftaran.${RESET}"
        exit 1
    fi
}

# Setup layanan systemd untuk dcdnd
setup_systemd_service() {
    echo -e "${CYAN}=== SETUP SYSTEMD SERVICE ===${RESET}"

    sudo bash -c "cat > /etc/systemd/system/dcdnd.service <<EOF
[Unit]
Description=DCDN Node Service
After=network.target
Wants=network-online.target

[Service]
ExecStart=$INSTALL_DIR/dcdnd \
            --grpc-server-url=0.0.0.0:8002 \
            --http-server-url=0.0.0.0:8003 \
            --node-registry-url=\"$NODE_REGISTRY_URL\" \
            --cache-max-capacity-mb=1024 \
            --credentials-dir=\"$OUTPUT_DIR\" \
            --allow-origin=*

Restart=always
RestartSec=5
LimitNOFILE=65536
LimitNPROC=4096
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node
WorkingDirectory=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF"

    sudo systemctl daemon-reload
    sudo systemctl enable dcdnd.service
    sudo systemctl start dcdnd.service

    echo -e "${LIGHT_GREEN}Service dcdnd telah diatur dan dijalankan.${RESET}"
}

# Menjalankan proses pengaturan
echo -e "${CYAN}=== MEMULAI INSTALASI DAN PENGATURAN NODE PIPE ===${RESET}"

prompt_urls
setup_binaries
perform_login
generate_and_register_wallet
generate_registration_token
setup_systemd_service

echo -e "${LIGHT_GREEN}=== INSTALASI SELESAI ===${RESET}"
