#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

install_dependencies() {
    echo "Nginstal Node.js..."
    source <(wget -O - https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/ndjs.sh)
    clear
    echo "Ngawali proyek Hardhat..."
    npx hardhat init --yes
    clear
    echo "Nginstal dependensi sing dibutuhake..."
    npm install -D @matterlabs/hardhat-zksync @matterlabs/zksync-contracts zksync-ethers@6 ethers@6

    echo "Kabeh proses instalasi dependensi rampung."
}

compilation() {
    echo "Ngganti konfigurasi Hardhat..."
    cat <<EOL > hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@matterlabs/hardhat-zksync";

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest",
    settings: {
      enableEraVMExtensions: false,
    },
  },
  defaultNetwork: "abstractTestnet",
  networks: {
    abstractTestnet: {
      url: "https://api.testnet.abs.xyz",
      ethNetwork: "sepolia",
      zksync: true,
      verifyURL: "https://api-explorer-verify.testnet.abs.xyz/contract_verification",
    },
  },
  solidity: {
    version: "0.8.24",
  },
};

export default config;
EOL
    mv contracts/Lock.sol contracts/HelloAbstract.sol
    cat <<EOL > contracts/HelloAbstract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HelloAbstract {
    function sayHello() public pure virtual returns (string memory) {
        return "Hallo cvk, kontrak cerdas wes dipasang airdrop_node!";
    }
}
EOL

    npx hardhat clean
    npx hardhat compile --network abstractTestnet
}

deployment() {
    read -p "Lebokake kunci pribadi dompetmu (tanpa 0x): " DEPLOYER_PRIVATE_KEY
    mkdir -p deploy
    read -p "Lebokake nama kontrak: " CONTRACT_NAME  # Tambahkan baris ini untuk nama kontrak
    cat <<EOL > deploy/deploy.ts
import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";

export default async function (hre: HardhatRuntimeEnvironment) {
  const wallet = new Wallet("$DEPLOYER_PRIVATE_KEY");
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("$CONTRACT_NAME");  // Gunakan nama kontrak yang dimasukkan

  const tokenContract = await deployer.deploy(artifact);
  console.log(\`Alamat kontrakmu sing dipasang : \${await tokenContract.getAddress()}\`);
}
EOL
}

deploy_contracts() {
    read -p "Pira kontrak sing pengin sampeyan pasang? " CONTRACT_COUNT
    > contracts.txt

    for ((i = 1; i <= CONTRACT_COUNT; i++)); do
        echo "Nginstal kontrak #$i..."
        npx hardhat deploy-zksync --script deploy.ts
        echo "Kontrak #$i wis sukses dipasang"
        echo "------------------------------------"
        read -p "Mangga lebokake alamat kontrak sing dipasang kanggo kontrak #$i : " CONTRACT_ADDRESS
        echo "$CONTRACT_ADDRESS" >> contracts.txt
    done
}

verify_contracts() {
    while IFS= read -r CONTRACT_ADDRESS; do
        echo "Verifikasi kontrak pinter ing alamat: $CONTRACT_ADDRESS..."
        npx hardhat verify --network abstractTestnet "$CONTRACT_ADDRESS"
    done < contracts.txt
}

# Ngajak gabung ing Airdrop Node
echo -e "\n🎉 **Rampung! ** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
