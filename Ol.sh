#!/bin/bash

# Clear the terminal screen for a fresh look
clear

# Print a styled heading
echo -e "\033[1;34m-----------------------------------------------------------------------------"
echo -e "\033[1;32m                   Installing Openledger Node... Please Wait!"
echo -e "\033[1;34m-----------------------------------------------------------------------------"

# Add some spacing
echo -e "\n"

# Create directory for Openledger
echo -e "\033[1;33mCreating directory for Openledger...\033[0m"
mkdir Openledger

# Navigate into the Openledger directory
cd Openledger

# Upgrade the system
echo -e "\033[1;33mUpgrading the system...\033[0m"
sudo apt-get upgrade -y

# Add some spacing
echo -e "\n"

# Download Openledger Node package
echo -e "\033[1;33mDownloading Openledger Node package...\033[0m"
wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip

# Unzip the Openledger Node package
echo -e "\033[1;33mUnzipping the Openledger Node package...\033[0m"
unzip openledger-node-1.0.0-linux.zip

# Install the Openledger Node package
echo -e "\033[1;33mInstalling Openledger Node package...\033[0m"
sudo apt install ./openledger-node-1.0.0.deb

# Update the system again
echo -e "\033[1;33mUpdating the system...\033[0m"
sudo apt update

# Install additional required libraries
echo -e "\033[1;33mInstalling additional libraries...\033[0m"
sudo apt install libasound2 -y
sudo apt install xvfb -y

# Set DISPLAY environment variable
echo -e "\033[1;33mSetting up DISPLAY environment variable...\033[0m"
export DISPLAY=:0

# Add some spacing
echo -e "\n"

# Start Openledger Node in a screen session named "airdropnode_openledger"
echo -e "\033[1;33mStarting Openledger Node in screen session...\033[0m"
screen -S airdropnode_openledger -dm bash -c "openledger-node --no-sandbox --disable-gpu"

# Final message
echo -e "\033[1;32m-----------------------------------------------------------------------------"
echo -e "\033[1;32m               Openledger Node has been successfully started!"
echo -e "\033[1;32m-----------------------------------------------------------------------------"

