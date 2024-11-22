#!/bin/bash

# Step 1: Download the compatible client for your Linux architecture
echo "Downloading multipleforlinux.tar..."
wget https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar

# Step 2: Extract the installation package
echo "Extracting multipleforlinux.tar..."
tar -xvf multipleforlinux.tar

# Step 3: Grant required permissions
echo "Granting permissions..."
chmod +x ./multiple-cli
chmod +x ./multiple-node

# Step 4: Configure the required parameters
echo "Configuring PATH..."
echo "PATH=\$PATH:/$(pwd)" >> ~/.bashrc

# Apply the required parameters
echo "Applying parameters..."
source /etc/profile

# Step 5: Return to the root directory and grant permissions
echo "Granting root permissions to the extracted folder..."
chmod -R 777 ./multipleforlinux

# Step 6: Start the program
echo "Starting the program..."
nohup ./multiple-node > output.log 2>&1 &

# Step 7: Bind the unique account identifier (Replace XXXXXXXX and XXXXXX with actual values)
echo "Binding unique account identifier..."
echo "Please enter your unique account identifier and PIN code."

# Prompt user for account identifier and pin
read -p "Enter unique identifier: " identifier
read -p "Enter PIN code: " pin

# Run the bind command with provided values
multiple-cli bind --bandwidth-download 100 --identifier "$identifier" --pin "$pin" --storage 200 --bandwidth-upload 100

echo "Installation and configuration complete."
