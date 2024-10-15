#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
BLUE='\033[1;34m'  # Mengganti warna PINK menjadi BIRU

tampil() {
    case $2 in
        "error")
            echo -e "${BLUE}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${BLUE}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${BLUE}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit

read -p "Lebokno Private Key panjenengan: " PRIVATE_KEY
read -p "Lebokno jeneng token (cth: Airdrop Token): " TOKEN_NAME
read -p "Lebokno simbol token (cth: AIR): " TOKEN_SYMBOL

mkdir -p "$SCRIPT_DIR/token_deployment"
cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
EOL

source "$SCRIPT_DIR/token_deployment/.env"

CONTRACT_NAME="Airdrop"

if [ ! -d ".git" ]; then
    tampil "Nyiapno repositori Git..." "progress"
    git init
fi

if ! command -v forge &> /dev/null; then
    tampil "Foundry durung diinstal. Lagi diinstal..." "progress"
    source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh)
fi

if [ ! -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; then
    tampil "Nginstal OpenZeppelin Contracts..." "progress"
    git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
else
    tampil "OpenZeppelin Contracts wis diinstal."
fi

if [ ! -f "$SCRIPT_DIR/foundry.toml" ]; then
    tampil "Ngawe foundry.toml lan nambah Unichain RPC..." "progress"
    cat <<EOL > "$SCRIPT_DIR/foundry.toml"
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
unichain = "https://sepolia.unichain.org"
EOL
else
    tampil "foundry.toml wis ana."
fi

tampil "Ngawe kontrak token ERC-20 nganggo OpenZeppelin..." "progress"
mkdir -p "$SCRIPT_DIR/src"
cat <<EOL > "$SCRIPT_DIR/src/$CONTRACT_NAME.sol"
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract $CONTRACT_NAME is ERC20 {
    constructor() ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, 100000 * (10 ** decimals()));
    }
}
EOL

tampil "Ngkompilasi kontrak..." "progress"
forge build

if [[ $? -ne 0 ]]; then
    tampil "Kompilasi kontrak gagal." "error"
    exit 1
fi

tampil "Nggolek kontrak ing Unichain..." "progress"
DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/$CONTRACT_NAME.sol:$CONTRACT_NAME" \
    --rpc-url unichain \
    --private-key "$PRIVATE_KEY")

if [[ $? -ne 0 ]]; then
    tampil "Deploy gagal." "error"
    exit 1
fi

CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
tampil "Token sukses ditransfer ing alamat: https://sepolia.uniscan.xyz/address/$CONTRACT_ADDRESS"
