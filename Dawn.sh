#!/bin/bash 

# Lokasi penyimpanan skrip dan log
SCRIPT_PATH="$HOME/Dawn.sh"
DAWN_DIR="$HOME/Dawn"
LOG_FILE="$HOME/Dawn_install.log"

# Fungsi logging
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Periksa apakah skrip dijalankan sebagai pengguna root
if [ "$(id -u)" != "0" ]; then
    log "Skrip ini perlu dijalankan dengan hak akses root."
    echo "Cobalah menggunakan perintah 'sudo -i' untuk beralih ke pengguna root, lalu jalankan kembali skrip ini."
    exit 1
fi

# Fungsi untuk menginstal Python 3.11
install_python() {
    log "Memasang Python 3.11..."
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip libopencv-dev python3-opencv
    python3.11 -m pip install --upgrade pip
    log "Python 3.11 dan pip berhasil dipasang."
}

# Fungsi untuk memeriksa apakah Python 3.11 sudah terpasang
check_python_installed() {
    if command -v python3.11 &>/dev/null; then
        log "Python 3.11 sudah terpasang."
    else
        log "Python 3.11 belum terpasang. Memasang sekarang..."
        install_python
    fi
}

# Fungsi utama pemasangan dan konfigurasi
install_and_configure() {
    check_python_installed

    log "Memperbarui daftar paket dan memasang git dan tmux..."
    sudo apt update
    sudo apt install -y git tmux python3.11-venv libgl1-mesa-glx libglib2.0-0 libsm6 libxext6 libxrender-dev

    if [ -d "$DAWN_DIR" ]; then
        log "Direktori Dawn sudah ada, sedang menghapus..."
        rm -rf "$DAWN_DIR"
        log "Direktori Dawn telah dihapus."
    fi

    log "Mengkloning repository dari GitHub..."
    if git clone https://github.com/sdohuajia/Dawn-py.git "$DAWN_DIR"; then
        log "Repository berhasil dikloning."
    else
        log "Cloning gagal, periksa koneksi jaringan atau alamat repository."
        exit 1
    fi

    cd "$DAWN_DIR" || { log "Tidak dapat masuk ke direktori Dawn"; exit 1; }

    log "Membuat dan mengaktifkan virtual environment..."
    python3.11 -m venv venv
    source "$DAWN_DIR/venv/bin/activate"

    log "Memasang paket Python yang dibutuhkan..."
    if [ -f requirements.txt ]; then
        pip install -r requirements.txt && pip install httpx
        log "Dependensi Python berhasil dipasang."
    else
        log "File requirements.txt tidak ditemukan, tidak dapat memasang dependensi."
        exit 1
    fi

    read -p "Masukkan email dan password Anda, format email:password: " email_password
    echo "$email_password" > "$DAWN_DIR/config/data/farm.txt"
    log "Email dan password ditambahkan ke farm.txt."

    read -p "Masukkan informasi proxy Anda, format (http://user:pass@ip:port): " proxy_info
    echo "$proxy_info" > "$DAWN_DIR/config/data/proxies.txt"
    log "Informasi proxy ditambahkan ke proxies.txt."

    log "Menjalankan skrip python3.11 run.py di sesi tmux..."
    tmux new-session -d -s dawn
    tmux send-keys -t dawn "cd $DAWN_DIR" C-m
    tmux send-keys -t dawn "source \"$DAWN_DIR/venv/bin/activate\"" C-m
    tmux send-keys -t dawn "python3.11 run.py" C-m

    log "Sesi tmux 'dawn' dibuat dan skrip Python dijalankan."
    echo "Gunakan perintah 'tmux attach -t dawn' untuk melihat log."
    echo "Untuk keluar dari sesi tmux, tekan Ctrl+B lalu tekan D."
    log "Instalasi dan konfigurasi selesai."
}

# Jalankan fungsi utama
install_and_configure
