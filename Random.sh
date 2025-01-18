#!/bin/bash

# Warna untuk output
BLUE='\033[0;34m'
WHITE='\033[0;97m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Direktori skrip saat ini
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

# Fungsi instalasi dependensi
install_dependencies() {
    echo -e "${YELLOW}Menginstal dependensi...${RESET}"

    # Inisialisasi Git jika belum ada
    if [ ! -d ".git" ]; then
        echo -e "${YELLOW}Menginisialisasi repository Git...${RESET}"
        git init
    fi

    # Instal Foundry jika belum terinstal
    if ! command -v forge &> /dev/null; then
        echo -e "${YELLOW}Foundry belum terinstal. Menginstal Foundry...${RESET}"
        source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh)
    fi

    # Instal OpenZeppelin Contracts jika belum ada
    if [ ! -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; then
        echo -e "${YELLOW}Menginstal OpenZeppelin Contracts...${RESET}"
        git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
    else
        echo -e "${WHITE}OpenZeppelin Contracts sudah terinstal.${RESET}"
    fi
}

# Fungsi input detail yang diperlukan
input_required_details() {
    echo -e "${YELLOW}-----------------------------------${RESET}"

    # Hapus file .env lama jika ada
    [ -f "$SCRIPT_DIR/token_deployment/.env" ] && rm "$SCRIPT_DIR/token_deployment/.env"

    # Input nama token
    read -p "Masukkan Nama Token (default: AirdropNode): " TOKEN_NAME
    TOKEN_NAME="${TOKEN_NAME:-AirdropNode}"

    # Input simbol token
    read -p "Masukkan Simbol Token (default: NODE): " TOKEN_SYMBOL
    TOKEN_SYMBOL="${TOKEN_SYMBOL:-NODE}"

    # Input jumlah kontrak
    read -p "Jumlah kontrak yang akan dideploy (default: 1): " NUM_CONTRACTS
    NUM_CONTRACTS="${NUM_CONTRACTS:-1}"

    # Input private key
    read -p "Masukkan Private Key Anda: " PRIVATE_KEY

    # Input RPC URL untuk Tea Layer
    read -p "Masukkan RPC URL (misal: https://assam-rpc.tea.xyz/): " RPC_URL
    RPC_URL="${RPC_URL:-https://assam-rpc.tea.xyz/}"

    # Input Explorer URL untuk Tea Layer
    read -p "Masukkan Explorer URL (misal: https://assam.tea.xyz/): " EXPLORER_URL
    EXPLORER_URL="${EXPLORER_URL:-https://assam.tea.xyz/}"

    # Simpan input ke file .env
    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
NUM_CONTRACTS="$NUM_CONTRACTS"
RPC_URL="$RPC_URL"
EXPLORER_URL="$EXPLORER_URL"
EOL

    # Konfigurasi foundry.toml
    cat <<EOL > "$SCRIPT_DIR/foundry.toml"
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
rpc_url = "$RPC_URL"
EOL

    echo -e "${YELLOW}Data berhasil disimpan dan konfigurasi diperbarui.${RESET}"
}

# Menghasilkan 1000 alamat acak untuk pengiriman
generate_random_addresses() {
    echo -e "${YELLOW}Menghasilkan 1000 alamat acak untuk pengiriman...${RESET}"
    
    # Generate 1000 alamat acak untuk pengiriman
    node -e "
    const { ethers } = require('ethers');
    for (let i = 0; i < 1000; i++) {
        const wallet = ethers.Wallet.createRandom();
        console.log(wallet.address);
    }
    " > "$SCRIPT_DIR/random_send_addresses.txt"

    echo -e "${GREEN}Alamat acak telah disimpan ke random_send_addresses.txt${RESET}"
}

