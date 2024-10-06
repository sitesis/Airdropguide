#!/bin/bash

#Logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash

sleep 4


# Fungsi untuk menginstal Rust
install_rust() {
    echo "Memulai instalasi Rust..."
    
    # Periksa apakah Rust sudah diinstal
    if command -v rustc &> /dev/null
    then
        echo "Rust sudah terinstall pada sistem."
    else
        # Unduh dan instal Rust melalui Rustup
        echo "Menginstall Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

        # Tambahkan Rust ke dalam PATH
        source $HOME/.cargo/env

        echo "Rust berhasil diinstall."
    fi
}

# Fungsi untuk menginstal Foundry
install_foundry() {
    echo "Memulai instalasi Foundry..."
    
    # Periksa apakah Foundry sudah diinstal
    if command -v forge &> /dev/null
    then
        echo "Foundry sudah terinstall pada sistem."
    else
        # Instal Foundry menggunakan Foundryup
        echo "Menginstall Foundry..."
        curl -L https://foundry.paradigm.xyz | bash

        # Tambahkan Foundry ke dalam PATH
        source $HOME/.bashrc
        
        echo "Foundry berhasil diinstall."
    fi
}

# Fungsi untuk menginstal pkg-config dan libssl-dev
install_dependencies() {
    echo "Memulai update dan instalasi dependensi..."
    
    # Perbarui daftar paket dan instal dependensi
    sudo apt update && sudo apt install -y pkg-config libssl-dev

    echo "pkg-config dan libssl-dev berhasil diinstall."
}

# Fungsi untuk mengimpor wallet menggunakan private key
import_wallet() {
    echo "Memulai proses impor wallet menggunakan private key..."

    # Pastikan private key diinput oleh user
    read -sp "Masukkan private key Anda: " PRIVATE_KEY
    echo
    
    # Periksa apakah direktori ~/.aligned_keystore sudah ada, dan hapus jika ada
    if [ -d ~/.aligned_keystore ]; then
        rm -rf ~/.aligned_keystore
        echo "Deleted existing directory ~/.aligned_keystore."
    fi
    
    # Buat direktori baru untuk keystore
    mkdir -p ~/.aligned_keystore
    
    # Import wallet menggunakan private key
    cast wallet import --private-key $PRIVATE_KEY ~/.aligned_keystore/keystore0
    
    echo "Wallet berhasil diimpor menggunakan private key ke ~/.aligned_keystore."
}

# Fungsi untuk meng-clone repository aligned_layer
clone_repository() {
    echo "Memulai proses clone repository aligned_layer..."
    
    # Periksa apakah direktori aligned_layer sudah ada, dan hapus jika ada
    if [ -d aligned_layer ]; then
        rm -rf aligned_layer
        echo "Deleted existing aligned_layer directory."
    fi
    
    # Clone repository dan masuk ke direktori zkquiz
    git clone https://github.com/yetanotherco/aligned_layer.git && cd aligned_layer/examples/zkquiz
    
    echo "Repository berhasil di-clone dan pindah ke direktori aligned_layer/examples/zkquiz."
}

# Fungsi untuk menjalankan make answer_quiz
run_quiz() {
    echo "Memulai proses make answer_quiz..."
    
    # Jalankan perintah make dengan KEYSSTORE_PATH
    make answer_quiz KEYSTORE_PATH=~/.aligned_keystore/keystore0 <<EOF
y
c
c
a
y
EOF

    echo "Proses answer_quiz selesai."
}

