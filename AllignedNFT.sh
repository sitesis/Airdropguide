#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Fungsi untuk menginstal Rust
install_rust() {
    echo "Memulai instalasi Rust..."
    if command -v rustc &> /dev/null; then
        echo "Rust sudah terinstall pada sistem."
    else
        echo "Menginstall Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
        echo "Rust berhasil diinstall."
    fi
}

# Fungsi untuk menginstal Foundry
install_foundry() {
    echo "Memulai instalasi Foundry..."
    if command -v forge &> /dev/null; then
        echo "Foundry sudah terinstall pada sistem."
    else
        echo "Menginstall Foundry..."
        curl -L https://foundry.paradigm.xyz | bash
        source $HOME/.bashrc
        echo "Foundry berhasil diinstall."
    fi
}

# Fungsi untuk menginstal pkg-config dan libssl-dev
install_dependencies() {
    echo "Memulai update dan instalasi dependensi..."
    sudo apt update && sudo apt install -y pkg-config libssl-dev
    echo "pkg-config dan libssl-dev berhasil diinstall."
}

# Fungsi untuk mengimpor wallet menggunakan cast
import_wallet() {
    echo "Memulai proses impor wallet..."
    
    # Buat direktori baru untuk keystore jika belum ada
    mkdir -p ~/.aligned_keystore
    
    # Import wallet secara interaktif menggunakan cast
    cast wallet import ~/.aligned_keystore/keystore0 --interactive
    echo "Wallet berhasil diimpor ke ~/.aligned_keystore."
}

# Fungsi untuk meng-clone repository aligned_layer
clone_repository() {
    echo "Memulai proses clone repository aligned_layer..."
    [ -d aligned_layer ] && rm -rf aligned_layer
    git clone https://github.com/yetanotherco/aligned_layer.git && cd aligned_layer/examples/zkquiz || exit
    echo "Repository berhasil di-clone dan pindah ke direktori aligned_layer/examples/zkquiz."
}

# Fungsi untuk menjalankan make answer_quiz
run_quiz() {
    echo "Memulai proses make answer_quiz..."
    make answer_quiz KEYSTORE_PATH=~/.aligned_keystore/keystore0
    echo "Proses answer_quiz selesai."
}

# Panggil fungsi
install_rust
install_foundry
install_dependencies
import_wallet
clone_repository
run_quiz
