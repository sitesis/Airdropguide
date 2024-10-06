#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Function to install Rust
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

# Function to install Foundry
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

# Function to install pkg-config and libssl-dev
install_dependencies() {
    echo "Memulai update dan instalasi dependensi..."
    sudo apt update && sudo apt install -y pkg-config libssl-dev
    echo "pkg-config dan libssl-dev berhasil diinstall."
}

# Function to check ETH balance in Holesky
check_eth_balance() {
    echo "Checking ETH balance in Holesky..."
    balance=$(cast wallet balance $(cast wallet address) --rpc-url https://holesky.ethereum.org)

    if (( $(echo "$balance < 0.1" | bc -l) )); then
        echo "You need at least 0.1 ETH in your Holesky account to proceed. Current balance: $balance ETH"
        exit 1
    else
        echo "You have sufficient balance: $balance ETH"
    fi
}

# Function to import a new wallet
import_wallet() {
    # Delete existing keystore directory if it exists
    if [ -d ~/.aligned_keystore ]; then
        rm -rf ~/.aligned_keystore
        echo "Deleted existing directory ~/.aligned_keystore."
    fi

    # Create a new keystore directory
    mkdir -p ~/.aligned_keystore

    # Import the wallet
    echo "Importing wallet..."
    cast wallet import ~/.aligned_keystore/keystore0 --interactive
}

# Function to clone aligned_layer repository
clone_aligned_layer() {
    # Delete existing aligned_layer directory if it exists
    if [ -d aligned_layer ]; then
        rm -rf aligned_layer
        echo "Deleted existing aligned_layer directory."
    fi

    # Clone the aligned_layer repository from GitHub
    git clone https://github.com/yetanotherco/aligned_layer.git

    # Change to the zkquiz directory
    cd aligned_layer/examples/zkquiz
    echo "Changed to the zkquiz directory."
}

# Function to answer the quiz
answer_quiz() {
    echo "Answering the quiz..."
    make answer_quiz KEYSTORE_PATH=~/.aligned_keystore/keystore0
}

# Main function to execute the steps
main() {
    install_dependencies
    install_rust
    install_foundry
    check_eth_balance
    import_wallet
    clone_aligned_layer
    answer_quiz
}

# Run the main function
main
