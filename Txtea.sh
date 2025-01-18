#!/bin/bash

# Definisi warna untuk output terminal
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

# URL RPC dan alamat kontrak token
RPC_URL="https://assam-rpc.tea.xyz/"
TOKEN_ADDRESS="0x8c8aE3254285621E85513d92149373F89a74e918"

# Meminta pengguna untuk memasukkan private key pengirim
echo -e "${YELLOW}Masukkan Private Key Pengirim:${RESET}"
read -s SENDER_PRIVATE_KEY  # -s untuk menyembunyikan input private key

# File tempat menyimpan alamat
ADDRESS_FILE="random_send_addresses.txt"

# ABI Token Contract (disesuaikan dengan yang Anda berikan)
TOKEN_ABI='[
  {"inputs":[],"stateMutability":"nonpayable","type":"constructor"},
  {"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"allowance","type":"uint256"},{"internalType":"uint256","name":"needed","type":"uint256"}],"name":"ERC20InsufficientAllowance","type":"error"},
  {"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"balance","type":"uint256"},{"internalType":"uint256","name":"needed","type":"uint256"}],"name":"ERC20InsufficientBalance","type":"error"},
  {"inputs":[{"internalType":"address","name":"approver","type":"address"}],"name":"ERC20InvalidApprover","type":"error"},
  {"inputs":[{"internalType":"address","name":"receiver","type":"address"}],"name":"ERC20InvalidReceiver","type":"error"},
  {"inputs":[{"internalType":"address","name":"sender","type":"address"}],"name":"ERC20InvalidSender","type":"error"},
  {"inputs":[{"internalType":"address","name":"spender","type":"address"}],"name":"ERC20InvalidSpender","type":"error"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},
  {"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},
  {"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"mint","outputs":[],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},
  {"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"}
]'

# Jumlah token yang ingin dikirim (misal 1 token)
AMOUNT_TO_SEND="1000000000000000000"  # 1 token dengan 18 desimal

# Fungsi untuk memeriksa dependensi
check_dependencies() {
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}Node.js tidak ditemukan, silakan instal terlebih dahulu.${RESET}"
        exit 1
    fi

    if ! npm list -g ethers &> /dev/null; then
        echo -e "${YELLOW}Ethers.js tidak terinstal, menginstal ethers.js...${RESET}"
        npm install -g ethers
    fi
}

# Fungsi untuk menghasilkan 1000 alamat acak
generate_random_addresses() {
    echo -e "${YELLOW}Menghasilkan 1000 alamat acak untuk pengiriman...${RESET}"
    
    # Generate 1000 alamat acak untuk pengiriman
    node -e "
    const { ethers } = require('ethers');
    for (let i = 0; i < 1000; i++) {
        const wallet = ethers.Wallet.createRandom();
        console.log(wallet.address);
    }
    " > "$ADDRESS_FILE"

    echo -e "${GREEN}Alamat acak telah disimpan ke $ADDRESS_FILE${RESET}"
}

# Fungsi untuk mengirim token ke semua alamat yang dihasilkan
send_tokens() {
    echo -e "${YELLOW}Mengirim token ke alamat-alamat yang dihasilkan...${RESET}"

    # Membaca alamat dari file dan mengirim token
    node <<EOF
const { ethers } = require("ethers");

const rpcUrl = "$RPC_URL";
const tokenAddress = "$TOKEN_ADDRESS";
const senderPrivateKey = "$SENDER_PRIVATE_KEY";
const recipientAddresses = require("fs").readFileSync("$ADDRESS_FILE", "utf-8").split("\n").filter(Boolean);

const tokenABI = $TOKEN_ABI;
const provider = new ethers.JsonRpcProvider(rpcUrl);
const wallet = new ethers.Wallet(senderPrivateKey, provider);
const tokenContract = new ethers.Contract(tokenAddress, tokenABI, wallet);

const amountToSend = ethers.utils.parseUnits("$AMOUNT_TO_SEND", 18);

async function sendTokens() {
  for (let i = 0; i < recipientAddresses.length; i++) {
    const recipient = recipientAddresses[i];
    try {
      const tx = await tokenContract.transfer(recipient, amountToSend);
      console.log(\`Transaksi terkirim ke \${recipient}: \${tx.hash}\`);
      await tx.wait();
      console.log(\`Transaksi sukses ke \${recipient}\`);
    } catch (error) {
      console.error(\`Gagal kirim ke \${recipient}: \${error.message}\`);
    }
  }
}

sendTokens();
EOF
}

# Memeriksa dependensi terlebih dahulu
check_dependencies

# Menjalankan fungsi untuk menghasilkan alamat dan mengirim token
generate_random_addresses
send_tokens
