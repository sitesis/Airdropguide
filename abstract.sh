#!/bin/bash

# Fungsi untuk kloning repositori
clone_repository() {
    echo "Mengkloning repositori Foundry zkSync..."
    git clone https://github.com/matter-labs/foundry-zksync.git
}

# Fungsi untuk menjalankan penginstal
install_foundry_zksync() {
    echo "Memasuki direktori foundry-zksync..."
    cd foundry-zksync || { echo "Direktori tidak ditemukan!"; exit 1; }
    
    echo "Menjalankan penginstal..."
    ./install-foundry-zksync || { echo "Instalasi gagal!"; exit 1; }
}

# Fungsi untuk verifikasi instalasi
verify_installation() {
    echo "Memverifikasi instalasi..."
    forge build --help | grep -A 20 "ZKSync configuration:" || { echo "Verifikasi instalasi gagal!"; exit 1; }
    echo "Instalasi berhasil diverifikasi!"
}

# Fungsi untuk membuat proyek baru
create_new_project() {
    echo "Keluar dari direktori foundry-zksync..."
    cd .. || { echo "Gagal keluar dari direktori foundry-zksync!"; exit 1; }

    echo "Membuat proyek baru dengan Forge..."
    forge init my-abstract-project && cd my-abstract-project || { echo "Gagal membuat proyek baru!"; exit 1; }
    echo "Proyek baru 'my-abstract-project' berhasil dibuat!"
}

# Fungsi untuk memperbarui konfigurasi forge.toml
update_forge_config() {
    echo "Memperbarui konfigurasi forge.toml..."

    # Tambahkan konfigurasi ke file forge.toml
    cat <<EOL >> forge.toml

[profile.default]
src = 'src'
libs = ['lib']
fallback_oz = true
is_system = false
mode = "3"
EOL

    echo "Konfigurasi forge.toml berhasil diperbarui!"
}

# Fungsi untuk menulis kontrak pintar ke src/Counter.sol
write_smart_contract() {
    echo "Menulis kontrak pintar ke src/Counter.sol..."

    # Buat folder src jika belum ada
    mkdir -p src

    # Tulis kontrak pintar ke file Counter.sol
    cat <<EOL > src/Counter.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Counter {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
EOL

    echo "Kontrak pintar berhasil ditulis ke src/Counter.sol!"
}

# Fungsi untuk mengkompilasi kontrak pintar dengan zksync
compile_contract() {
    echo "Mengompilasi kontrak pintar dengan zkSync..."
    forge build --zksync || { echo "Kompilasi gagal!"; exit 1; }
    echo "Kompilasi kontrak pintar berhasil!"
}

# Fungsi untuk menambahkan kunci pribadi ke keystore
import_private_key() {
    echo "Mengimpor kunci pribadi ke keystore dompet..."
    cast wallet import myKeystore --interactive
    echo "Kunci pribadi berhasil diimpor!"
}

# Fungsi untuk menyebarkan kontrak pintar ke jaringan zkSync
deploy_contract() {
    echo "Menyebarkan kontrak pintar ke jaringan zkSync..."

    # Jalankan perintah deploy menggunakan keystore yang dibuat
    transaction_hash=$(forge create src/Counter.sol:Counter --account myKeystore --rpc-url https://api.testnet.abs.xyz --chain 11124 --zksync | grep -o '0x[a-fA-F0-9]\+') || { echo "Penyebaran kontrak pintar gagal!"; exit 1; }

    echo "Kontrak pintar berhasil disebarkan! Transaction Hash: $transaction_hash"
}

# Fungsi untuk memeriksa transaksi di explorer
check_transaction() {
    echo "Memeriksa transaksi di explorer..."
    echo "Buka URL berikut untuk melihat transaksi: https://explorer.testnet.abs.xyz/transactions/$transaction_hash"
}

# Main function untuk menjalankan semua proses
main() {
    clone_repository
    install_foundry_zksync
    verify_installation
    create_new_project
    update_forge_config
    write_smart_contract
    compile_contract
    import_private_key
    deploy_contract
    check_transaction
}

# Menjalankan script utama
main
