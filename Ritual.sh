#!/bin/bash

# Memeriksa apakah skrip dijalankan sebagai pengguna root
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini memerlukan hak akses root."
    echo "Silakan coba menggunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan skrip ini lagi."
    exit 1
fi

# Jalur penyimpanan skrip
SCRIPT_PATH="$HOME/Ritual.sh"

# Fungsi untuk meminta input pengguna dan validasi
function prompt_input() {
    local prompt_message=$1
    local variable_name=$2
    local regex=$3

    while true; do
        read -p "$prompt_message" input_value
        if [[ $input_value =~ $regex ]]; then
            eval "$variable_name=\"$input_value\""
            break
        else
            echo "Input tidak valid. Silakan coba lagi."
        fi
    done
}

# Fungsi instalasi node
function install_node() {
    # Meminta pengguna memasukkan private_key dan melakukan validasi
    prompt_input "Masukkan private key EVM wallet (0x...): " private_key "^(0x)[0-9a-fA-F]{40}$"
    prompt_input "Masukkan alamat wallet yang sesuai (0x...): " wallet_address "^(0x)[0-9a-fA-F]{40}$"
    prompt_input "Masukkan RPC, harus menggunakan Base chain: " rpc_address "^https?://.+"
    prompt_input "Masukkan port: " port1 "^[0-9]+$"

    # Memperbarui daftar paket sistem
    echo "Memperbarui daftar paket sistem..."
    sudo apt update

    # Memeriksa apakah Git telah diinstal
    if ! command -v git &> /dev/null; then
        echo "Git tidak terdeteksi, sedang menginstal..."
        sudo apt install git -y || { echo "Instalasi Git gagal."; exit 1; }
    else
        echo "Git telah terinstal."
    fi

    # Mengkloning repositori ritual-net
    git clone https://github.com/ritual-net/infernet-node || { echo "Gagal mengkloning repositori."; exit 1; }
    cd infernet-node || { echo "Gagal masuk ke direktori infernet-node."; exit 1; }

    # Menetapkan tag dan membangun gambar Docker
    tag="v1.0.0"
    echo "Membangun gambar Docker..."
    docker build -t ritualnetwork/infernet-node:$tag . || { echo "Gagal membangun gambar Docker."; exit 1; }

    # Masuk ke direktori deploy
    cd deploy || { echo "Gagal masuk ke direktori deploy."; exit 1; }

    # Menggunakan perintah cat untuk menulis konfigurasi ke config.json
    cat > config.json <<EOF
{
  "log_path": "infernet_node.log",
  "manage_containers": true,
  "server": {
    "port": $port1,
    "rate_limit": {
      "num_requests": 100,
      "period": 100
    }
  },
  "chain": {
    "enabled": true,
    "trail_head_blocks": 3,
    "rpc_url": "$rpc_address",
    "registry_address": "0xe2F36C4E23D67F81fE0B278E80ee85Cf0ccA3c8d",
    "wallet": {
      "max_gas_limit": 5000000,
      "private_key": "$private_key",
      "payment_address": "$wallet_address",
      "allowed_sim_errors": ["not enough balance"]
    },
    "snapshot_sync": {
      "sleep": 3,
      "starting_sub_id": 160000,
      "batch_size": 800,
      "sync_period": 30
    }
  },
  "redis": {
    "host": "redis",
    "port": 6379
  },
  "forward_stats": true,
  "startup_wait": 1.0,
  "containers": [
    {
      "id": "hello-world",
      "image": "ritualnetwork/hello-world-infernet:latest",
      "external": true,
      "port": "3000",
      "allowed_delegate_addresses": [],
      "allowed_addresses": [],
      "allowed_ips": [],
      "command": "--bind=0.0.0.0:3000 --workers=2",
      "env": {},
      "volumes": [],
      "accepted_payments": {
        "0x0000000000000000000000000000000000000000": 1000000000000000000,
        "0x59F2f1fCfE2474fD5F0b9BA1E73ca90b143Eb8d0": 1000000000000000000
      },
      "generates_proofs": false
    }
  ]
}
EOF

    echo "File konfigurasi telah disiapkan."

    # Menginstal komponen dasar
    echo "Menginstal komponen dasar..."
    sudo apt install pkg-config curl build-essential libssl-dev libclang-dev -y || { echo "Gagal menginstal komponen dasar."; exit 1; }

    # Memeriksa apakah Docker telah diinstal
    if ! command -v docker &> /dev/null; then
        echo "Docker tidak terdeteksi, sedang menginstal..."
        sudo apt-get install ca-certificates curl gnupg lsb-release

        # Menambahkan kunci GPG resmi Docker
        sudo mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # Mengatur repositori Docker
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        # Memberikan izin pada file Docker
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        sudo apt-get update

        # Menginstal versi terbaru Docker
        sudo apt-get install docker-ce docker-ce-cli containerd.io -y || { echo "Gagal menginstal Docker."; exit 1; }
        
        # Menginstal Docker Compose
        DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
        mkdir -p $DOCKER_CONFIG/cli-plugins
        curl -SL https://github.com/docker/compose/releases/download/v2.25.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
        sudo chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
        docker compose version
    else
        echo "Docker telah terinstal."
    fi

    # Menjalankan kontainer
    echo "Menjalankan kontainer..."
    docker compose up -d || { echo "Gagal menjalankan kontainer."; exit 1; }

    echo "========================= Instalasi Selesai ==============================="
    echo "Silakan gunakan cd infernet-node/deploy untuk masuk ke direktori dan kemudian gunakan docker compose logs -f untuk memeriksa log."
}

# Memeriksa log node
function check_service_status() {
    cd infernet-node/deploy || { echo "Gagal masuk ke direktori deploy."; exit 1; }
    docker compose logs -f
}

# Menu utama
function main_menu() {
    clear
    echo "Silakan pilih tindakan yang ingin dilakukan:"
    echo "1. Instal node"
    echo "2. Lihat log node"
    read -p "Masukkan pilihan (1-2): " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    *) echo "Pilihan tidak valid." ;;
    esac
}

# Menampilkan menu utama
main_menu
