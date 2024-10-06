#!/bin/bash

# Update dan upgrade sistem
echo "Updating and upgrading the system..."
sudo apt update && sudo apt upgrade -y

# Menginstal dependensi tambahan
echo "Installing additional dependencies: pkg-config and libssl-dev..."
sudo apt install -y pkg-config libssl-dev

# Menginstal dependensi untuk Rust jika belum terpasang
if ! command -v rustc &> /dev/null; then
    echo "Installing dependencies for Rust..."
    sudo apt install -y build-essential curl

    # Menginstal Rust
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    # Menambahkan Rust ke PATH
    echo "Adding Rust to PATH..."
    source $HOME/.cargo/env

    # Memverifikasi instalasi Rust
    echo "Verifying Rust installation..."
    rustc --version
else
    echo "Rust is already installed. Skipping installation."
fi

# Menginstal Foundry jika belum terpasang
if ! command -v foundryup &> /dev/null; then
    echo "Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash

    # Menambahkan Foundry ke PATH
    echo "Adding Foundry to PATH..."
    source $HOME/.foundry/bin/foundry

    # Memverifikasi instalasi Foundry
    echo "Verifying Foundry installation..."
    foundryup --version
else
    echo "Foundry is already installed. Skipping installation."
fi

# Menghapus direktori ~/.aligned_keystore jika ada
if [ -d ~/.aligned_keystore ]; then
    rm -rf ~/.aligned_keystore
    echo "Deleted existing directory ~/.aligned_keystore."
fi

# Membuat direktori ~/.aligned_keystore
mkdir -p ~/.aligned_keystore

# Mengimpor wallet menggunakan cast
echo "Importing wallet..."
cast wallet import ~/.aligned_keystore/keystore0 --interactive

# Menghapus direktori aligned_layer jika ada
if [ -d aligned_layer ]; then
    rm -rf aligned_layer
    echo "Deleted existing aligned_layer directory."
fi

# Mengkloning repositori aligned_layer
echo "Cloning aligned_layer repository..."
git clone https://github.com/yetanotherco/aligned_layer.git

# Berpindah ke direktori aligned_layer/examples/zkquiz
cd aligned_layer/examples/zkquiz || { echo "Failed to change directory to aligned_layer/examples/zkquiz"; exit 1; }

# Menjalankan perintah make untuk answer_quiz
echo "Running make command to answer quiz..."
make answer_quiz KEYSTORE_PATH=~/.aligned_keystore/keystore0

echo "Installation script completed successfully!"
