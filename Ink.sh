#!/bin/bash

# Skrip instalasi logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Update dan upgrade sistem
echo "Memperbarui dan meng-upgrade sistem..."
sudo apt update && sudo apt upgrade -y

# Periksa dan install jq jika belum terpasang
if ! command -v jq &> /dev/null; then
    echo "jq tidak terpasang. Menginstall jq..."
    sudo apt install jq -y
fi

# Periksa dan install Docker serta Docker Compose jika belum terpasang
if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
    echo "Docker atau Docker Compose tidak terpasang. Harap instalasi sebelum menjalankan skrip ini."
    exit 1
fi

# Clone repositori Git Ink
echo "Meng-clone repositori Git Ink..."
if git clone https://github.com/inkonchain/node; then
    echo "Repositori berhasil di-clone."
else
    echo "Gagal meng-clone repositori. Pastikan URL benar dan koneksi internet stabil."
    exit 1
fi

# Masuk ke direktori Ink
if cd node; then
    echo "Berpindah ke direktori Ink."
else
    echo "Direktori Ink tidak ditemukan. Gagal masuk ke direktori."
    exit 1
fi

# Buat file .env dan tambahkan konfigurasi
echo "Membuat file .env dengan variabel lingkungan yang diperlukan..."
cat <<EOL > .env
L1_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
L1_BEACON_URL=https://ethereum-sepolia-beacon-api.publicnode.com
EOL
echo "File .env berhasil dibuat."

# Jalankan skrip setup
if [ -f "./setup.sh" ]; then
    echo "Menjalankan skrip setup..."
    ./setup.sh
    echo "Skrip setup berhasil dijalankan."
else
    echo "Skrip setup.sh tidak ditemukan. Pastikan skrip ini ada di direktori."
    exit 1
fi

# Tampilkan kunci pribadi untuk disimpan
if [ -f "var/secrets/jwt.txt" ]; then
    echo "Menyimpan kunci pribadi Anda dengan aman..."
    cp var/secrets/jwt.txt ~/jwt_backup.txt
    echo "Kunci pribadi disimpan ke ~/jwt_backup.txt. Pastikan Anda menyimpannya dengan aman."
else
    echo "File kunci pribadi var/secrets/jwt.txt tidak ditemukan."
fi

# Mulai node dengan Docker Compose
if [ -f "docker-compose.yml" ]; then
    echo "Memulai node dengan Docker Compose..."
    docker compose up -d
    echo "Node berhasil dijalankan."
else
    echo "File docker-compose.yml tidak ditemukan. Pastikan Docker Compose telah dikonfigurasi dengan benar."
    exit 1
fi

# Verifikasi status sinkronisasi
echo "Memverifikasi status sinkronisasi..."
sync_status=$(curl -X POST -H "Content-Type: application/json" --data \
    '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
    http://localhost:9545 | jq)

echo "Status sinkronisasi: $sync_status"

# Ambil dan bandingkan nomor blok yang difinalisasi secara lokal dan jarak jauh
echo "Mengambil nomor blok finalisasi terbaru dari node lokal dan RPC jarak jauh..."

local_block=$(curl -s -X POST http://localhost:8545 -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized", false],"id":1}' \
  | jq -r .result.number | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')

remote_block=$(curl -s -X POST https://rpc-gel-sepolia.inkonchain.com/ -H "Content-Type: application/json" \
 --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["finalized", false],"id":1}' \
 | jq -r .result.number | sed 's/^0x//' | awk '{printf "%d\n", "0x" $0}')

echo "Blok finalisasi lokal: $local_block"
echo "Blok finalisasi jarak jauh: $remote_block"

# Bandingkan blok dan tampilkan hasilnya
if [ "$local_block" -eq "$remote_block" ]; then
    echo "Node lokal Anda sinkron dengan RPC jarak jauh."
else
    echo "Node lokal Anda tidak sinkron dengan RPC jarak jauh."
    echo "Blok lokal pada $local_block, sedangkan blok jarak jauh pada $remote_block."
fi

echo "Instalasi, setup, dan verifikasi selesai."
echo -e "\n👉 **[Join Airdrop Node](https://t.me/airdrop_node)** 👈"

