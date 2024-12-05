#!/bin/bash

# Dapatkan IP Publik VPS
IP_VPS=$(curl -s ifconfig.me)

# Memastikan IP ditemukan
if [ -z "$IP_VPS" ]; then
  echo "Gagal mendapatkan IP VPS. Pastikan VPS dapat mengakses internet."
  exit 1
fi

echo "IP VPS Anda adalah: $IP_VPS"

# Langkah 1: Memperbarui sistem
echo "Memperbarui sistem..."
sudo apt update && sudo apt upgrade -y

# Langkah 2: Install Docker
if ! command -v docker &> /dev/null
then
    echo "Docker tidak ditemukan. Menginstall Docker..."
    sudo apt install docker.io -y
    sudo systemctl enable --now docker
else
    echo "Docker sudah terpasang."
fi

# Langkah 3: Install Docker Compose
if ! command -v docker-compose &> /dev/null
then
    echo "Docker Compose tidak ditemukan. Menginstall Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose sudah terpasang."
fi

# Langkah 4: Meminta alamat Ethereum pengguna
echo "Masukkan alamat Ethereum Anda (contoh: 0x1234567890abcdef...):"
read ETH_ADDRESS

# Langkah 5: Meminta nama validator
echo "Masukkan nama validator Anda:"
read VALIDATOR_NAME

# Langkah 6: Tentukan folder data chain
CHAIN_DATA_DIR=~/zenchain

# Membuat folder jika belum ada
echo "Membuat folder untuk data chain..."
mkdir -p $CHAIN_DATA_DIR

# Memastikan bahwa folder memiliki izin yang tepat
echo "Memastikan folder memiliki izin yang benar..."
chmod 755 $CHAIN_DATA_DIR
chown $USER:$USER $CHAIN_DATA_DIR

# Langkah 7: Membuat file docker-compose.yml untuk ZenChain
echo "Membuat file docker-compose.yml..."

cat > $CHAIN_DATA_DIR/docker-compose.yml <<EOL
version: '3'

services:
  zenchain:
    image: ghcr.io/zenchain-protocol/zenchain-testnet:latest
    platform: linux/amd64
    container_name: zenchain
    ports:
      - "$IP_VPS:9944:9944"  # Menggunakan IP VPS otomatis
    volumes:
      - $CHAIN_DATA_DIR:/chain-data
    command:
      - "./usr/bin/zenchain-node"
      - "--base-path=/chain-data"
      - "--rpc-cors=all"
      - "--validator"
      - "--name=$VALIDATOR_NAME"  # Nama validator yang dimasukkan
      - "--bootnodes=/dns4/node-7242611732906999808-0.p2p.onfinality.io/tcp/26266/p2p/12D3KooWLAH3GejHmmchsvJpwDYkvacrBeAQbJrip5oZSymx5yrE"
      - "--chain=zenchain_testnet"
EOL

echo "File docker-compose.yml telah dibuat dengan IP VPS Anda dan nama validator $VALIDATOR_NAME."

# Langkah 8: Memasuki direktori yang sesuai dan menjalankan Docker Compose
echo "Memasuki direktori ZenChain dan menjalankan Docker Compose..."
cd $CHAIN_DATA_DIR || { echo "Gagal mengakses direktori $CHAIN_DATA_DIR"; exit 1; }

# Menjalankan Docker Compose untuk memulai ZenChain Node
docker-compose up -d

# Langkah 9: Memanggil RPC untuk rotateSessionKey
echo "Mengonfigurasi kunci sesi untuk node..."

SESSION_KEY=$(curl -s -X POST --data '{"jsonrpc":"2.0","id":1,"method":"author_rotateKeys","params":[]}' http://$IP_VPS:9944)

echo "Kunci sesi baru telah digenerate. Output kunci sesi: $SESSION_KEY"

# Langkah 10: Kirimkan transaksi untuk mengaitkan kunci sesi dengan akun Ethereum
echo "Mengirim transaksi untuk mengaitkan kunci sesi dengan akun Ethereum..."

TRANSACTION_OUTPUT=$(curl -s -X POST --data '{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "author_submitExtrinsic",
  "params": [
    {
      "method": "setKeys",
      "params": [
        "$SESSION_KEY",
        "$ETH_ADDRESS"
      ]
    }
  ]
}' http://$IP_VPS:9944)

echo "Transaksi untuk setKeys telah dikirim. Output transaksi: $TRANSACTION_OUTPUT"

# Langkah 11: Restart node tanpa unsafe-rpc-external
echo "Menonaktifkan --unsafe-rpc-external dan memulai ulang node..."

docker-compose down
docker-compose up -d

echo "Node telah dimulai ulang dengan konfigurasi yang aman."

# Langkah 12: Verifikasi Node
echo "Memverifikasi apakah ZenChain Node sudah berjalan..."
docker logs zenchain
