#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Mriksa apa Node.js wis diinstal
if command -v node >/dev/null 2>&1; then
    echo "Node.js wis diinstal: $(node -v)"
else
    # Nganyari dhaptar paket
    sudo apt update

    # Instal curl yen durung diinstal
    sudo apt install -y curl

    # Ngundhuh lan nginstal Node.js nggunakake NodeSource
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt install -y nodejs

    # Verifikasi instalasi
    echo "Node.js lan npm wis diinstal."
    node -v
    npm -v
fi

# Gawe direktori proyek
PROJECT_DIR=~/UnichainNFTProject

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir "$PROJECT_DIR"
    echo "Direktori $PROJECT_DIR wis digawe."
else
    echo "Direktori $PROJECT_DIR wis ana."
fi

# Mlebu direktori proyek
cd "$PROJECT_DIR" || exit

# Inisialisasi proyek NPM
npm init -y
echo "Proyek NPM wis diinisialisasi."

# Instal Hardhat, Ethers.js, OpenZeppelin, lan dotenv
npm install --save-dev hardhat @nomiclabs/hardhat-ethers ethers @openzeppelin/contracts dotenv
echo "Hardhat, Ethers.js, OpenZeppelin, lan dotenv wis diinstal."

# Miwiti proyek Hardhat
npx hardhat init -y
echo "Proyek Hardhat wis digawe nganggo konfigurasi kosong."

# Gawe folder contracts lan scripts
mkdir contracts && mkdir scripts
echo "Folder 'contracts' lan 'scripts' wis digawe."

# Gawe file NFT.sol (ERC721 Token)
cat <<EOL > contracts/NFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AirdropNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("AirdropNFT", "ANFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://sepolia.uniscan.xyz/";  // Base URI for metadata
    }

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}
EOL
echo "File 'NFT.sol' wis digawe ing folder 'contracts'."

# Ngompilasi kontrak
npx hardhat compile
echo "Kontrak wis dikompilasi."

# Gawe file .env
touch .env
echo "File '.env' wis digawe ing direktori proyek."

# Njupuk input kunci privat saka pangguna
read -p "Lebokna private key sampeyan: " PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env
echo "Private key sampeyan wis disimpen ing file .env."

# Gawe file .gitignore
cat <<EOL > .gitignore
# Sample .gitignore code
# Node modules
node_modules/

# Environment variables
.env

# Coverage files
coverage/
coverage.json

# Typechain generated files
typechain/
typechain-types/

# Hardhat files
cache/
artifacts/

# Build files
build/
EOL
echo "File '.gitignore' wis digawe nganggo conto kode."

# Gawe file hardhat.config.js
cat <<EOL > hardhat.config.js
/** @type import('hardhat/config').HardhatUserConfig */
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.20",
  networks: {
    unichain: {
      url: "https://sepolia.unichain.org",  // Unichain Sepolia RPC URL
      chainId: 1301,  // Sepolia Unichain chain ID
      accounts: [\`0x\${process.env.PRIVATE_KEY}\`],
    },
  },
};
EOL
echo "File 'hardhat.config.js' wis diisi karo konfigurasi Hardhat kanggo Unichain."

# Gawe file deploy.js ing folder scripts
cat <<EOL > scripts/deploy.js
const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    const NFT = await ethers.getContractFactory("AirdropNFT");
    const nft = await NFT.deploy();

    console.log("NFT contract deployed to:", nft.address);

    // Mint NFT to deployer's address
    await nft.safeMint(deployer.address);
    console.log("NFT successfully minted to deployer's address:", deployer.address);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
EOL
echo "File 'deploy.js' wis digawe ing folder 'scripts'."

# Mlakokake skrip deploy
echo "Mlakokake skrip deploy..."
DEPLOY_OUTPUT=$(npx hardhat run --network unichain scripts/deploy.js)

# Tampilake output deploy
echo "$DEPLOY_OUTPUT"

# Tampilake informasi penting
echo -e "\nProyek Unichain NFT wis disiapake lan kontrak wis dideploy!"

# Njupuk alamat token saka output deploy
TOKEN_ADDRESS=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')

# Tampilake pesen kanggo mriksa alamat ing explorer
if [ -n "$TOKEN_ADDRESS" ]; then
    echo -e "Monggo dipriksa alamat NFT sampeyan ing explorer: https://sepolia.uniscan.xyz/address/$TOKEN_ADDRESS"
else
    echo "Ora bisa nemokake alamat NFT sing wis dideploy."
fi

# Ngajak gabung ing Airdrop Node
echo -e "\n🎉 **Rampung! ** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
