#!/bin/bash

# Step 1: Check the Linux architecture
ARCHITECTURE=$(uname -m)
if [[ "$ARCHITECTURE" == "x86_64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
elif [[ "$ARCHITECTURE" == "aarch64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
else
    echo "Unsupported architecture: $ARCHITECTURE"
    exit 1
fi

# Step 2: Download the client package
echo "Downloading client package for $ARCHITECTURE..."
wget $CLIENT_URL -O multipleforlinux.tar

# Step 3: Extract the installation package
echo "Extracting installation package..."
tar -xvf multipleforlinux.tar

# Step 4: Navigate to the extracted directory
cd multipleforlinux || { echo "Directory 'multipleforlinux' does not exist."; exit 1; }

# Step 5: List the extracted files to ensure we have the right files
echo "Listing files in 'multipleforlinux' directory:"
ls -l

# Check if the files exist before attempting to change permissions
if [[ -f "./multiple-cli" ]]; then
    chmod +x ./multiple-cli
else
    echo "'multiple-cli' not found. Please check the extracted contents."
fi

if [[ -f "./multiple-node" ]]; then
    chmod +x ./multiple-node
else
    echo "'multiple-node' not found. Please check the extracted contents."
fi

# Step 6: Configure the PATH variable
echo "Configuring PATH..."
echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc
source ~/.bashrc

# Step 7: Return to the root directory and grant permissions recursively
echo "Granting root permissions to the extracted files..."
cd ..
chmod -R 777 multipleforlinux

# Step 8: Start the program
echo "Starting the program..."
nohup ./multipleforlinux/multiple-node > output.log 2>&1 &

# Step 9: Bind the unique account identifier
echo "Please input your unique account identifier and PIN..."

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

# Bind the account
echo "Binding account with identifier $IDENTIFIER and PIN $PIN..."
./multipleforlinux/multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

# Step 10: Perform additional operations (optional)
echo "If you need help with other commands, you can use --help."
