#!/bin/bash

SERVICE_NAME="nexus"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

# --- Warna untuk Pesan ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# --- Update dan Instalasi Paket ---
echo -e "\n${BLUE}[INFO]${RESET} Memperbarui daftar paket dan menginstal build-essential serta curl..."
if ! sudo apt update && sudo apt install build-essential curl -y; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal menginstal paket yang diperlukan."
    exit 1
fi

# --- Instalasi Rust ---
echo -e "\n${BLUE}[INFO]${RESET} Menginstal Rust menggunakan rustup..."
if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal menginstal Rust."
    exit 1
fi

source $HOME/.cargo/env

# Menambahkan Rust ke PATH secara permanen
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc

# Verifikasi Instalasi Rust
echo -e "\n${BLUE}[INFO]${RESET} Verifikasi Instalasi Rust..."
echo -e "\n${GREEN}[INFO]${RESET} Versi Rust:"
rustc --version
echo -e "\n${GREEN}[INFO]${RESET} Versi Cargo:"
cargo --version

# --- Memperbarui Daftar Paket ---
echo -e "\n${BLUE}[INFO]${RESET} Memperbarui daftar paket..."
if ! sudo apt update; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal memperbarui daftar paket."
    exit 1
fi

# --- Memastikan Git Terinstal ---
if ! command -v git &> /dev/null; then
    echo -e "\n${YELLOW}[INFO]${RESET} Git belum terinstal. Menginstal Git..."
    if ! sudo apt install git -y; then
        echo -e "\n${RED}[ERROR]${RESET} Gagal menginstal git."
        exit 1
    fi
else
    echo -e "\n${GREEN}[INFO]${RESET} Git sudah terinstal."
fi

# --- Menghapus Repository Lama (Jika Ada) ---
if [ -d "$HOME/network-api" ]; then
    echo -e "\n${YELLOW}[INFO]${RESET} Menghapus repository yang ada..."
    rm -rf "$HOME/network-api"
fi

# --- Mengkloning Repository Nexus-XYZ ---
echo -e "\n${BLUE}[INFO]${RESET} Mengkloning repository Nexus-XYZ network API..."
if ! git clone https://github.com/nexus-xyz/network-api.git "$HOME/network-api"; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal mengkloning repository."
    exit 1
fi

cd $HOME/network-api/clients/cli

# --- Instalasi Dependensi ---
echo -e "\n${BLUE}[INFO]${RESET} Menginstal dependensi yang diperlukan..."
if ! sudo apt install pkg-config libssl-dev protobuf-compiler -y; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal menginstal dependensi."
    exit 1
fi

# --- Memeriksa Status Layanan ---
if systemctl is-active --quiet nexus.service; then
    echo -e "\n${YELLOW}[INFO]${RESET} nexus.service sedang berjalan. Menghentikan dan menonaktifkannya..."
    sudo systemctl stop nexus.service
    sudo systemctl disable nexus.service
else
    echo -e "\n${GREEN}[INFO]${RESET} nexus.service tidak sedang berjalan."
fi

# --- Meminta Masukan Prover ID (Jika Kosong, Membuat ID Baru) ---
read -p "Masukkan Prover ID (Kosongkan untuk membuat otomatis): " PROVER_ID
if [ -z "$PROVER_ID" ]; then
    echo -e "\n${YELLOW}[INFO]${RESET} Prover ID tidak dimasukkan. Membuat ID baru secara otomatis..."
    PROVER_ID=$(uuidgen)  # Membuat Prover ID baru secara otomatis
    echo -e "\n${GREEN}[INFO]${RESET} Prover ID yang dihasilkan: $PROVER_ID"
fi

# --- Membuat File Layanan systemd ---
echo -e "\n${BLUE}[INFO]${RESET} Membuat file layanan systemd..."
if ! sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Nexus XYZ Prover Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
Environment=NONINTERACTIVE=1
ExecStart=$HOME/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz --prover-id $PROVER_ID
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal membuat file layanan systemd."
    exit 1
fi

# --- Memuat Ulang systemd dan Memulai Layanan ---
echo -e "\n${BLUE}[INFO]${RESET} Memuat ulang systemd dan memulai layanan..."
if ! sudo systemctl daemon-reload; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal memuat ulang systemd."
    exit 1
fi

if ! sudo systemctl start $SERVICE_NAME.service; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal memulai layanan."
    exit 1
fi

if ! sudo systemctl enable $SERVICE_NAME.service; then
    echo -e "\n${RED}[ERROR]${RESET} Gagal mengaktifkan layanan."
    exit 1
fi

echo -e "\n${GREEN}[INFO]${RESET} Instalasi Nexus Prover dan pengaturan layanan selesai!"
echo -e "\n${BLUE}[INFO]${RESET} Menampilkan log Nexus Prover secara langsung..."

# --- Menampilkan Log Secara Langsung ---
sudo journalctl -u nexus.service -fn 50 --follow
