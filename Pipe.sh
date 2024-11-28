#!/bin/bash

# Variabel global
PIPE_TOOL_URL="https://github.com/choir94/Airdropguide/raw/refs/heads/main/pipe-tool"
DCDND_URL="https://github.com/choir94/Airdropguide/raw/refs/heads/main/dcdnd"
NODE_REGISTRY_URL="https://rpc.pipedev.network"
INSTALL_DIR="/opt/dcdn"
OUTPUT_DIR="$HOME/.permissionless"
CREDENTIALS_FILE="$OUTPUT_DIR/credentials.json"
KEYPAIR_PATH="$OUTPUT_DIR/key.json"

# Setup pipe-tool dan dcdnd binary
setup_binaries() {
    echo "=== SETUP BINARIES ==="
    sudo mkdir -p "$INSTALL_DIR"

    echo "1. Mengunduh pipe-tool binary..."
    sudo curl -L "$PIPE_TOOL_URL" -o "$INSTALL_DIR/pipe-tool"

    echo "2. Mengunduh dcdnd binary..."
    sudo curl -L "$DCDND_URL" -o "$INSTALL_DIR/dcdnd"

    echo "3. Memberikan izin eksekusi pada binary..."
    sudo chmod +x "$INSTALL_DIR/pipe-tool"
    sudo chmod +x "$INSTALL_DIR/dcdnd"

    echo "Setup binaries selesai."
}

# Login ke jaringan Pipa
perform_login() {
    echo "=== MASUK KE JARINGAN PIPA ==="
    $INSTALL_DIR/pipe-tool login --node-registry-url="$NODE_REGISTRY_URL"
    if [ -f "$CREDENTIALS_FILE" ]; then
        echo "Login berhasil! File 'credentials.json' telah dibuat di $OUTPUT_DIR."
    else
        echo "Login gagal. Pastikan kredensial Anda benar."
        exit 1
    fi
}

# Membuat dompet baru
generate_wallet() {
    echo "=== MEMBUAT DOMPET BARU ==="
    $INSTALL_DIR/pipe-tool generate-wallet --node-registry-url="$NODE_REGISTRY_URL"
    if [ -f "$KEYPAIR_PATH" ]; then
        echo "Dompet baru berhasil dibuat!"
        echo "Lokasi pasangan kunci: $KEYPAIR_PATH"
        echo "Pastikan Anda mencadangkan frasa pemulihan dan file kunci di lokasi yang aman."
    else
        echo "Gagal membuat dompet baru."
        exit 1
    fi
}

# Menautkan dompet menggunakan kunci publik Base58
link_wallet() {
    echo "=== MENAUTKAN DOMPET DENGAN KUNCI PUBLIK BASE58 ==="
    read -p "Masukkan kunci publik Base58: " PUBLIC_KEY
    if [ -z "$PUBLIC_KEY" ]; then
        echo "Kunci publik tidak boleh kosong. Proses dibatalkan."
        exit 1
    fi
    $INSTALL_DIR/pipe-tool link-wallet --node-registry-url="$NODE_REGISTRY_URL" --public-key="$PUBLIC_KEY" --key-path="$KEYPAIR_PATH"
    if [ $? -eq 0 ]; then
        echo "Dompet berhasil ditautkan."
    else
        echo "Gagal menautkan dompet."
        exit 1
    fi
}

# Setup layanan systemd untuk dcdnd
setup_systemd_service() {
    echo "=== SETUP SYSTEMD SERVICE ==="
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

    echo "Service dcdnd telah diatur dan dijalankan."
}

# Menjalankan proses pengaturan
echo "=== MEMULAI INSTALASI DAN PENGATURAN NODE PIPA ==="
setup_binaries
perform_login

echo "=== PILIH OPSI UNTUK PENGATURAN DOMPET ==="
echo "1. Buat dompet baru"
echo "2. Tautkan dompet menggunakan kunci publik Base58"
read -p "Masukkan pilihan Anda (1/2): " WALLET_OPTION

case $WALLET_OPTION in
    1)
        generate_wallet
        ;;
    2)
        link_wallet
        ;;
    *)
        echo "Pilihan tidak valid. Proses dibatalkan."
        exit 1
        ;;
esac

setup_systemd_service

echo "=== INSTALASI SELESAI ==="
echo "Untuk memeriksa status layanan, gunakan:"
echo "  sudo systemctl status dcdnd"
echo "Untuk melihat log secara real-time, gunakan:"
echo "  sudo journalctl -f -u dcdnd.service"
