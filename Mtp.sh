#!/bin/bash

# Step 1: Check if required commands are available
command -v wget >/dev/null 2>&1 || { echo "wget not found, please install it."; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "tar not found, please install it."; exit 1; }
command -v chmod >/dev/null 2>&1 || { echo "chmod not found, please install it."; exit 1; }
command -v nohup >/dev/null 2>&1 || { echo "nohup not found, please install it."; exit 1; }

# Step 2: Download the compatible client for your Linux architecture
echo "Downloading multipleforlinux.tar..."
wget https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar || { echo "Download failed!"; exit 1; }

# Step 3: Extract the installation package
echo "Extracting multipleforlinux.tar..."
tar -xvf multipleforlinux.tar || { echo "Extraction failed!"; exit 1; }

# Step 4: Change to the directory where the files were extracted
cd multipleforlinux || { echo "Failed to navigate to multipleforlinux directory"; exit 1; }

# Step 5: Grant required permissions
echo "Granting permissions..."
chmod +x ./multiple-cli || { echo "Failed to grant permission to multiple-cli"; exit 1; }
chmod +x ./multiple-node || { echo "Failed to grant permission to multiple-node"; exit 1; }

# Step 6: Configure the required parameters
echo "Configuring PATH..."
export PATH=$PATH:$(pwd)  # Add current directory to PATH

# Apply the required parameters
echo "Applying parameters..."
source /etc/profile || { echo "Failed to source /etc/profile"; exit 1; }

# Step 7: Return to the root directory and grant permissions
echo "Granting root permissions to the extracted folder..."
chmod -R 777 ./multipleforlinux || { echo "Failed to change permissions"; exit 1; }

# Step 8: Start the program
echo "Starting the program..."
nohup ./multiple-node > output.log 2>&1 & || { echo "Failed to start the program"; exit 1; }

# Step 9: Bind the unique account identifier (Replace XXXXXXXX and XXXXXX with actual values)
echo "Binding unique account identifier..."
echo "Please enter your unique account identifier and PIN code."

# Prompt user for account identifier and pin
read -p "Enter unique identifier: " identifier
read -p "Enter PIN code: " pin

# Run the bind command with provided values
./multiple-cli bind --bandwidth-download 100 --identifier "$identifier" --pin "$pin" --storage 200 --bandwidth-upload 100 || { echo "Failed to bind account"; exit 1; }

echo "Installation and configuration complete."
