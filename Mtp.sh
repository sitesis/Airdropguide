#!/bin/bash

# Define colors for text
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'
UNDERLINE='\033[4m'

# Define symbols for better UX
CHECK_MARK="${CYAN}✔${RESET}"
CROSS_MARK="${RED}✘${RESET}"
INFO_ICON="${YELLOW}ℹ${RESET}"
WARNING_ICON="${RED}⚠${RESET}"
SUCCESS_ICON="${GREEN}✅${RESET}"

# Step 1: Check the Linux architecture
ARCHITECTURE=$(uname -m)
echo -e "\n${INFO_ICON} ${CYAN}Checking system architecture...${RESET}"

if [[ "$ARCHITECTURE" == "x86_64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
    echo -e "${INFO_ICON} Architecture is ${CYAN}x86_64${RESET}. Downloading appropriate client..."
elif [[ "$ARCHITECTURE" == "aarch64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
    echo -e "${INFO_ICON} Architecture is ${CYAN}ARM64${RESET}. Downloading appropriate client..."
else
    echo -e "${CROSS_MARK} ${RED}Unsupported architecture: $ARCHITECTURE${RESET}"
    exit 1
fi

# Step 2: Download the client package
echo -e "\n${INFO_ICON} ${CYAN}Downloading client package...${RESET}"
wget $CLIENT_URL -O multipleforlinux.tar
if [[ $? -ne 0 ]]; then
    echo -e "${CROSS_MARK} ${RED}Failed to download client package.${RESET}"
    exit 1
fi

# Step 3: Extract the installation package
echo -e "\n${INFO_ICON} ${CYAN}Extracting installation package...${RESET}"
tar -xvf multipleforlinux.tar
if [[ $? -ne 0 ]]; then
    echo -e "${CROSS_MARK} ${RED}Extraction failed.${RESET}"
    exit 1
fi

# Step 4: Navigate to the extracted directory
cd multipleforlinux || { echo -e "${CROSS_MARK} ${RED}Directory 'multipleforlinux' does not exist.${RESET}"; exit 1; }

# Step 5: List the extracted files to ensure we have the right files
echo -e "\n${INFO_ICON} ${CYAN}Listing files in the extracted directory:${RESET}"
ls -l

# Step 6: Check if the files exist before attempting to change permissions
echo -e "\n${INFO_ICON} ${CYAN}Changing permissions...${RESET}"

if [[ -f "./multiple-cli" ]]; then
    chmod +x ./multiple-cli
    echo -e "${SUCCESS_ICON} ${GREEN}'multiple-cli' permissions set.${RESET}"
else
    echo -e "${CROSS_MARK} ${RED}'multiple-cli' not found. Please check the extracted contents.${RESET}"
    exit 1
fi

if [[ -f "./multiple-node" ]]; then
    chmod +x ./multiple-node
    echo -e "${SUCCESS_ICON} ${GREEN}'multiple-node' permissions set.${RESET}"
else
    echo -e "${CROSS_MARK} ${RED}'multiple-node' not found. Please check the extracted contents.${RESET}"
    exit 1
fi

# Step 7: Configure the PATH variable
echo -e "\n${INFO_ICON} ${CYAN}Configuring PATH...${RESET}"
echo "export PATH=\$PATH:$(pwd)" >> ~/.bashrc
source ~/.bashrc

# Step 8: Return to the root directory and grant permissions recursively
echo -e "\n${INFO_ICON} ${CYAN}Granting root permissions to the extracted files...${RESET}"
cd ..
chmod -R 777 multipleforlinux

# Step 9: Start the program
echo -e "\n${INFO_ICON} ${CYAN}Starting the program...${RESET}"
nohup ./multipleforlinux/multiple-node > output.log 2>&1 &
if [[ $? -ne 0 ]]; then
    echo -e "${CROSS_MARK} ${RED}Failed to start the program.${RESET}"
    exit 1
fi

# Step 10: Bind the unique account identifier
echo -e "\n${INFO_ICON} ${CYAN}Please input your unique account identifier and PIN...${RESET}"

# Input validation for identifier
while [[ -z "$IDENTIFIER" ]]; do
    read -p "Enter your unique identifier: " IDENTIFIER
    if [[ -z "$IDENTIFIER" ]]; then
        echo -e "${WARNING_ICON} ${YELLOW}Identifier cannot be empty. Please provide a valid identifier.${RESET}"
    fi
done

# Input validation for PIN
while [[ -z "$PIN" ]]; do
    read -p "Enter your PIN: " PIN
    if [[ -z "$PIN" ]]; then
        echo -e "${WARNING_ICON} ${YELLOW}PIN cannot be empty. Please provide a valid PIN.${RESET}"
    fi
done

# Step 11: Bind the account
echo -e "\n${INFO_ICON} ${CYAN}Binding account with identifier $IDENTIFIER and PIN $PIN...${RESET}"
./multipleforlinux/multiple-cli bind --bandwidth-download 100 --identifier $IDENTIFIER --pin $PIN --storage 200 --bandwidth-upload 100

if [[ $? -eq 0 ]]; then
    echo -e "\n${SUCCESS_ICON} ${GREEN}Account successfully bound with identifier $IDENTIFIER.${RESET}"
else
    echo -e "\n${CROSS_MARK} ${RED}Failed to bind account. Please check the input values and try again.${RESET}"
    exit 1
fi

# Step 12: Perform additional operations (optional)
echo -e "\n${INFO_ICON} ${CYAN}If you need help with other commands, you can use ${CYAN}--help${RESET}."

# Final step: Invite the user to join the Telegram channel
echo -e "\n${INFO_ICON} ${CYAN}Thank you for completing the installation!${RESET}"
echo -e "\n${INFO_ICON} ${CYAN}For updates and support, please join our Telegram channel: ${CYAN}${UNDERLINE}https://t.me/airdrop_node${RESET}"

# Provide instructions for joining the channel
echo -e "\n${INFO_ICON} ${YELLOW}Click the link above or search for AirdropNode on Telegram to join the community.${RESET}"

# Optional: Open the link in the browser
xdg-open "https://t.me/airdrop_node" &>/dev/null
