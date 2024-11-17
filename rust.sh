#!/bin/bash

# Define the location where Rust will be installed
RUSTUP_HOME="$HOME/.rustup"
CARGO_HOME="$HOME/.cargo"

# ANSI escape code for white color
WHITE='\033[1;37m'
RESET='\033[0m'

# Load Rust environment variables
load_rust() {
    export RUSTUP_HOME="$HOME/.rustup"
    export CARGO_HOME="$HOME/.cargo"
    export PATH="$CARGO_HOME/bin:$PATH"

    # Source the environment variables for the current session
    if [ -f "$CARGO_HOME/env" ]; then
        source "$CARGO_HOME/env"
    fi
}

# Function to install system dependencies required for Rust
install_dependencies() {
    echo -e "${WHITE}Installing system dependencies required for Rust...${RESET}"

    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y build-essential libssl-dev curl
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall 'Development Tools' && sudo yum install -y openssl-devel curl
    elif command -v dnf &> /dev/null; then
        sudo dnf groupinstall 'Development Tools' && sudo dnf install -y openssl-devel curl
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syu base-devel openssl curl
    else
        echo -e "${WHITE}Unsupported package manager. Please install dependencies manually.${RESET}"
        exit 1
    fi
}

# Install system dependencies before checking for Rust
install_dependencies

# Check if Rust is already installed
if command -v rustup &> /dev/null; then
    echo -e "${WHITE}Rust is already installed.${RESET}"
    read -p "Do you want to reinstall or update Rust? (y/n): " choice

    if [[ "$choice" == "y" ]]; then
        echo -e "${WHITE}Reinstalling Rust...${RESET}"
        rustup self uninstall -y
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
else
    echo -e "${WHITE}Rust is not installed. Installing Rust...${RESET}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi

# Load Rust environment after installation
load_rust

# Fix permissions for Rust directories (using sudo for root access)
echo -e "${WHITE}Ensuring correct permissions for Rust directories...${RESET}"

if [ -d "$RUSTUP_HOME" ]; then
    sudo chmod -R 755 "$RUSTUP_HOME"
fi

if [ -d "$CARGO_HOME" ]; then
    sudo chmod -R 755 "$CARGO_HOME"
fi

# Function to retry sourcing environment if Cargo is not found
retry_cargo() {
    local max_retries=3
    local retry_count=0
    local cargo_found=false

    while [ $retry_count -lt $max_retries ]; do
        if command -v cargo &> /dev/null; then
            cargo_found=true
            break
        else
            echo -e "${WHITE}Cargo not found in the current session. Attempting to reload the environment...${RESET}"
            source "$CARGO_HOME/env"
            retry_count=$((retry_count + 1))
        fi
    done

    if [ "$cargo_found" = false ]; then
        echo -e "${WHITE}Error: Cargo is still not recognized after $max_retries attempts.${RESET}"
        echo -e "${WHITE}Please manually source the environment by running: source \$HOME/.cargo/env${RESET}"
        return 1
    fi

    echo -e "${WHITE}Cargo is available in the current session.${RESET}"
    return 0
}

# Verify Rust and Cargo versions
rust_version=$(rustc --version)
cargo_version=$(cargo --version)

echo -e "${WHITE}Rust version: $rust_version${RESET}"
echo -e "${WHITE}Cargo version: $cargo_version${RESET}"

# Add Rust environment variables to the appropriate shell profile (.bashrc or .zshrc)
if [[ $SHELL == *"zsh"* ]]; then
    PROFILE="$HOME/.zshrc"
else
    PROFILE="$HOME/.bashrc"
fi

# Add Rust environment variables if not already present
if ! grep -q "CARGO_HOME" "$PROFILE"; then
    echo -e "${WHITE}Adding Rust environment variables to $PROFILE...${RESET}"
    {
        echo 'export RUSTUP_HOME="$HOME/.rustup"'
        echo 'export CARGO_HOME="$HOME/.cargo"'
        echo 'export PATH="$CARGO_HOME/bin:$PATH"'
        echo 'source "$CARGO_HOME/env"'
    } >> "$PROFILE"
fi

# Reload the profile automatically for the current session
source "$PROFILE"

# Force reload of cargo env in case the session doesn’t reflect it yet
source "$CARGO_HOME/env"

# Retry checking for Cargo availability
retry_cargo
if [ $? -ne 0 ]; then
    exit 1
fi

echo -e "${WHITE}Rust installation and setup are complete!${RESET}"
