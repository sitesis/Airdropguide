#!/bin/bash

# Fungsi untuk memeriksa dan memasang Docker
install_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker tidak ditemukan. Memasang Docker..."
        
        # Memasang Docker di Ubuntu
        sudo apt-get update
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            software-properties-common

        # Menambahkan kunci GPG resmi Docker
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

        # Menambahkan repositori Docker
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

        # Memasang Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce
    else
        echo "Docker sudah terinstal."
    fi
}

# Fungsi untuk menarik gambar Docker Celo
pull_celo_image() {
    export CELO_IMAGE=us.gcr.io/celo-org/geth:alfajores
    echo "Variabel lingkungan CELO_IMAGE telah disetel: $CELO_IMAGE"

    echo "Menarik gambar Docker Celo..."
    docker pull $CELO_IMAGE
}

# Fungsi untuk membuat direktori data
create_data_directory() {
    mkdir -p celo-data-dir
    cd celo-data-dir || exit
    echo "Direktori 'celo-data-dir' telah dibuat dan berpindah ke direktori tersebut."
}

# Fungsi untuk membuat akun baru dan mendapatkan alamatnya
create_account() {
    echo "Membuat akun baru Celo..."
    CELO_ACCOUNT_ADDRESS=$(docker run -v $PWD:/root/.celo --rm -it $CELO_IMAGE account new | grep -oE '0x[a-fA-F0-9]{40}')

    # Memastikan alamat akun disetel
    if [ -z "$CELO_ACCOUNT_ADDRESS" ]; then
        echo "Gagal membuat akun baru. Skrip akan dihentikan."
        exit 1
    fi
    echo "Akun baru telah dibuat. Alamat akun: $CELO_ACCOUNT_ADDRESS"
}

# Fungsi untuk memulai node Celo
start_node() {
    echo "Memulai node Celo..."
    docker run --name celo-fullnode -d --restart unless-stopped --stop-timeout 300 \
        -p 127.0.0.1:8545:8545 \
        -p 127.0.0.1:8546:8546 \
        -p 30303:30303 \
        -p 30303:30303/udp \
        -v $PWD:/root/.celo \
        $CELO_IMAGE --verbosity 3 --syncmode full \
        --http --http.addr 0.0.0.0 --http.api eth,net,web3,debug,admin,personal \
        --light.serve 90 --light.maxpeers 1000 --maxpeers 1100 \
        --etherbase $CELO_ACCOUNT_ADDRESS --alfajores --datadir /root/.celo
}

# Fungsi utama untuk menjalankan semua langkah
main() {
    install_docker
    pull_celo_image
    create_data_directory
    create_account
    start_node

    
}

# Menjalankan fungsi utama
main
