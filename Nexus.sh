#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

NORMAL=$(tput sgr0)
RED='\033[1;31m'


show() {
    case $2 in
        "error")
            echo -e "${RED}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${RED}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${RED}✅ $1${NORMAL}"
            ;;
    esac
}

SERVICE_NAME="nexus"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"

show "Nginstal Rust..." "progress"
if ! source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/rust.sh); then
    show "Gagal nginstal Rust." "error"
    exit 1
fi

show "Ngupdate dhaptar paket..." "progress"
if ! sudo apt update; then
    show "Gagal ngupdate dhaptar paket." "error"
    exit 1
fi

if ! command -v git &> /dev/null; then
    show "Git ora diinstal. Nginstal git..." "progress"
    if ! sudo apt install git -y; then
        show "Gagal nginstal git." "error"
        exit 1
    fi
else
    show "Git wis diinstal."
fi

if [ -d "$HOME/network-api" ]; then
    show "Mbusak repositori sing wis ana..." "progress"
    rm -rf "$HOME/network-api"
fi

sleep 3

show "Nggandha repositori Nexus-XYZ network API..." "progress"
if ! git clone https://github.com/nexus-xyz/network-api.git "$HOME/network-api"; then
    show "Gagal nggandha repositori." "error"
    exit 1
fi

cd $HOME/network-api/clients/cli

show "Nginstal dependensi sing dibutuhake..." "progress"
if ! sudo apt install pkg-config libssl-dev -y; then
    show "Gagal nginstal dependensi." "error"
    exit 1
fi

if systemctl is-active --quiet nexus.service; then
    show "nexus.service saiki mlaku. Mandhegake lan mateni..."
    sudo systemctl stop nexus.service
    sudo systemctl disable nexus.service
else
    show "nexus.service ora mlaku."
fi

show "Nggawe layanan systemd..." "progress"
if ! sudo bash -c "cat > $SERVICE_FILE <<EOF
[Unit]
Description=Nexus XYZ Prover Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/network-api/clients/cli
Environment=NONINTERACTIVE=1
ExecStart=$HOME/.cargo/bin/cargo run --release --bin prover -- beta.orchestrator.nexus.xyz
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"; then
    show "Gagal nggawe file layanan systemd." "error"
    exit 1
fi

show "Nggeload ulang systemd lan miwiti layanan..." "progress"
if ! sudo systemctl daemon-reload; then
    show "Gagal nggeload ulang systemd." "error"
    exit 1
fi

if ! sudo systemctl start $SERVICE_NAME.service; then
    show "Gagal miwiti layanan." "error"
    exit 1
fi

if ! sudo systemctl enable $SERVICE_NAME.service; then
    show "Gagal ngaktifake layanan." "error"
    exit 1
fi

show "Status layanan:" "progress"
if ! sudo systemctl status $SERVICE_NAME.service; then
    show "Gagal njupuk status layanan." "error"
fi

show "Instalasi Nexus Prover lan setup layanan rampung!"
echo -e "\nKamu dapat cek status prover menggunakan iki:"
echo "systemctl status nexus.service"
echo -e "\nCek logs nganggo iki:"
echo "journalctl -u nexus.service -f -n 50"
