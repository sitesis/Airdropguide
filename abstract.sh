#!/bin/bash

# Memastikan bahwa skrip dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Silakan jalankan sebagai root"
  exit
fi

# Memeriksa apakah Node.js sudah terinstal
if command -v node &> /dev/null; then
  echo "Node.js sudah terinstal. Versi yang terpasang:"
  node -v
  echo "Melanjutkan ke langkah berikutnya..."
else
  echo "Node.js belum terinstal. Memulai instalasi..."

  # Mengupdate dan menginstal dependensi yang diperlukan
  apt update && apt install -y curl

  # Mengunduh skrip ndjs.sh dari GitHub
  curl -o ndjs.sh https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/ndjs.sh

  # Memberikan izin eksekusi pada skrip
  chmod +x ndjs.sh

  # Menjalankan skrip ndjs.sh untuk menginstal Node.js
  ./ndjs.sh

  # Memeriksa instalasi Node.js dan npm
  node -v
  npm -v
fi

# Membuat direktori baru dan navigasi ke dalamnya
mkdir my-abstract-project && cd my-abstract-project

# Menginisialisasi proyek Hardhat baru dalam direktori
npx hardhat init <<EOF
Create a TypeScript project
$(pwd)
y
y
EOF

# Menginstal dependensi yang diperlukan untuk Abstract
npm install -D @matterlabs/hardhat-zksync @matterlabs/zksync-contracts zksync-ethers@6 ethers@6

# Membuat atau memperbarui hardhat.config.ts dengan konfigurasi yang diperlukan
cat <<EOL > hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@matterlabs/hardhat-zksync";

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest",
    settings: {
      // Note: This must be true to call NonceHolder & ContractDeployer system contracts
      enableEraVMExtensions: false,
    },
  },
  defaultNetwork: "abstractTestnet",
  networks: {
    abstractTestnet: {
      url: "https://api.testnet.abs.xyz",
      ethNetwork: "sepolia",
      zksync: true,
      verifyURL:
        "https://api-explorer-verify.testnet.abs.xyz/contract_verification",
    },
  },
  solidity: {
    version: "0.8.24",
  },
};

export default config;
EOL

# Menulis kontrak pintar baru dalam HelloAbstract.sol
cat <<EOL > contracts/HelloAbstract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HelloAbstract {
    function sayHello() public pure virtual returns (string memory) {
        return "Hello, bro! Script ini dibuat oleh airdrop_node";
    }
}
EOL

# Membersihkan semua artefak yang ada
npx hardhat clean

# Mengompilasi kontrak pintar untuk Abstract
npx hardhat compile --network abstractTestnet

# Membuat variabel konfigurasi baru bernama DEPLOYER_PRIVATE_KEY
echo "Masukkan kunci pribadi dompet Anda untuk DEPLOYER_PRIVATE_KEY:"
read -s DEPLOYER_PRIVATE_KEY

# Mengatur DEPLOYER_PRIVATE_KEY menggunakan Hardhat vars
npx hardhat vars set DEPLOYER_PRIVATE_KEY $DEPLOYER_PRIVATE_KEY

# Membuat direktori deploy dan file deploy.ts
mkdir deploy && touch deploy/deploy.ts

# Menambahkan kode penyebaran ke deploy.ts
cat <<EOL > deploy/deploy.ts
import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";
import { vars } from "hardhat/config";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(\`Running deploy script\`);

  // Initialize the wallet using your private key.
  const wallet = new Wallet(vars.get("DEPLOYER_PRIVATE_KEY"));

  // Create deployer object and load the artifact of the contract we want to deploy.
  const deployer = new Deployer(hre, wallet);
  // Load contract
  const artifact = await deployer.loadArtifact("HelloAbstract");

  // Deploy this contract. The returned object will be of a \`Contract\` type,
  // similar to the ones in \`ethers\`.
  const tokenContract = await deployer.deploy(artifact);

  console.log(
    \`\${
      artifact.contractName
    } was deployed to \${await tokenContract.getAddress()}\`
  );
}
EOL

# Menampilkan pesan selesai
echo "Proyek Hardhat baru telah berhasil diinisialisasi di $(pwd) dan semua dependensi telah diinstal!"
echo "Berhasil memperbarui hardhat.config.ts dengan konfigurasi untuk Abstract!"
echo "Berkas HelloAbstract.sol telah berhasil dibuat dengan kontrak pintar yang baru."
echo "Semua artefak telah dibersihkan dan kontrak pintar telah berhasil dikompilasi!"
echo "Variabel DEPLOYER_PRIVATE_KEY telah berhasil disimpan."
echo "Skrip penyebaran telah dibuat di deploy/deploy.ts."

# Menyebarkan kontrak pintar
echo "Menjalankan penyebaran kontrak pintar..."
npx hardhat deploy-zksync --script deploy.ts

# Memverifikasi kontrak pintar
echo "Masukkan alamat kontrak yang telah diterapkan untuk verifikasi:"
read CONTRACT_ADDRESS

npx hardhat verify --network abstractTestnet $CONTRACT_ADDRESS

# Menampilkan pesan selesai
echo "Kontrak pintar Anda telah berhasil diverifikasi! Anda dapat memeriksanya di https://explorer.testnet.abs.xyz/"
