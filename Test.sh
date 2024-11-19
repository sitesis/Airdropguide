#!/bin/bash

# Define colors and styles
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NORMAL="\033[0m"
BOLD="\033[1m"

# Logfile
LOGFILE="$HOME/celestia-node.log"
MAX_LOG_SIZE=52428800  # 50MB

log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOGFILE"
}

rotate_log_file() {
    if [ -f "$LOGFILE" ] && [ $(stat -c%s "$LOGFILE") -ge $MAX_LOG_SIZE ]; then
        mv "$LOGFILE" "$LOGFILE.bak"
        touch "$LOGFILE"
        log_message "Log file rotated. Previous log archived as $LOGFILE.bak"
    fi
}

# Get latest version of Celestia Node from GitHub API
VERSION=$(curl -s "https://api.github.com/repos/celestiaorg/celestia-node/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Failed to fetch the latest version from GitHub.${NORMAL}"
    exit 1
fi

# Create New Wallet
create_new_wallet() {
    log_message "Creating a new wallet..."
    echo -e "${YELLOW}Creating a new wallet...${NORMAL}"
    OUTPUT=$(sudo docker run --rm \
        -v $HOME/celestia-node:/root/.celestia-light \
        ghcr.io/celestiaorg/celestia-node:$VERSION keys add my-wallet 2>&1)

    if [[ $OUTPUT == *"error"* ]]; then
        echo -e "${RED}Failed to create wallet. Check the logs for more details.${NORMAL}"
        log_message "Wallet creation failed: $OUTPUT"
        return
    fi

    # Extract wallet information
    ADDRESS=$(echo "$OUTPUT" | grep "address:" | awk '{print $2}')
    PUBLIC_KEY=$(echo "$OUTPUT" | grep "public key:" | awk '{print $3}')
    MNEMONIC=$(echo "$OUTPUT" | grep -A 12 "mnemonic:" | tail -n +2)

    echo -e "${GREEN}New wallet created successfully!${NORMAL}"
    echo -e "${YELLOW}Wallet Details:${NORMAL}"
    echo -e "  ${BOLD}Address:${NORMAL} $ADDRESS"
    echo -e "  ${BOLD}Public Key:${NORMAL} $PUBLIC_KEY"
    echo -e "  ${BOLD}Mnemonic:${NORMAL}"
    echo -e "$MNEMONIC"

    log_message "New wallet created. Address: $ADDRESS, Public Key: $PUBLIC_KEY"
}

# Import Wallet
import_wallet() {
    log_message "Importing an existing wallet..."
    echo -e "${YELLOW}Importing an existing wallet...${NORMAL}"
    read -p "Enter your wallet mnemonic: " MNEMONIC
    OUTPUT=$(sudo docker run --rm \
        -v $HOME/celestia-node:/root/.celestia-light \
        ghcr.io/celestiaorg/celestia-node:$VERSION keys add my-wallet --recover --mnemonic "$MNEMONIC" 2>&1)
    
    if [[ $OUTPUT == *"error"* ]]; then
        echo -e "${RED}Failed to import wallet. Please check your mnemonic.${NORMAL}"
        log_message "Wallet import failed: $OUTPUT"
    else
        echo -e "${GREEN}Wallet imported successfully!${NORMAL}"
        echo -e "${YELLOW}$OUTPUT${NORMAL}"
        log_message "Wallet imported: $OUTPUT"
    fi
}

# Start Celestia Node in Screen
start_celestia_node() {
    log_message "Starting Celestia Node in a screen session..."
    screen -S node-celestia -dm bash -c "sudo docker run --rm \
        -v $HOME/celestia-node:/root/.celestia-light \
        ghcr.io/celestiaorg/celestia-node:$VERSION start"

    echo -e "${GREEN}Celestia Node is running in the background. To attach, run: screen -r node-celestia${NORMAL}"
    log_message "Celestia Node started in screen session."
}

# Main Execution
rotate_log_file

echo -e "${BOLD}Choose an action:${NORMAL}"
echo "1. Create New Wallet"
echo "2. Import Wallet"
echo "3. Start Celestia Node"
read -p "Enter your choice (1/2/3): " ACTION

case $ACTION in
    1)
        create_new_wallet
        ;;
    2)
        import_wallet
        ;;
    3)
        start_celestia_node
        ;;
    *)
        echo -e "${RED}Invalid option. Exiting...${NORMAL}"
        log_message "Invalid option chosen. Script exited."
        ;;
esac
