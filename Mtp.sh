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

# Step 4: Grant permissions
echo "Granting execution permissions..."
chmod +x ./multiple-cli
chmod +x ./multiple-node

# Step 5: Configure the PATH variable
echo "Configuring PATH..."
echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc
source ~/.bashrc

# Step 6: Return to the root directory and grant permissions recursively
echo "Granting root permissions to extracted files..."
chmod -R 777 multipleforlinux

# Step 7: Start the program
echo "Starting the program..."
nohup ./multiple-node > output.log 2>&1 &

# Step 8: Bind the unique account identifier
echo "Please input your unique account identifier and PIN..."
read -p "Enter your unique identifier: " IDENTIFIER
read -p "Enter your PIN: " PIN
multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

# Step 9: Perform additional operations (optional)
echo "If you need help with other commands, you can use --help."
