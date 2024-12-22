#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
RESET='\033[0m'

# Header
clear
echo -e "${CYAN}=================================================${RESET}"
echo -e "${GREEN}         Auto Installer for Rivalz Node          ${RESET}"
echo -e "${CYAN}                  By AirdropNode                 ${RESET}"
echo -e "${CYAN}=================================================${RESET}\n"

# Update dan upgrade sistem
echo -e "${YELLOW}Updating and upgrading system...${RESET}\n"
sudo apt update && sudo apt upgrade -y

# Instal Node.js versi 20
echo -e "\n${YELLOW}Installing Node.js v20...${RESET}\n"
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Instal Rivalz Node CLI
echo -e "\n${YELLOW}Installing Rivalz Node CLI...${RESET}\n"
npm i -g rivalz-node-cli

# Memulai screen session
echo -e "\n${YELLOW}Starting a new screen session for Rivalz Node...${RESET}\n"
screen -dmS rivalz bash -c 'rivalz run'

# Menyediakan opsi untuk cek log
echo -e "\n${YELLOW}Would you like to view the logs now? (y/n)${RESET}"
read -p "Your choice: " choice

if [[ $choice == "y" || $choice == "Y" ]]; then
    echo -e "\n${CYAN}Attaching to the screen session...${RESET}"
    sleep 1
    screen -r rivalz
else
    echo -e "\n${GREEN}Logs can be viewed later by running: ${CYAN}screen -r rivalz${RESET}\n"
fi

# Penutup
echo -e "\n${CYAN}=================================================${RESET}"
echo -e "${GREEN}        Installation Complete! Next Steps:       ${RESET}"
echo -e "${CYAN}=================================================${RESET}\n"
echo -e "${YELLOW}1.${RESET} Input your ${CYAN}Metamask address${RESET}, ${CYAN}CPU cores${RESET}, and ${CYAN}RAM specs${RESET}."
echo -e "${YELLOW}2.${RESET} Wait for ${CYAN}~5-10 minutes${RESET} for the node to sync."
echo -e "${YELLOW}3.${RESET} Open the Rivalz Testnet Web and click ${CYAN}'Validate'${RESET}."
echo -e "${YELLOW}   Link: ${CYAN}https://rivalz.ai/?r=Choirc8${RESET}\n"
echo -e "${CYAN}=================================================${RESET}"
echo -e "${GREEN}For more details, check the official documentation:${RESET}"
echo -e "${CYAN}https://docs.rivalz.ai/testnet/testnet-guide/download-and-run-rclient/rclient-cli-guide${RESET}"
echo -e "${CYAN}=================================================${RESET}\n"
