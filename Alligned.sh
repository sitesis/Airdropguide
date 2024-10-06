#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash

sleep 4

set -e  # Keluar segera jika ada perintah yang keluar dengan status non-nol

# Fungsi untuk menginstal ketergantungan sistem yang diperlukan untuk Rust dan Foundry
install_dependencies() {
    echo "Menginstal ketergantungan sistem yang diperlukan untuk Rust dan Foundry..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y build-essential pkg-config libssl-dev curl || { echo "Gagal menginstal ketergantungan."; exit 1; }
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl || { echo "Gagal menginstal ketergantungan."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl || { echo "Gagal menginstal ketergantungan."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu base-devel openssl curl || { echo "Gagal menginstal ketergantungan."; exit 1; }
    else
        echo "Pengelola paket tidak didukung. Silakan instal ketergantungan secara manual."
        exit 1
    fi
}

# Instal ketergantungan sistem
install_dependencies

# Langkah 1: Instal Rust menggunakan rustup
if command -v rustup &> /dev/null; then
    echo "Rust sudah terinstal."
    read -p "Apakah Anda ingin menginstal ulang atau memperbarui Rust? (r untuk menginstal ulang, u untuk memperbarui, n untuk melewatkan): " choice
    case "$choice" in
        r)
            echo "Menginstal ulang Rust..."
            rustup self uninstall -y
            ;;
        u)
            echo "Memperbarui Rust..."
            rustup update
            ;;
        *)
            echo "Melewatkan instalasi Rust."
            ;;
    esac
else
    echo "Menginstal Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Muat variabel lingkungan Rust
export RUSTUP_HOME="$HOME/.rustup"
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# Perbaiki izin untuk direktori Rust
chmod -R 755 "$RUSTUP_HOME"
chmod -R 755 "$CARGO_HOME"
chown -R $(whoami) "$RUSTUP_HOME" "$CARGO_HOME"

# Verifikasi versi Rust dan Cargo
rust_version=$(rustc --version)
cargo_version=$(cargo --version)

echo "Versi Rust: $rust_version"
echo "Versi Cargo: $cargo_version"

# Tambahkan variabel lingkungan Rust ke .bashrc atau .zshrc
if [[ $SHELL == *"zsh"* ]]; then
    PROFILE="$HOME/.zshrc"
else
    PROFILE="$HOME/.bashrc"
fi

if ! grep -q 'CARGO_HOME' "$PROFILE"; then
    echo 'export RUSTUP_HOME="$HOME/.rustup"' >> "$PROFILE"
    echo 'export CARGO_HOME="$HOME/.cargo"' >> "$PROFILE"
    echo 'export PATH="$CARGO_HOME/bin:$PATH"' >> "$PROFILE"
    echo 'source "$HOME/.cargo/env"' >> "$PROFILE"
    echo "Menambahkan variabel lingkungan Rust ke $PROFILE. Silakan restart terminal Anda atau jalankan 'source $PROFILE' agar perubahan berlaku."
fi

# Sumber profil untuk sesi saat ini
source "$PROFILE"

# Langkah 2: Instal Foundry menggunakan foundryup
echo "Menginstal Foundry..."
if ! command -v curl &> /dev/null; then
    echo "curl tidak terinstal. Silakan instal curl secara manual."
    exit 1
fi

curl -L https://foundry.paradigm.xyz | bash

# Perbarui PATH untuk Foundry
if ! grep -q 'export PATH="$HOME/.foundry/bin:$PATH"' "$PROFILE"; then
    echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$PROFILE"
    echo "Menambahkan variabel lingkungan Foundry ke $PROFILE. Silakan restart terminal Anda atau jalankan 'source $PROFILE' agar perubahan berlaku."
fi

# Sumber profil untuk sesi saat ini
source "$PROFILE"

# Verifikasi instalasi Foundry
if foundryup; then
    echo "Instalasi Foundry berhasil!"
else
    echo "Instalasi Foundry gagal."
    exit 1
fi

# Verifikasi alat Foundry
if command -v forge &> /dev/null && command -v cast &> /dev/null && command -v anvil &> /dev/null; then
    echo "Alat Foundry (forge, cast, anvil) telah terinstal dan tersedia!"
else
    echo "Alat Foundry tidak dikenali. Silakan periksa instalasi Anda."
    exit 1
fi

# Langkah 3: Atur keystore yang selaras
echo "Mengatur keystore yang selaras..."
[ -d ~/.aligned_keystore ] && rm -rf ~/.aligned_keystore && echo "Menghapus direktori yang ada ~/.aligned_keystore."
mkdir -p ~/.aligned_keystore
cast wallet import ~/.aligned_keystore/keystore0 --interactive

# Langkah 4: Klon repositori aligned_layer dan navigasikan ke contoh zkquiz
echo "Mengatur aligned_layer..."
[ -d aligned_layer ] && rm -rf aligned_layer && echo "Menghapus direktori aligned_layer yang ada."
git clone https://github.com/yetanotherco/aligned_layer.git
cd aligned_layer/examples/zkquiz || { echo "Gagal menavigasi ke aligned_layer/examples/zkquiz."; exit 1; }

# Langkah 5: Bangun target answer_quiz
echo "Membangun target answer_quiz..."
make answer_quiz KEYSTORE_PATH=~/.aligned_keystore/keystore0

echo "Berhasil"
echo -e "\n👉 **[Gabung ke Airdrop Node](https://t.me/airdrop_node)** 👈"
