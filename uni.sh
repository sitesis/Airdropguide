#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
BIRU='\033[1;34m'

tampil() {
    kasus $2 inggih:
        "kesalahan")
            echo -e "${BIRU}${BOLD}❌ $1${NORMAL}"
            ;;
        "progres")
            echo -e "${BIRU}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${BIRU}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || metu

waca -p "Lebokna Private Key sampeyan: " PRIVATE_KEY
waca -p "Lebokna jeneng token (cth., Airdrop Token): " TOKEN_NAME
waca -p "Lebokna simbol token (cth., ADRP): " TOKEN_SYMBOL

mkdir -p "$SCRIPT_DIR/token_deployment"
cat <<EOL > "$SCRIPT_DIR/token_deployment/.env"
PRIVATE_KEY="$PRIVATE_KEY"
TOKEN_NAME="$TOKEN_NAME"
TOKEN_SYMBOL="$TOKEN_SYMBOL"
EOL

sumber "$SCRIPT_DIR/token_deployment/.env"

CONTRACT_NAME="AirdropNode"

yen [ ! -d ".git" ]; banjur
    tampil "Nggawe repositori Git..." "progres"
    git init
fi

yen ora ketemu perintah forge &> /dev/null; banjur
    tampil "Foundry ora diinstal. Nginstal saiki..." "progres"
    sumber <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/Foundry.sh)
fi

yen [ ! -d "$SCRIPT_DIR/lib/openzeppelin-contracts" ]; banjur
    tampil "Nginstal Kontrak OpenZeppelin..." "progres"
    git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git "$SCRIPT_DIR/lib/openzeppelin-contracts"
liyane
    tampil "Kontrak OpenZeppelin wis diinstal."
fi

yen [ ! -f "$SCRIPT_DIR/foundry.toml" ]; banjur
    tampil "Nggawe foundry.toml lan nambah Unichain RPC..." "progres"
    cat <<EOL > "$SCRIPT_DIR/foundry.toml"
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[rpc_endpoints]
unichain = "https://sepolia.unichain.org"
EOL
liyane
    tampil "foundry.toml wis ana."
fi

tampil "Nggawe kontrak token ERC-20 nganggo OpenZeppelin..." "progres"
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

tampil "Menyusun kontrak..." "progres"
forge build

yen [[ $? -ne 0 ]]; banjur
    tampil "Kompilasi kontrak gagal." "kesalahan"
    metu 1
fi

tampil "Ngedum kontrak menyang Unichain..." "progres"
DEPLOY_OUTPUT=$(forge create "$SCRIPT_DIR/src/$CONTRACT_NAME.sol:$CONTRACT_NAME" \
    --rpc-url unichain \
    --private-key "$PRIVATE_KEY")

yen [[ $? -ne 0 ]]; banjur
    tampil "Ngedum gagal." "kesalahan"
    metu 1
fi

CONTRACT_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oP 'Deployed to: \K(0x[a-fA-F0-9]{40})')
tampil "Token sukses diwedum ing alamat: https://sepolia.uniscan.xyz/address/$CONTRACT_ADDRESS"
