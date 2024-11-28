#!/bin/bash

# Display a header message with spacing
echo -e "\n###############################"
echo -e "# Airdrop Node Setup Script"
echo -e "###############################\n"

# Step 1: Create Directory for DCDN
echo "Step 1: Creating directory /opt/dcdn..."
sudo mkdir -p /opt/dcdn
echo -e "\nDirectory /opt/dcdn created successfully.\n"

# Step 2: Prompt for Pipe Tool URL and Download Binary
echo "Step 2: Please enter the URL for the Pipe tool binary:"
read PIPE_URL
echo "Downloading pipe tool from $PIPE_URL..."
sudo curl -L "$PIPE_URL" -o /opt/dcdn/pipe-tool
echo -e "\nPipe tool downloaded successfully.\n"

# Step 3: Prompt for Node Binary URL and Download
echo "Step 3: Please enter the URL for the Node binary:"
read DCDND_URL
echo "Downloading node binary from $DCDND_URL..."
sudo curl -L "$DCDND_URL" -o /opt/dcdn/dcdnd
echo -e "\nNode binary downloaded successfully.\n"

# Step 4: Make Binary Executable
echo "Step 4: Making binaries executable..."
sudo chmod +x /opt/dcdn/pipe-tool
sudo chmod +x /opt/dcdn/dcdnd
echo -e "\nBinaries made executable.\n"

# Step 5: Log In to Generate Access Token
echo "Step 5: Logging in to generate access token..."
/opt/dcdn/pipe-tool login --node-registry-url="https://rpc.pipedev.network"
echo -e "\nLogin successful.\n"

# Step 6: Generate Registration Token
echo "Step 6: Generating registration token..."
/opt/dcdn/pipe-tool generate-registration-token --node-registry-url="https://rpc.pipedev.network"
echo -e "\nRegistration token generated.\n"

# Step 7: Generate Wallet and Save Wallet Phrase
echo "Step 7: Generating wallet..."
WALLET_PHRASE=$(/opt/dcdn/pipe-tool generate-wallet --node-registry-url="https://rpc.pipedev.network")
echo -e "\nWallet generated successfully. Save the following wallet phrase securely:\n"
echo -e "\e[1;33m$WALLET_PHRASE\e[0m"
echo -e "\nMake sure to store this wallet phrase safely.\n"

# Step 8: Link Wallet
echo "Step 8: Linking wallet..."
/opt/dcdn/pipe-tool link-wallet --node-registry-url="https://rpc.pipedev.network"
echo -e "\nWallet linked successfully.\n"

# Step 9: Create Systemd Service File
echo "Step 9: Creating systemd service file for dcdnd..."
sudo cat > /etc/systemd/system/dcdnd.service << 'EOF'
[Unit]
Description=DCDN Node Service
After=network.target
Wants=network-online.target

[Service]
# Path to the executable and its arguments
ExecStart=/opt/dcdn/dcdnd \
                --grpc-server-url=0.0.0.0:8002 \
                --http-server-url=0.0.0.0:8003 \
                --node-registry-url="https://rpc.pipedev.network" \
                --cache-max-capacity-mb=1024 \
                --credentials-dir=/root/.permissionless \
                --allow-origin=*

# Restart policy
Restart=always
RestartSec=5

# Resource and file descriptor limits
LimitNOFILE=65536
LimitNPROC=4096

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dcdn-node

# Working directory
WorkingDirectory=/opt/dcdn

[Install]
WantedBy=multi-user.target
EOF
echo -e "\nSystemd service file created successfully.\n"

# Step 10: Reload systemd Daemon
echo "Step 10: Reloading systemd daemon..."
sudo systemctl daemon-reload
echo -e "\nsystemd daemon reloaded.\n"

# Step 11: Enable and Start the Service
echo "Step 11: Enabling and starting the dcdnd service..."
sudo systemctl enable dcdnd.service
sudo systemctl start dcdnd.service
echo -e "\ndcdnd service enabled and started.\n"

# Step 12: Check Service Status
echo "Step 12: Checking the status of dcdnd service..."
sudo systemctl status dcdnd.service
echo -e "\nService status check complete.\n"

# Step 13: Check Node Status
echo "Step 13: Checking the node status..."
/opt/dcdn/pipe-tool list-nodes --node-registry-url="https://rpc.pipedev.network"
echo -e "\nNode status check complete.\n"

# Final Message
echo -e "###############################"
echo -e "# Installation and Service Setup Complete!"
echo -e "###############################\n"

# Invitation to Join Telegram Channel
echo -e "To stay updated, join our Telegram channel: \n"
echo -e "\e[1;34mhttps://t.me/airdrop_node\e[0m\n"
echo -e "Thank you for setting up your DCDN node!\n"
