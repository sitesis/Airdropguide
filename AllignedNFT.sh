#!/bin/bash

# Function to install system dependencies required for Rust and Foundry
install_dependencies() {
    echo "Installing system dependencies required for Rust and Foundry..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y build-essential libssl-dev curl
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu base-devel openssl curl
    else
        echo "Unsupported package manager. Please install dependencies manually."
        exit 1
    fi
}

# Install system dependencies
install_dependencies

# Step 1: Install Rust using rustup
if command -v rustup &> /dev/null; then
    echo "Rust is already installed."
    read -p "Do you want to reinstall or update Rust? (r to reinstall, u to update, n to skip): " choice
    if [[ "$choice" == "r" ]]; then
        echo "Reinstalling Rust..."
        rustup self uninstall -y
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    elif [[ "$choice" == "u" ]]; then
        echo "Updating Rust..."
        rustup update
    fi
else
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Load Rust environment variables
export RUSTUP_HOME="$HOME/.rustup"
export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# Fix permissions for Rust directories
chmod -R 755 "$RUSTUP_HOME"
chmod -R 755 "$CARGO_HOME"
chown -R $(whoami) "$RUSTUP_HOME" "$CARGO_HOME"

# Verify Rust and Cargo versions
rust_version=$(rustc --version)
cargo_version=$(cargo --version)

echo "Rust version: $rust_version"
echo "Cargo version: $cargo_version"

# Add Rust environment variables to .bashrc or .zshrc
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
    echo "Added Rust environment variables to $PROFILE. Please restart your terminal or run 'source $PROFILE' for changes to take effect."
fi

# Source the profile for the current session
source "$PROFILE"

# Step 2: Install Foundry using foundryup
echo "Installing Foundry..."
if ! command -v curl &> /dev/null; then
    echo "curl is not installed. Please install curl manually."
    exit 1
fi

curl -L https://foundry.paradigm.xyz | bash

# Update PATH for Foundry
if ! grep -q 'export PATH="$HOME/.foundry/bin:$PATH"' "$PROFILE"; then
    echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$PROFILE"
    echo "Added Foundry environment variable to $PROFILE. Please restart your terminal or run 'source $PROFILE' for changes to take effect."
fi

# Source the profile for the current session
source "$PROFILE"

# Verify Foundry installation
if foundryup; then
    echo "Foundry installation successful!"
else
    echo "Foundry installation failed."
    exit 1
fi

# Verify Foundry tools
if command -v forge &> /dev/null && command -v cast &> /dev/null && command -v anvil &> /dev/null; then
    echo "Foundry tools (forge, cast, anvil) are installed and available!"
else
    echo "Foundry tools are not recognized. Please check your installation."
    exit 1
fi

# Step 3: Import wallet using cast
echo "Preparing to import wallet..."
mkdir -p ~/.aligned_keystore

# Prompt for private key and password
read -sp "Enter your private key: " private_key
echo
read -sp "Enter the password for your private key: " password
echo

# Import the wallet using cast
cast wallet import ~/.aligned_keystore/keystore0 --interactive

# Optionally, you can save the private key to the keystore file (ensure this is done securely)
# echo "$private_key" > ~/.aligned_keystore/keystore0
# echo "$password" >> ~/.aligned_keystore/keystore0

echo "Wallet import completed successfully!"

echo "Rust and Foundry installation and wallet import are complete!"
