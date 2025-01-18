#!/bin/bash

# URL RPC dan alamat kontrak token
RPC_URL="https://assam-rpc.tea.xyz/"
TOKEN_ADDRESS="0x8c8aE3254285621E85513d92149373F89a74e918"

# File tempat menyimpan alamat
ADDRESS_FILE="random_addresses.txt"

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

# Meminta input private key dari pengguna
echo "Masukkan private key pengirim:"
read -s SENDER_PRIVATE_KEY

# Fungsi untuk menghasilkan 1000 alamat acak
generate_random_addresses() {
  echo "Menghasilkan 1000 alamat acak..."
  for i in $(seq 1 1000); do
    # Menghasilkan alamat acak menggunakan openssl dan keccak-256
    ADDRESS=$(openssl rand -hex 32 | keccak-256sum | head -n 1 | awk '{print "0x" substr($1, 1, 40)}')
    echo $ADDRESS >> $ADDRESS_FILE
  done
  echo "Alamat acak telah disimpan di $ADDRESS_FILE."
}

# Fungsi untuk mengirim token ke semua alamat yang dihasilkan
send_tokens() {
  echo "Mengirim token ke alamat-alamat..."

  # Memeriksa dan menginstal dependensi jika belum ada
  if ! command -v node &> /dev/null; then
    echo "Node.js tidak ditemukan, menginstal Node.js..."
    sudo apt update
    sudo apt install -y nodejs npm
  fi

  if ! npm list -g ethers &> /dev/null; then
    echo "Ethers.js belum terinstal, menginstal ethers.js..."
    npm install ethers
  fi

  # Menggunakan ethers.js untuk mengirim token (panggil node JS dari bash)
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

# Langsung menjalankan proses generate alamat dan kirim token
generate_random_addresses
send_tokens
