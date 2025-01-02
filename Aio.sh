#!/bin/bash

LOG_FILE="/tmp/aios_install.log"
exec > >(tee -i $LOG_FILE) 2>&1

# Fungsi logging
log() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Deteksi distribusi Linux
detect_linux_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        log "ERROR" "Tidak dapat mendeteksi distribusi Linux."
        exit 1
    fi
}

# Update dan instalasi paket dasar
install_prerequisites() {
    local distro=$(detect_linux_distro)
    log "INFO" "Menginstal paket dasar untuk $distro..."

    if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
        sudo apt update && sudo apt install -y curl wget tar
    elif [[ "$distro" == "centos" || "$distro" == "rhel" ]]; then
        sudo yum install -y curl wget tar
    else
        log "ERROR" "Distribusi $distro tidak didukung."
        exit 1
    fi
}

# Instalasi CUDA jika GPU NVIDIA tersedia
install_cuda() {
    log "INFO" "Memeriksa keberadaan GPU NVIDIA..."
    if command -v nvidia-smi &>/dev/null; then
        log "INFO" "GPU NVIDIA terdeteksi. Menginstal CUDA toolkit..."
        local distro=$(detect_linux_distro)
        if [[ "$distro" == "ubuntu" || "$distro" == "debian" ]]; then
            sudo apt install -y nvidia-cuda-toolkit
        elif [[ "$distro" == "centos" || "$distro" == "rhel" ]]; then
            sudo yum install -y nvidia-cuda-toolkit
        fi
    else
        log "WARN" "GPU NVIDIA tidak terdeteksi. Melewatkan instalasi CUDA."
    fi
}

# Mendapatkan URL untuk aios-cli
get_aios_cli_url() {
    local base_url="https://github.com/aios-labs/aios-cli/releases/latest/download"
    echo "$base_url/aios-cli-linux-amd64.tar.gz"
}

# Unduh dan instalasi aios-cli
install_aios_cli() {
    local url=$(get_aios_cli_url)
    local filename="aios-cli.tar.gz"

    log "INFO" "Mengunduh aios-cli dari $url..."
    curl -L -o "$filename" "$url" || { log "ERROR" "Gagal mengunduh aios-cli."; exit 1; }

    log "INFO" "Ekstrak dan instal aios-cli..."
    tar -xzf "$filename"
    sudo mv aios-cli /usr/local/bin/ || { log "ERROR" "Gagal memindahkan aios-cli ke /usr/local/bin."; exit 1; }
    rm -f "$filename"

    log "SUCCESS" "aios-cli berhasil diinstal."
}

# Menjalankan fungsi utama
main() {
    log "INFO" "Memulai instalasi di Linux VPS..."
    install_prerequisites
    install_cuda
    install_aios_cli
    log "SUCCESS" "Instalasi selesai. Anda dapat menggunakan 'aios-cli' sekarang."
}

main
