#!/bin/bash

# Variabel global
NODE_REGISTRY_URL="https://rpc.pipedev.network"
INSTALL_DIR="/opt/dcdn"
OUTPUT_DIR="$HOME/.permissionless"
CREDENTIALS_FILE="$OUTPUT_DIR/credentials.json"
KEYPAIR_PATH="$OUTPUT_DIR/key.json"
REGISTRATION_TOKEN_PATH="$OUTPUT_DIR/registration_token.txt"  # Lokasi untuk menyimpan token pendaftaran

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

# Generate Registration Token
generate_registration_token() {
    echo -e "${CYAN}=== GENERATE REGISTRATION TOKEN ===${RESET}"
    $INSTALL_DIR/pipe-tool generate-registration-token --node-registry-url="$NODE_REGISTRY_URL" > "$REGISTRATION_TOKEN_PATH"

    if [ -f "$REGISTRATION_TOKEN_PATH" ]; then
        echo -e "${LIGHT_GREEN}Token pendaftaran berhasil dibuat!${RESET}"
        echo -e "Token pendaftaran telah disimpan di: ${YELLOW}$REGISTRATION_TOKEN_PATH${RESET}"
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

# Membuat dompet baru
generate_wallet() {
    echo -e "${CYAN}=== MEMBUAT DOMPET BARU ===${RESET}"
    $INSTALL_DIR/pipe-tool generate-wallet --node-registry-url="$NODE_REGISTRY_URL"

    if [ -f "$KEYPAIR_PATH" ]; then
        echo -e "${LIGHT_GREEN}Dompet baru berhasil dibuat!${RESET}"
        echo -e "Lokasi pasangan kunci: ${YELLOW}$KEYPAIR_PATH${RESET}"
        echo -e "Pastikan Anda mencadangkan frasa pemulihan dan file kunci di lokasi yang aman."
    else
        echo -e "${RED}Gagal membuat dompet baru.${RESET}"
        exit 1
    fi
}

# Menjalankan proses pengaturan
echo -e "${CYAN}=== MEMULAI INSTALASI DAN PENGATURAN NODE PIPE ===${RESET}"

prompt_urls
setup_binaries
perform_login

generate_registration_token  # Menambahkan langkah untuk menghasilkan token pendaftaran

setup_systemd_service

echo -e "${CYAN}=== MEMBUAT DOMPET BARU ===${RESET}"

generate_wallet  # Memindahkan generate wallet ke akhir

echo -e "${LIGHT_GREEN}=== INSTALASI SELESAI ===${RESET}"
echo -e "Untuk memeriksa status layanan, gunakan:"
echo -e "  ${BLUE}sudo systemctl status dcdnd${RESET}"
echo -e "Untuk melihat log secara real-time, gunakan:"
echo -e "  ${BLUE}sudo journalctl -f -u dcdnd.service${RESET}"

# Bergabung dengan channel Telegram Airdrop Node
echo -e "${CYAN}Untuk bergabung dengan channel Telegram Airdrop Node, klik link berikut:${RESET}"
echo -e "${LIGHT_GREEN}https://t.me/airdrop_node${RESET}"
