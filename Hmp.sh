#!/bin/bash

show() {
    echo -e "\033[1;35m$1\033[0m"
}

install_node() {
    curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

    ARCH=$(uname -m)

    if ! command -v jq &> /dev/null; then
        show "jq not found, installing..."
        sudo apt-get update
        sudo apt-get install -y jq > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            show "Failed to install jq. Please check your package manager."
            exit 1
        fi
    fi

    check_latest_version() {
        for i in {1..3}; do
            LATEST_VERSION=$(curl -s https://api.github.com/repos/hemilabs/heminetwork/releases/latest | jq -r '.tag_name')
            if [ -n "$LATEST_VERSION" ]; then
                show "Latest version available: $LATEST_VERSION"
                return 0
            fi
            show "Attempt $i: Failed to fetch the latest version. Retrying..."
            sleep 2
        done

        show "Failed to fetch the latest version after 3 attempts. Please check your internet connection or GitHub API limits."
        exit 1
    }

    check_latest_version

    download_required=true

    if [ "$ARCH" == "x86_64" ]; then
        if [ -d "heminetwork_${LATEST_VERSION}_linux_amd64" ]; then
            show "Latest version for x86_64 is already downloaded. Skipping download."
            cd "heminetwork_${LATEST_VERSION}_linux_amd64" || { show "Failed to change directory."; exit 1; }
            download_required=false
        fi
    elif [ "$ARCH" == "arm64" ]; then
        if [ -d "heminetwork_${LATEST_VERSION}_linux_arm64" ]; then
            show "Latest version for arm64 is already downloaded. Skipping download."
            cd "heminetwork_${LATEST_VERSION}_linux_arm64" || { show "Failed to change directory."; exit 1; }
            download_required=false
        fi
    fi

    if [ "$download_required" = true ]; then
        if [ "$ARCH" == "x86_64" ]; then
            show "Downloading for x86_64 architecture..."
            wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz"
            tar -xzf "heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz" > /dev/null
            cd "heminetwork_${LATEST_VERSION}_linux_amd64" || { show "Failed to change directory."; exit 1; }
        elif [ "$ARCH" == "arm64" ]; then
            show "Downloading for arm64 architecture..."
            wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz"
            tar -xzf "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" > /dev/null
            cd "heminetwork_${LATEST_VERSION}_linux_arm64" || { show "Failed to change directory."; exit 1; }
        else
            show "Unsupported architecture: $ARCH"
            exit 1
        fi
    else
        show "Skipping download as the latest version is already present."
    fi

    echo
    show "Do you want to create (1) new wallets or (2) import existing ones?"
    read -p "Enter your choice (1/2): " choice

    if [ "$choice" == "1" ]; then
        show "How many wallets do you want to create?"
        read -p "Enter the number of wallets: " wallet_count

        > ~/PoP-Mining-Wallets.txt

        for i in $(seq 1 $wallet_count); do
            echo
            show "Generating wallet $i..."
            ./keygen -secp256k1 -json -net="testnet" > "wallet_$i.json"

            if [ $? -ne 0 ]; then
                show "Failed to generate wallet $i."
                exit 1
            fi

            pubkey_hash=$(jq -r '.pubkey_hash' "wallet_$i.json")
            priv_key=$(jq -r '.private_key' "wallet_$i.json")
            ethereum_address=$(jq -r '.ethereum_address' "wallet_$i.json")

            echo "Wallet $i - Ethereum Address: $ethereum_address" >> ~/PoP-Mining-Wallets.txt
            echo "Wallet $i - BTC Address: $pubkey_hash" >> ~/PoP-Mining-Wallets.txt
            echo "Wallet $i - Private Key: $priv_key" >> ~/PoP-Mining-Wallets.txt
            echo "--------------------------------------" >> ~/PoP-Mining-Wallets.txt
            show "Wallet $i details saved in PoP-Mining-Wallets.txt"

            show "Join: https://discord.gg/hemixyz"
            show "Request faucet from faucet channel to this address: $pubkey_hash"
            echo
            read -p "Have you requested faucet for wallet $i? (y/N): " faucet_requested
            if [[ ! "$faucet_requested" =~ ^[Yy]$ ]]; then
                show "Please request faucet before proceeding."
                exit 1
            fi
        done

    elif [ "$choice" == "2" ]; then
        show "How many wallets do you want to import?"
        read -p "Enter the number of wallets: " wallet_count

        > ~/PoP-Mining-Imported-Wallets.txt

        for i in $(seq 1 $wallet_count); do
            read -p "Enter your private key for Wallet $i: " priv_key

            echo "Wallet $i - Private Key: $priv_key" >> ~/PoP-Mining-Imported-Wallets.txt
            echo "--------------------------------------" >> ~/PoP-Mining-Imported-Wallets.txt
            show "Wallet $i imported successfully."
        done
    else
        show "Invalid choice. Exiting."
        exit 1
    fi

    echo
    read -p "Enter static fee (numerical only, recommended: 100-200): " static_fee
    echo

    for i in $(seq 1 $wallet_count); do
        if systemctl is-active --quiet hemi_wallet_$i.service; then
            show "hemi_wallet_$i.service is currently running. Stopping and disabling it..."
            sudo systemctl stop hemi_wallet_$i.service
            sudo systemctl disable hemi_wallet_$i.service
        fi
        
        sleep 2

        if [ "$choice" == "1" ]; then
            priv_key=$(jq -r '.private_key' "wallet_$i.json")
        elif [ "$choice" == "2" ]; then
            priv_key=$(grep "Wallet $i - Private Key" ~/PoP-Mining-Imported-Wallets.txt | cut -d ':' -f 2 | xargs)
        fi

        cat << EOF | sudo tee /etc/systemd/system/hemi_wallet_$i.service > /dev/null
[Unit]
Description=Hemi Network PoP Mining for Wallet $i
After=network.target

[Service]
WorkingDirectory=$(pwd)
ExecStart=$(pwd)/popmd
Environment="POPM_BFG_REQUEST_TIMEOUT=60s"
Environment="POPM_BTC_PRIVKEY=$priv_key"
Environment="POPM_STATIC_FEE=$static_fee"
Environment="POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable hemi_wallet_$i.service
        sudo systemctl start hemi_wallet_$i.service
    done

    show "All processes completed successfully."
}

update_node() {
    show "Updating Hemi Network PoP node..."
    services_to_restart=()
    for service in /etc/systemd/system/hemi_wallet_*.service; do
        if [ -f "$service" ]; then
            service_name=$(basename "$service")
            if systemctl is-active --quiet "$service_name"; then
                show "Stopping $service_name..."
                sudo systemctl stop "$service_name"
                sudo systemctl disable "$service_name"
                services_to_restart+=("$service_name")
            fi
        fi
    done

    if [ ${#services_to_restart[@]} -eq 0 ]; then
        show "No hemi_wallet services are running."
    fi

    ARCH=$(uname -m)

    if ! command -v jq &> /dev/null; then
        show "jq not found, installing..."
        sudo apt-get update
        sudo apt-get install -y jq > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            show "Failed to install jq. Please check your package manager."
            exit 1
        fi
    fi

    check_latest_version() {
        for i in {1..3}; do
            LATEST_VERSION=$(curl -s https://api.github.com/repos/hemilabs/heminetwork/releases/latest | jq -r '.tag_name')
            if [ -n "$LATEST_VERSION" ]; then
                show "Latest version available: $LATEST_VERSION"
                return 0
            fi
            show "Attempt $i: Failed to fetch the latest version. Retrying..."
            sleep 2
        done
    
        show "Failed to fetch the latest version after 3 attempts. Please check your internet connection or GitHub API limits."
        exit 1
    }
    
    check_latest_version
    
    
    download_required=true
    
    if [ "$ARCH" == "x86_64" ]; then
        if [ -d "heminetwork_${LATEST_VERSION}_linux_amd64" ]; then
            show "Latest version for x86_64 is already downloaded. Skipping download."
            cd "heminetwork_${LATEST_VERSION}_linux_amd64" || { show "Failed to change directory."; exit 1; }
            download_required=false
        fi
    elif [ "$ARCH" == "arm64" ]; then
        if [ -d "heminetwork_${LATEST_VERSION}_linux_arm64" ]; then
            show "Latest version for arm64 is already downloaded. Skipping download."
            cd "heminetwork_${LATEST_VERSION}_linux_arm64" || { show "Failed to change directory."; exit 1; }
            download_required=false
        fi
    fi
    
    if [ "$download_required" = true ]; then
        if [ "$ARCH" == "x86_64" ]; then
            show "Downloading for x86_64 architecture..."
            wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz"
            tar -xzf "heminetwork_${LATEST_VERSION}_linux_amd64.tar.gz" > /dev/null
            cd "heminetwork_${LATEST_VERSION}_linux_amd64" || { show "Failed to change directory."; exit 1; }
        elif [ "$ARCH" == "arm64" ]; then
            show "Downloading for arm64 architecture..."
            wget --quiet --show-progress "https://github.com/hemilabs/heminetwork/releases/download/$LATEST_VERSION/heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" -O "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz"
            tar -xzf "heminetwork_${LATEST_VERSION}_linux_arm64.tar.gz" > /dev/null
            cd "heminetwork_${LATEST_VERSION}_linux_arm64" || { show "Failed to change directory."; exit 1; }
        else
            show "Unsupported architecture: $ARCH"
            exit 1
        fi
    else
        show "Skipping download as the latest version is already present."
    fi

    sudo systemctl daemon-reload

    for service in /etc/systemd/system/hemi_wallet_*.service; do
        if [ -f "$service" ]; then
            service_name=$(basename "$service")
            new_exec_start="$(pwd)/popmd"
            
            show "Updating ExecStart in $service_name to point to $new_exec_start"
            sudo sed -i "s|^ExecStart=.*|ExecStart=$new_exec_start|" "$service"
            
            if ! grep -q 'POPM_BFG_REQUEST_TIMEOUT=60s' "$service"; then
                sudo sed -i "/^\[Service\]/,/\[Install\]/ s/\(Restart=always\)/Environment=\"POPM_BFG_REQUEST_TIMEOUT=60s\"\n\1/" "$service"
            fi
        fi
    done

    for service in /etc/systemd/system/hemi_wallet_*.service; do
        if [ -f "$service" ]; then
            service_name=$(basename "$service")
            show "Restarting $service_name..."
            for attempt in {1..5}; do
                sudo systemctl enable "$service_name"
                sudo systemctl start "$service_name"
    
                if systemctl is-active --quiet "$service_name"; then
                    show "$service_name restarted successfully."
                    break
                else
                    show "Failed to restart $service_name. Attempt $attempt of 5."
                    sleep 2
                fi
            done
            
            if ! systemctl is-active --quiet "$service_name"; then
                show "Failed to restart $service_name after 5 attempts."
            fi
        fi
    done

    show "Node update completed successfully."
}

delete_node() {
    show "Deleting Hemi Network PoP node..."

    for service in $(systemctl list-units --type=service --all | grep -o 'hemi_wallet_[0-9]\+.service'); do
        if systemctl is-active --quiet "$service"; then
            show "Stopping and disabling $service..."
            sudo systemctl stop "$service"
            sudo systemctl disable "$service"
        fi

        sudo rm -f /etc/systemd/system/"$service"
        show "Service $service deleted."
    done

    show "All Hemi services stopped and deleted. Node removal completed."
}

menu() {
    while true; do
        echo -e "\n${YELLOW}┌─────────────────────────────────────────────────────┐${NORMAL}"
        echo -e "${YELLOW}│              Script Menu Options                    │${NORMAL}"
        echo -e "${YELLOW}├─────────────────────────────────────────────────────┤${NORMAL}"
        echo -e "${YELLOW}│              1) Install Hemi Pop Miner              │${NORMAL}"
        echo -e "${YELLOW}│              2) Update Hemi Pop Miner               │${NORMAL}"
        echo -e "${YELLOW}│              3) Delete Hemi Pop Miner               │${NORMAL}"
        echo -e "${YELLOW}│              4) Exit                                │${NORMAL}"
        echo -e "${YELLOW}└─────────────────────────────────────────────────────┘${NORMAL}"
        read -p "Enter your choice: " option

        case $option in
            1)
                install_node
                ;;
            2)
                update_node
                ;;
            3)
                delete_node
                ;;
            4)
                show "Exiting."
                exit 0
                ;;
            *)
                show "Invalid option. Please try again."
                ;;
        esac
    done
}

menu
