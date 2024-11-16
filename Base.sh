#!/bin/bash

# Tentukan kode warna untuk tampilan yang lebih menarik
RESET="\e[0m"
BOLD="\e[1m"
MAROON="\e[38;5;88m"       # Maroon untuk sukses
CYAN="\e[96m"              # Cyan muda untuk pesan informasi
YELLOW="\e[93m"            # Kuning muda untuk prompt
RED="\e[91m"               # Merah untuk kesalahan
MAGENTA="\e[35m"           # Magenta untuk catatan khusus
BLUE="\e[94m"              # Biru untuk bagian umum
ORANGE="\e[38;5;214m"      # Orange untuk aksi utama
LIGHT_BLUE="\e[94m"        # Biru terang untuk langkah-langkah penerapan

# Fungsi untuk efek loading logo dengan animasi
loading_logo() {
    clear
    echo -e "${CYAN}Memuat logo, harap tunggu...${RESET}"

    # Membuat animasi loading dengan simbol berputar
    spin='|/-\'
    while true; do
        for i in $(seq 0 3); do
            echo -n -e "\r${CYAN}[${spin:$i:1}] Memuat logo..."
            sleep 0.2
        done
    done
}

# Menampilkan logo dengan loading
loading_logo &
SPIN_PID=$!

# Menunggu beberapa detik untuk efek loading
sleep 3

# Menghentikan animasi loading dan menampilkan logo
kill $SPIN_PID
clear
echo -e "${MAGENTA}-----------------------------------${RESET}"
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
echo -e "${MAGENTA}-----------------------------------${RESET}"

sleep 2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

install_dependencies() {
    CONTRACT_NAME="AirdropNode"

    # Inisialisasi Git jika belum dilakukan
    if [ ! -d ".git" ]; then
        echo -e "${MAGENTA}Menginisialisasi repositori Git...${RESET}"
        git init
    fi

    # Instalasi Foundry jika belum terpasang
    if ! command -v forge &> /dev/null; then
        echo -e "${ORANGE}Foundry tidak terinstal. Instalasi sekarang...${RESET}"
        source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh)
    fi

    # Instalasi OpenZeppelin Contracts jika belum ada
    if [ ! -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; then
        echo -e "${CYAN}Menginstal OpenZeppelin Contracts...${RESET}"
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
    else
        echo -e "${MAROON}OpenZeppelin Contracts sudah terinstal.${RESET}"
    fi
}

input_required_details() {
    echo -e "${LIGHT_BLUE}-----------------------------------${RESET}"

    # Hapus .env yang ada jika ada
    if [ -f "$SCRIPT_DIR/token_deployment/.env" ]; then
        rm "$SCRIPT_DIR/token_deployment/.env"
    fi

    # Minta nama token dan simbolnya, default AirdropNode dan NODE jika kosong
    read -p "$(echo -e ${BLUE}Masukkan Nama Token (default: AirdropNode): ${RESET})" TOKEN_NAME
    read -p "$(echo -e ${BLUE}Masukkan Simbol Token (default: NODE): ${RESET})" TOKEN_SYMBOL

    # Tetapkan nilai default jika input kosong
    TOKEN_NAME="${TOKEN_NAME:-AirdropNode}"
    TOKEN_SYMBOL="${TOKEN_SYMBOL:-NODE}"

    # Minta jumlah kontrak yang akan diterapkan
    read -p "$(echo -e ${BLUE}Masukkan jumlah kontrak yang akan diterapkan (default: 1): ${RESET})" NUM_CONTRACTS

    # Tetapkan nilai default jika input kosong
    NUM_CONTRACTS="${NUM_CONTRACTS:-1}"

    # Minta input private key
    read -p "$(echo -e ${BLUE}Masukkan Private Key Anda: ${RESET})" PRIVATE_KEY

    # Tentukan URL RPC langsung
    RPC_URL="https://mainnet.base.org"

    # Buat file .env dengan detail yang diberikan
    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
NUM_CONTRACTS="$NUM_CONTRACTS"
RPC_URL="$RPC_URL"
EOL

    # Sumber file .env
    source "$SCRIPT_DIR/token_deployment/.env"

    # Perbarui foundry.toml dengan RPC URL yang diberikan
    cat <<EOL > "$SCRIPT_DIR/foundry.toml"
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
rpc_url = "$RPC_URL"
EOL

    echo -e "${MAROON}File telah diperbarui dengan data yang diberikan.${RESET}"
}

deploy_contract() {
    echo -e "${LIGHT_BLUE}-----------------------------------${RESET}"
    # Sumber file .env lagi untuk mendapatkan variabel lingkungan terbaru
    source "$SCRIPT_DIR/token_deployment/.env"

    # Buat direktori sumber kontrak jika belum ada
    mkdir -p "$SCRIPT_DIR/src"

    # Tulis kode kontrak ke file
    cat <<EOL > "$SCRIPT_DIR/src/AirdropNode.sol"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNode is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, 1000 * (10 ** decimals()));  # Pasokan default 1000 token
    }
}
EOL

    # Kompilasi kontrak
    echo -e "${CYAN}Mengekompilasi kontrak...${RESET}"
    forge build

    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Kompilasi kontrak gagal.${RESET}"
        exit 1
    fi

    # Terapkan kontrak berdasarkan jumlah kontrak
    for i in $(seq 1 "$NUM_CONTRACTS"); do
        echo -e "${LIGHT_BLUE}Menerapkan kontrak $i dari $NUM_CONTRACTS...${RESET}"

        DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/AirdropNode.sol:AirdropNode" \
            --rpc-url "$RPC_URL" \
            --private-key "$PRIVATE_KEY")

        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Penerapan kontrak $i gagal.${RESET}"
            continue
        fi

        # Ekstrak dan tampilkan alamat kontrak yang diterapkan
        CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
        echo -e "${MAROON}Kontrak $i diterapkan dengan sukses di alamat: $CONTRACT_ADDRESS${RESET}"

        # Hasilkan dan tampilkan URL BaseScan untuk kontrak
        BASESCAN_URL="https://basescan.org/address/$CONTRACT_ADDRESS"
        echo -e "${CYAN}Anda dapat melihat kontrak Anda di: $BASESCAN_URL${RESET}"
    done
}

# Main execution flow
install_dependencies
input_required_details
deploy_contract

# Undangan untuk bergabung dengan channel Telegram
echo -e "${YELLOW}-----------------------------------${RESET}"
echo -e "${MAGENTA}Bergabunglah dengan channel Telegram kami untuk pembaruan dan dukungan: https://t.me/airdrop_node${RESET}"
