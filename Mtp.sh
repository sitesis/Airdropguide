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
cd multipleforlinux

# Step 5: Grant permissions in the `multipleforlinux` directory
echo "Granting execution permissions in the 'multipleforlinux' directory..."
chmod +x ./multiple-cli
chmod +x ./multiple-node

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
read -p "Enter your unique identifier: " IDENTIFIER
read -p "Enter your PIN: " PIN
multipleforlinux/multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

# Step 10: Perform additional operations (optional)
echo "If you need help with other commands, you can use --help."
