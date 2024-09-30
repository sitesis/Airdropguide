#!/bin/bash

# Nama proyek
PROJECT_NAME="SonicTokenDeploy"
TOKEN_NAME="soniclabs"
TOKEN_SYMBOL="SON"
INITIAL_SUPPLY="1000000" # Jumlah awal token

# Fungsi untuk memeriksa dan menginstal Node.js dan npm
install_node() {
    if ! command -v node &> /dev/null; then
        echo "Node.js tidak terinstal. Menginstal Node.js..."
        
        # Menginstal Node.js dan npm
        if [ "$(uname)" == "Darwin" ]; then
            # MacOS
            brew install node
        elif [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            sudo apt update
            sudo apt install -y nodejs npm
        elif [ -f /etc/redhat-release ]; then
            # RHEL/CentOS
            sudo yum install -y nodejs npm
        else
            echo "Sistem operasi tidak dikenali. Silakan instal Node.js dan npm secara manual."
            exit 1
        fi
    else
        echo "Node.js sudah terinstal."
    fi
}

# Memeriksa dan menginstal Node.js dan npm
install_node

# Membuat direktori proyek
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Inisialisasi proyek Node.js
npm init -y

# Instalasi Hardhat dan OpenZeppelin
npm install --save-dev hardhat
npm install @openzeppelin/contracts

# Membuat file konfigurasi Hardhat
cat <<EOL > hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");

// Ganti dengan private key akun Sonic kamu
const SONIC_PRIVATE_KEY = "YOUR SONIC TEST ACCOUNT PRIVATE KEY";

module.exports = {
  solidity: "0.8.19",
  networks: {
    sonic: {
      url: "https://rpc.testnet.soniclabs.com",
      accounts: [SONIC_PRIVATE_KEY],
    },
  },
};
EOL

# Membuat kontrak token ERC20
mkdir -p contracts
cat <<EOL > contracts/$TOKEN_NAME.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract $TOKEN_NAME is ERC20 {
    constructor(uint256 initialSupply) ERC20("$TOKEN_NAME", "$TOKEN_SYMBOL") {
        _mint(msg.sender, initialSupply);
    }
}
EOL

# Membuat script deploy
mkdir -p scripts
cat <<EOL > scripts/deploy.js
const hre = require("hardhat");

async function main() {
    const initialSupply = hre.ethers.utils.parseUnits("$INITIAL_SUPPLY", 18); // 1 juta token
    const Token = await hre.ethers.getContractFactory("$TOKEN_NAME");
    const token = await Token.deploy(initialSupply);

    await token.deployed();
    console.log("Token deployed to:", token.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
EOL

# Membuat file .gitignore
cat <<EOL > .gitignore
node_modules/
artifacts/
cache/
.env
EOL

# Menjalankan deploy
echo "Instalasi dependensi dan deploy kontrak..."
npx hardhat run scripts/deploy.js --network sonic
