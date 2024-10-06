#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Function to install system dependencies required for Rust and Foundry
install_dependencies() {
    echo "Installing system dependencies required for Rust and Foundry..."
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y build-essential pkg-config libssl-dev curl || { echo "Failed to install dependencies."; exit 1; }
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl || { echo "Failed to install dependencies."; exit 1; }
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl || { echo "Failed to install dependencies."; exit 1; }
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu base-devel openssl curl || { echo "Failed to install dependencies."; exit 1; }
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
    case "$choice" in
        r)
            echo "Reinstalling Rust..."
            rustup self uninstall -y
            ;;
        u)
            echo "Updating Rust..."
            rustup update
            ;;
        *)
            echo "Skipping Rust installation."
            ;;
    esac
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

# Step 3: Set up the aligned keystore
echo "Setting up aligned keystore..."
[ -d ~/.aligned_keystore ] && rm -rf ~/.aligned_keystore && echo "Deleted existing directory ~/.aligned_keystore."
mkdir -p ~/.aligned_keystore
cast wallet import ~/.aligned_keystore/keystore0 --interactive

# Step 4: Clone aligned_layer repository and navigate to zkquiz example
echo "Setting up aligned_layer..."
[ -d aligned_layer ] && rm -rf aligned_layer && echo "Deleted existing aligned_layer directory."
git clone https://github.com/yetanotherco/aligned_layer.git
cd aligned_layer/examples/zkquiz || { echo "Failed to navigate to aligned_layer/examples/zkquiz."; exit 1; }

# Step 5: Build the answer_quiz target
echo "Building the answer_quiz target..."
make answer_quiz KEYSTORE_PATH=~/.aligned_keystore/keystore0

echo "Join Channel TELEGRAM https://t.me/airdrop_node"
