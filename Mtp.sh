#!/bin/bash
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5
# Set color codes
RED='\033[0;31m'
LIGHT_GREEN='\033[1;32m'    # Light Green
YELLOW='\033[0;33m'
LIGHT_BLUE='\033[1;34m'     # Light Blue
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

# 🖥️ Check Linux architecture
ARCH=$(uname -m)

if [[ "$ARCH" == "x86_64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/x64/multipleforlinux.tar"
elif [[ "$ARCH" == "aarch64" ]]; then
    CLIENT_URL="https://cdn.app.multiple.cc/client/linux/arm64/multipleforlinux.tar"
else
    echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"
    exit 1
fi

echo ""
echo -e "${CYAN}🔽 Downloading client from $CLIENT_URL...${NC}"
wget $CLIENT_URL -O multipleforlinux.tar
echo ""

echo -e "${MAGENTA}📦 Extracting installation package...${NC}"
tar -xvf multipleforlinux.tar
echo ""

# Navigate into the extracted directory
cd multipleforlinux
echo ""

echo -e "${YELLOW}🔧 Setting required permissions...${NC}"
chmod +x multiple-cli
chmod +x multiple-node
echo ""

# Configure required parameters
echo -e "${LIGHT_BLUE}⚙️ Configuring PATH...${NC}"
echo "PATH=\$PATH:$(pwd)" >> ~/.bashrc
source ~/.bashrc
echo ""

# Set permissions for the directory
echo -e "${LIGHT_GREEN}🔑 Setting permissions for the directory...${NC}"
chmod -R 777 .
echo ""

# Prompt for IDENTIFIER and PIN
echo -e "${CYAN}📝 Please enter the required information:${NC}"
read -p "Enter your IDENTIFIER: " IDENTIFIER
read -p "Enter your PIN: " PIN
echo ""

# Run the program
echo -e "${LIGHT_GREEN}🚀 Running the program...${NC}"
nohup ./multiple-node > output.log 2>&1 &

# Bind unique account identifier
echo -e "${YELLOW}🔗 Binding account with identifier and PIN...${NC}"
./multiple-cli bind --bandwidth-download 100 --identifier "$IDENTIFIER" --pin "$PIN" --storage 200 --bandwidth-upload 100
echo ""

echo -e "${LIGHT_GREEN}✅ Process completed.${NC}"
echo ""

# Step 8: Perform other operations if necessary
echo -e "${MAGENTA}💡 You can perform other operations if necessary. Use the --help option to view specific commands for logs.${NC}"
