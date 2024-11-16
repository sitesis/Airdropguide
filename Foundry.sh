#!/bin/bash

check_foundry_installed() {
    if command -v forge >/dev/null 2>&1; then
        echo "Foundry is already installed."
        return 0
    else
        return 1
    fi
}

install_foundry() {
    echo "Installing Foundry..."
    if ! curl -L https://foundry.paradigm.xyz | bash; then
        echo "Error: Foundry installation failed."
        return 1
    fi

    export PATH="$HOME/.foundry/bin:$PATH"

    echo "Installing essential tools: cast, anvil..."
    if ! foundryup; then
        echo "Error: Installation of essential tools failed."
        return 1
    fi
}

add_foundry_to_path() {
    if grep -q "foundry/bin" "$HOME/.bashrc" || grep -q "foundry/bin" "$HOME/.zshrc"; then
        echo "Foundry is already added to PATH."
    else
        echo "Adding Foundry to PATH..."

        if [ -f "$HOME/.bashrc" ]; then
            echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.bashrc"
            source "$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.zshrc"
            source "$HOME/.zshrc"
        else
            echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.profile"
            source "$HOME/.profile"
        fi
    fi
}

validate_path() {
    echo "Validating PATH setup..."
    if ! command -v forge >/dev/null 2>&1 || ! command -v cast >/dev/null 2>&1 || ! command -v anvil >/dev/null 2>&1; then
        echo "Error: PATH not properly set in the current session."
        return 1
    else
        echo "Foundry tools are working fine in the current session."
    fi

    # Test for future shell session after reloading the shell config
    if ! bash -c "command -v forge && command -v cast && command -v anvil"; then
        echo "Error: PATH not properly set for future shell sessions."
        return 1
    else
        echo "Foundry tools are working fine in future shell sessions."
    fi

    return 0
}

echo "Checking if Foundry is already installed..."
if check_foundry_installed; then
    echo "Foundry is already installed. Validating the PATH setup..."
    validate_path
else
    install_foundry
    add_foundry_to_path
    validate_path
fi

echo "Foundry installation and PATH setup complete."
