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

    if ! command -v forge &> /dev/null; then
        echo -e "${YELLOW}Menginstal Foundry...${RESET}"
        source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh)
    fi

    if ! command -v screen &> /dev/null; then
        echo -e "${YELLOW}Menginstal screen...${RESET}"
        sudo apt-get install screen -y
    fi
}

# Fungsi untuk input detail
input_required_details() {
    echo -e "${YELLOW}-----------------------------------${RESET}"

    read -p "Masukkan Nama Token (default: AirdropNode): " TOKEN_NAME
    TOKEN_NAME="${TOKEN_NAME:-AirdropNode}"

    read -p "Masukkan Simbol Token (default: NODE): " TOKEN_SYMBOL
    TOKEN_SYMBOL="${TOKEN_SYMBOL:-NODE}"

    read -p "Jumlah kontrak yang akan dideploy (default: 1): " NUM_CONTRACTS
    NUM_CONTRACTS="${NUM_CONTRACTS:-1}"

    read -p "Masukkan Private Key Anda: " PRIVATE_KEY

    read -p "Masukkan RPC URL (misal: https://assam-rpc.tea.xyz/): " RPC_URL
    RPC_URL="${RPC_URL:-https://assam-rpc.tea.xyz/}"

    read -p "Masukkan Explorer URL (misal: https://assam.tea.xyz/): " EXPLORER_URL
    EXPLORER_URL="${EXPLORER_URL:-https://assam.tea.xyz/}"

    mkdir -p "$SCRIPT_DIR/token_deployment"
    cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
NUM_CONTRACTS="$NUM_CONTRACTS"
RPC_URL="$RPC_URL"
EXPLORER_URL="$EXPLORER_URL"
EOL
}

# Menghasilkan 5000 alamat acak
generate_random_addresses() {
    echo -e "${YELLOW}Menghasilkan 5000 alamat acak untuk pengiriman...${RESET}"

    node -e "
    const { ethers } = require('ethers');
    const fs = require('fs');
    const addresses = [];
    for (let i = 0; i < 5000; i++) {
        const wallet = ethers.Wallet.createRandom();
        addresses.push(wallet.address);
    }
    fs.writeFileSync('$SCRIPT_DIR/random_send_addresses.txt', addresses.join('\\n'));
    "

    echo -e "${GREEN}Alamat acak telah disimpan ke random_send_addresses.txt${RESET}"
}

# Mengirim token ke 5000 alamat
send_tokens_random() {
    echo -e "${YELLOW}Mengirim token ke 5000 alamat...${RESET}"

    local contract_address="$1"
    local sender_address="$2"

    while IFS= read -r address; do
        node -e "
        const { ethers } = require('ethers');
        const provider = new ethers.JsonRpcProvider('$RPC_URL');
        const signer = new ethers.Wallet('$PRIVATE_KEY', provider);
        const contract = new ethers.Contract('$contract_address', ['function transfer(address recipient, uint256 amount) public returns (bool)'], signer);

        async function send() {
            const amount = ethers.utils.parseUnits('1', 18);  // Kirim 1 token
            const tx = await contract.transfer('$address', amount);
            console.log('Transaksi disiarkan:', tx.hash);
        }
        send();
        "
        sleep 1
    done < "$SCRIPT_DIR/random_send_addresses.txt"
}

# Menjalankan proses di dalam screen
run_in_screen() {
    echo -e "${YELLOW}Menjalankan proses di dalam screen...${RESET}"

    screen -dmS token_deployment bash -c "
        install_dependencies;
        input_required_details;
        generate_random_addresses;
        send_tokens_random;
    "

    echo -e "${GREEN}Proses sedang berjalan di dalam screen dengan nama 'token_deployment'.${RESET}"
    echo -e "${WHITE}Gunakan perintah berikut untuk melihat screen:${RESET}"
    echo -e "${BLUE}screen -r token_deployment${RESET}"
}

# Menu utama
main() {
    install_dependencies
    run_in_screen
}

main
