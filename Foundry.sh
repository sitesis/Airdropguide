#!/bin/bash

BOLD=$(tput bold)
NORMAL=$(tput sgr0)
PINK='\033[1;35m'       # Pink for error messages
GREEN='\033[1;32m'      # Green for success messages
YELLOW='\033[1;33m'     # Yellow for progress messages

show() {
    case $2 in
        "error")
            echo -e "${PINK}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${YELLOW}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${GREEN}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

check_foundry_installed() {
    command -v forge >/dev/null 2>&1
}

install_foundry() {
    show "Installing Foundry..." "progress"
    curl -L https://foundry.paradigm.xyz | bash
    export PATH="$HOME/.foundry/bin:$PATH"
    show "Installing essential tools: cast, anvil..." "progress"
    foundryup
}

add_foundry_to_path() {
    if ! grep -q "foundry/bin" "$HOME/.bashrc" && ! grep -q "foundry/bin" "$HOME/.zshrc"; then
        show "Adding Foundry to PATH..." "progress"
        echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.profile"
        echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> "$HOME/.profile"
    else
        show "Foundry is already added to PATH."
    fi
}

validate_path() {
    show "Validating PATH setup..." "progress"
    if command -v forge >/dev/null 2>&1 && command -v cast >/dev/null 2>&1 && command -v anvil >/dev/null 2>&1; then
        show "Foundry tools are working fine in the current session."
    else
        show "Error: PATH not properly set in the current session." "error"
        return 1
    fi

    if ! bash -c "command -v forge && command -v cast && command -v anvil" >/dev/null 2>&1; then
        show "Error: PATH not properly set for future shell sessions." "error"
        return 1
    fi

    show "Foundry tools are working fine in future shell sessions."
    return 0
}

show "Checking if Foundry is already installed..." "progress"
if check_foundry_installed; then
    show "Foundry is already installed. Validating the PATH setup..."
else
    install_foundry
    add_foundry_to_path
fi

validate_path
show "Foundry installation and PATH setup complete."
