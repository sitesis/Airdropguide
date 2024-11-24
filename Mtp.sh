#!/bin/bash

# Define symbols for better UX
CHECK_MARK="✔"
CROSS_MARK="✘"
INFO_ICON="ℹ"
WARNING_ICON="⚠"
SUCCESS_ICON="✅"

# Step 1: Check the Linux architecture
ARCHITECTURE=$(uname -m)
echo -e "\n${INFO_ICON} Checking system architecture..."

if [[ "$ARCHITECTURE" == "x86_64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
    echo -e "${INFO_ICON} Architecture is x86_64. Downloading appropriate client..."
elif [[ "$ARCHITECTURE" == "aarch64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
    echo -e "${INFO_ICON} Architecture is ARM64. Downloading appropriate client..."
else
    echo -e "${CROSS_MARK} Unsupported architecture: $ARCHITECTURE"
    exit 1
fi

# Step 2: Download the client package
echo -e "\n${INFO_ICON} Downloading client package..."
wget $CLIENT_URL -O multipleforlinux.tar
if [[ $? -ne 0 ]]; then
    echo -e "${CROSS_MARK} Failed to download client package."
    exit 1
fi

# Step 3: Extract the installation package
echo -e "\n${INFO_ICON} Extracting installation package..."
tar -xvf multipleforlinux.tar
if [[ $? -ne 0 ]]; then
    echo -e "${CROSS_MARK} Extraction failed."
    exit 1
fi

# Step 4: Navigate to the extracted directory
cd multipleforlinux || { echo -e "${CROSS_MARK} Directory 'multipleforlinux' does not exist."; exit 1; }

# Step 5: List the extracted files to ensure we have the right files
echo -e "\n${INFO_ICON} Listing files in the extracted directory:"
ls -l

# Step 6: Check if the files exist before attempting to change permissions
echo -e "\n${INFO_ICON} Changing permissions..."

if [[ -f "./multiple-cli" ]]; then
    chmod +x ./multiple-cli
    echo -e "${SUCCESS_ICON} 'multiple-cli' permissions set."
else
    echo -e "${CROSS_MARK} 'multiple-cli' not found. Please check the extracted contents."
    exit 1
fi

if [[ -f "./multiple-node" ]]; then
    chmod +x ./multiple-node
    echo -e "${SUCCESS_ICON} 'multiple-node' permissions set."
else
    echo -e "${CROSS_MARK} 'multiple-node' not found. Please check the extracted contents."
    exit 1
fi

# Step 7: Configure the PATH variable
echo -e "\n${INFO_ICON} Configuring PATH..."
echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc
source ~/.bashrc

# Step 8: Return to the root directory and grant permissions recursively
echo -e "\n${INFO_ICON} Granting root permissions to the extracted files..."
cd ..
chmod -R 777 multipleforlinux

# Step 9: Start the program
echo -e "\n${INFO_ICON} Starting the program..."
nohup ./multipleforlinux/multiple-node > output.log 2>&1 &
if [[ $? -ne 0 ]]; then
    echo -e "${CROSS_MARK} Failed to start the program."
    exit 1
fi

# Step 10: Bind the unique account identifier
echo -e "\nPlease input your unique account identifier and PIN..."

# Input validation for identifier
while [[ -z "$IDENTIFIER" ]]; do
    read -p "Enter your unique identifier: " IDENTIFIER
    if [[ -z "$IDENTIFIER" ]]; then
        echo "Identifier cannot be empty. Please provide a valid identifier."
    fi
done

# Input validation for PIN
while [[ -z "$PIN" ]]; do
    read -p "Enter your PIN: " PIN
    if [[ -z "$PIN" ]]; then
        echo "PIN cannot be empty. Please provide a valid PIN."
    fi
done

# Step 11: Bind the account
echo -e "\nBinding account with identifier $IDENTIFIER and PIN $PIN..."
./multipleforlinux/multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

if [[ $? -eq 0 ]]; then
    echo -e "\nAccount successfully bound with identifier $IDENTIFIER."
else
    echo -e "\nFailed to bind account. Please check the input values and try again."
    exit 1
fi

# Step 12: Perform additional operations (optional)
echo -e "\nIf you need help with other commands, you can use --help."

# Final step: Invite the user to join the Telegram channel
echo -e "\nThank you for completing the installation!"
echo -e "\nFor updates and support, please join our Telegram channel: https://t.me/airdrop_node"

# Optional: Open the link in the browser
xdg-open "https://t.me/airdrop_node" &>/dev/null
