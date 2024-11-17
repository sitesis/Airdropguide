#!/bin/bash

# Display the updated logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 3

# Function to display messages in white
show() {
    echo -e "\033[1;37m$1\033[0m"
}

# Function to simulate a gradual fade-in effect
show_fadein() {
    local text="$1"
    local delay=0.1  # Delay between each character
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""  # Move to the next line after the fade-in
}

# Source rust installation script from the new URL
source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/rust.sh)

# Function to install Solana
install_solana() {
    if ! command -v solana &> /dev/null; then
        show "Solana not found. Installing Solana..."
        # Install Solana using the official installer
        sh -c "$(curl -sSfL https://release.solana.com/v1.18.18/install)"
        show_fadein " Installing Solana"
    else
        show "Solana is already installed."
    fi

    if ! grep -q "$HOME/.local/share/solana/install/active_release/bin" ~/.bashrc; then
        echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.bashrc
        show "Added Solana to PATH in .bashrc."
    fi

    if [ -n "$ZSH_VERSION" ]; then
        if ! grep -q "$HOME/.local/share/solana/install/active_release/bin" ~/.zshrc; then
            echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> ~/.zshrc
            show "Added Solana to PATH in .zshrc."
        fi
    fi

    # Reload shell configuration
    if [ -n "$BASH_VERSION" ]; then
        source ~/.bashrc
    elif [ -n "$ZSH_VERSION" ]; then
        source ~/.zshrc
    fi

    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

    if command -v solana &> /dev/null; then
        show "Solana is available in the current session."
    else
        show "Failed to add Solana to the PATH. Exiting."
        exit 1
    fi
}

# Function to import wallet
import_wallet() {
    KEYPAIR_DIR="$HOME/solana_keypairs"
    mkdir -p "$KEYPAIR_DIR"

    show "Please provide the wallet import file path (e.g., ~/solana_keypairs/your-wallet.json): "
    read KEYPAIR_PATH

    if [[ ! -f "$KEYPAIR_PATH" ]]; then
        show "Invalid file path. Exiting."
        exit 1
    fi

    solana config set --keypair "$KEYPAIR_PATH"
    show "Wallet imported successfully!"
}

# Function to set up network
setup_network() {
    NETWORK_URL="https://mainnetbeta-rpc.eclipse.xyz"
    solana config set --url "$NETWORK_URL"
    show "Network set to Mainnet."
}

# Function to create SPL token and perform operations
create_spl_and_operations() {
    show "Creating SPL token..."

    if ! solana config get | grep -q "Keypair Path:"; then
        show "Error: No keypair is set in Solana config. Exiting."
        exit 1
    fi

    spl-token create-token --enable-metadata -p TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb &
    show_fadein " Creating SPL token"

    if [[ $? -ne 0 ]]; then
        show "Failed to create SPL token. Exiting."
        exit 1
    fi

    read -p "Enter the token address you found above: " TOKEN_ADDRESS
    read -p "Enter your token symbol (e.g., AirdropNode): " TOKEN_SYMBOL
    read -p "Enter your token name (e.g., AirdropNode Token): " TOKEN_NAME
    read -p "Enter your token metadata url (Leave blank if not needed): " METADATA_URL

    if [[ -n "$METADATA_URL" ]]; then
        show "Initializing token metadata..."
        spl-token initialize-metadata "$TOKEN_ADDRESS" "$TOKEN_NAME" "$TOKEN_SYMBOL" "$METADATA_URL" &
        show_fadein " Initializing token metadata"
        if [[ $? -ne 0 ]]; then
            show "Failed to initialize token metadata. Exiting."
            exit 1
        fi
    else
        show "No metadata URL provided. Skipping metadata initialization."
    fi

    show "Creating token account..."
    spl-token create-account "$TOKEN_ADDRESS" &
    show_fadein " Creating token account"
    if [[ $? -ne 0 ]]; then
        show "Failed to create token account. Exiting."
        exit 1
    fi

    show "Minting tokens..."
    spl-token mint "$TOKEN_ADDRESS" 10000 &
    show_fadein " Minting tokens"
    if [[ $? -ne 0 ]]; then
        show "Failed to mint tokens. Exiting."
        exit 1
    fi

    show "Token operations completed successfully!"
}

# Prompt to join Telegram channel
join_telegram_channel() {
    show_fadein "Join our Telegram channel for updates and support: https://t.me/airdrop_node"
}

# Run all functions
install_solana
import_wallet
setup_network
create_spl_and_operations

# Join Telegram channel at the end
join_telegram_channel
