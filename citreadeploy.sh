#!/bin/bash

# Check for Node.js installation
if ! command -v node &> /dev/null
then
    echo "Node.js is not installed. Please install Node.js before running this script."
    exit 1
fi

# Check for npm installation
if ! command -v npm &> /dev/null
then
    echo "npm is not installed. Please install npm before running this script."
    exit 1
fi

# Install Hardhat
echo "Installing Hardhat..."
npm install --save-dev hardhat

# Create a new Hardhat project
echo "Creating a new Hardhat project..."
npx hardhat init

# Check if hardhat.config.js exists
CONFIG_FILE="hardhat.config.js"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found. Please make sure to run 'npx hardhat init' first."
    exit 1
fi

# Prompt for private key
read -sp "Enter your private key (this will be kept secret): " PRIVATE_KEY
echo

# Update hardhat.config.js with Citrea configuration
echo "Configuring Hardhat for Citrea..."

# Add Citrea network configuration to hardhat.config.js
cat <<EOL >> $CONFIG_FILE

module.exports = {
    // Add your existing configuration above this line
    networks: {
        citrea: {
            url: "https://rpc.testnet.citrea.xyz",
            chainId: 5115,
            accounts: ["$PRIVATE_KEY"],
        },
    },
    // Add your existing configuration below this line
};
EOL

# Print success message
echo "Hardhat has been configured for Citrea Testnet successfully!"
echo "You can now deploy your smart contracts using the command:"
echo "npx hardhat run --network citrea scripts/deploy.js"
