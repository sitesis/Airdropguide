#!/bin/bash

# Step 1: Check the Linux architecture
ARCHITECTURE=$(uname -m)
echo -e "\nChecking system architecture..."

if [[ "$ARCHITECTURE" == "x86_64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
    echo "Architecture is x86_64. Downloading appropriate client..."
elif [[ "$ARCHITECTURE" == "aarch64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
    echo "Architecture is ARM64. Downloading appropriate client..."
else
    echo "Unsupported architecture: $ARCHITECTURE"
    exit 1
fi

# Step 2: Download the client package
echo -e "\nDownloading client package..."
wget $CLIENT_URL -O multipleforlinux.tar
if [[ $? -ne 0 ]]; then
    echo "Failed to download client package."
    exit 1
fi

# Step 3: Extract the installation package
echo -e "\nExtracting installation package..."
tar -xvf multipleforlinux.tar
if [[ $? -ne 0 ]]; then
    echo "Extraction failed."
    exit 1
fi

# Step 4: Navigate to the extracted directory
cd multipleforlinux || { echo "Directory 'multipleforlinux' does not exist."; exit 1; }

# Step 5: Set permissions for the binaries
echo -e "\nSetting permissions for binaries..."
chmod +x ./multiple-cli ./multiple-node
if [[ $? -ne 0 ]]; then
    echo "Failed to set permissions. Please check the extracted files."
    exit 1
fi

# Step 6: Configure the PATH
echo -e "\nConfiguring PATH..."
echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc
source ~/.bashrc

# Step 7: Start the program
echo -e "\nStarting the program..."
nohup ./multiple-node > output.log 2>&1 &
if [[ $? -ne 0 ]]; then
    echo "Failed to start the program."
    exit 1
fi

# Step 8: Input unique identifier and PIN
echo -e "\nPlease input your unique account identifier and PIN..."

# Input validation for identifier
while [[ -z "$IDENTIFIER" ]]; do
    read -p "Enter your unique identifier: " IDENTIFIER
    if [[ -z "$IDENTIFIER" ]]; then
        echo "Error: Identifier cannot be empty. Please provide a valid identifier."
    fi
done

# Input validation for PIN
while [[ -z "$PIN" ]]; do
    read -p "Enter your PIN: " PIN
    if [[ -z "$PIN" ]]; then
        echo "Error: PIN cannot be empty. Please provide a valid PIN."
    fi
done

# Debugging input values
echo -e "\nDebug Info:"
echo "Identifier: $IDENTIFIER"
echo "PIN: $PIN"

# Step 9: Bind the account
echo -e "\nBinding account with identifier $IDENTIFIER and PIN $PIN..."
./multiple-cli bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100 2> bind_error.log

if [[ $? -eq 0 ]]; then
    echo -e "\nAccount successfully bound with identifier $IDENTIFIER."
else
    echo -e "\nFailed to bind account. Please check the input values and try again."
    echo "Check the error log for details: bind_error.log"
    exit 1
fi

# Final Step: Completion message
echo -e "\nInstallation completed successfully!"
echo -e "\nFor updates and support, please join our Telegram channel: https://t.me/airdrop_node"