# Fungsi untuk kompilasi dan deploy kontrak
deploy_contract() {
    echo -e "${YELLOW}-----------------------------------${RESET}"
    source "$SCRIPT_DIR/token_deployment/.env"

    # Buat direktori src jika belum ada
    mkdir -p "$SCRIPT_DIR/src"

    # Tulis kode kontrak
    cat <<EOL > "$SCRIPT_DIR/src/AirdropNode.sol"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropNode is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, 1000000 * (10 ** decimals())); // 1 juta token
    }

    // Fungsi untuk mint token
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
EOL

    # Kompilasi kontrak
    echo -e "${BLUE}Mengompilasi kontrak...${RESET}"
    forge build || { echo -e "${RED}Kompilasi gagal.${RESET}"; exit 1; }

    # Deploy kontrak
    for i in $(seq 1 "$NUM_CONTRACTS"); do
        echo -e "${BLUE}Mendeploy kontrak $i dari $NUM_CONTRACTS...${RESET}"

        DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/AirdropNode.sol:AirdropNode" \
            --rpc-url "$RPC_URL" \
            --private-key "$PRIVATE_KEY" \
            --broadcast)

        if [[ $? -ne 0 ]]; then
            echo -e "${RED}Deploy kontrak $i gagal.${RESET}"
            continue
        fi

        # Ambil alamat kontrak
        CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
        echo -e "${YELLOW}Kontrak $i berhasil di-deploy di alamat: $CONTRACT_ADDRESS${RESET}"
        echo -e "${WHITE}Lihat kontrak di: ${BLUE}$EXPLORER_URL/address/$CONTRACT_ADDRESS${RESET}"

        # Verifikasi kontrak di Blockscout
        verify_contract "$CONTRACT_ADDRESS"

        # Ambil alamat pengirim dari private key
        SENDER_ADDRESS=$(node -e "
        const { ethers } = require('ethers');
        const wallet = new ethers.Wallet('$PRIVATE_KEY');
        console.log(wallet.address);
        ")

        # Memberikan izin kepada spender menggunakan alamat yang sama
        approve_spender "$CONTRACT_ADDRESS" "$SENDER_ADDRESS"

        send_tokens_random "$CONTRACT_ADDRESS" "$SENDER_ADDRESS"
    done
}

# Fungsi untuk verifikasi kontrak di Blockscout
verify_contract() {
    local contract_address="$1"
    echo -e "${YELLOW}Verifikasi kontrak di Tea Layer: $contract_address${RESET}"

    # URL verifier dan URL API untuk blokscout
    VERIFIER_URL='https://explorer-tea-assam-fo46m5b966.t.conduit.xyz/api/'

    # Verifikasi di Blockscout
    echo -e "${BLUE}Memverifikasi kontrak di Blockscout...${RESET}"
    forge verify-contract \
        --rpc-url "$RPC_URL" \
        --verifier blockscout \
        --verifier-url "$VERIFIER_URL" \
        "$contract_address" \
        "$SCRIPT_DIR/src/AirdropNode.sol:AirdropNode" || {
        echo -e "${RED}Verifikasi gagal untuk kontrak $contract_address.${RESET}"
        exit 1
    }

    echo -e "${GREEN}Kontrak berhasil diverifikasi di Blockscout!${RESET}"
}

# Fungsi untuk memberikan izin kepada spender
approve_spender() {
    local contract_address="$1"
    local sender_address="$2"
    
    # Menentukan jumlah maksimum yang akan disetujui
    local MAX_APPROVAL="115792089237316195423570985008687907853269984665640564039457584007913129640855"

    echo -e "${YELLOW}Memberikan izin kepada spender...${RESET}"

    node -e "
    const { ethers } = require('ethers');
    const provider = new ethers.JsonRpcProvider('$RPC_URL');
    const signer = new ethers.Wallet('$PRIVATE_KEY', provider);
    const contract = new ethers.Contract('$contract_address', ['function approve(address spender, uint256 amount) public returns (bool)'], signer);

    async function approve() {
        const tx = await contract.approve('$sender_address', $MAX_APPROVAL);
        console.log('Transaksi disiarkan:', tx.hash);
    }
    approve();
    "
}

# Fungsi untuk mengirim token ke alamat acak
send_tokens_random() {
    local contract_address="$1"
    local sender_address="$2"
    
    echo -e "${YELLOW}Mengirim token ke alamat acak...${RESET}"
    
    while IFS= read -r address; do
        node -e "
        const { ethers } = require('ethers');
        const provider = new ethers.JsonRpcProvider('$RPC_URL');
        const signer = new ethers.Wallet('$PRIVATE_KEY', provider);
        const contract = new ethers.Contract('$contract_address', ['function transfer(address recipient, uint256 amount) public returns (bool)'], signer);
        
        async function send() {
            const amount = ethers.utils.parseUnits('1', 18);  // Kirim 1 token
            const tx = await contract.transfer('$address', amount);
            console.log('Token dikirim ke: $address, Transaksi: ' + tx.hash);
        }
        send();
        " || echo -e "${RED}Gagal mengirim ke alamat $address.${RESET}"
    done < "$SCRIPT_DIR/random_send_addresses.txt"
}

# Menjalankan semua fungsi
install_dependencies
input_required_details
generate_random_addresses
deploy_contract

echo -e "${GREEN}Selesai!${RESET}"
