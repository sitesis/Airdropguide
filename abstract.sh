#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 3

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
        return "Hey cok, kontrak cerdas wes dipasang airdrop_node!";
    }
}
EOL

    npx hardhat clean
    npx hardhat compile --network abstractTestnet
}

deployment() {
    read -p "Lebokake kunci pribadi dompetmu (tanpa 0x): " DEPLOYER_PRIVATE_KEY
    mkdir -p deploy
    read -p "Lebokake nama kontrak: " CONTRACT_NAME
    cat <<EOL > deploy/deploy.ts
import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";

export default async function (hre: HardhatRuntimeEnvironment) {
  const wallet = new Wallet("$DEPLOYER_PRIVATE_KEY");
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("$CONTRACT_NAME");

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

clean_up() {
    echo "Ngresiki build artifacts lan contracts.txt..."
    npx hardhat clean
    rm -f contracts.txt
    echo "Proses resik-resik rampung."
}

display_contract_addresses() {
    echo "Alamat kontrak sing wis dipasang:"
    cat contracts.txt || echo "Ora ana kontrak sing dipasang."
}

update_contract() {
    read -p "Lebokake alamat kontrak sing arep dianyari: " CONTRACT_ADDRESS
    read -p "Lebokake kunci pribadi dompetmu (tanpa 0x): " DEPLOYER_PRIVATE_KEY
    read -p "Lebokake nama kontrak anyar: " NEW_CONTRACT_NAME

    cat <<EOL > deploy/update.ts
import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";

export default async function (hre: HardhatRuntimeEnvironment) {
  const wallet = new Wallet("$DEPLOYER_PRIVATE_KEY");
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("$NEW_CONTRACT_NAME");

  const updatedContract = await deployer.deploy(artifact, { at: "$CONTRACT_ADDRESS" });
  console.log(\`Alamat kontrak anyar: \${await updatedContract.getAddress()}\`);
}
EOL

    echo "Nginstal kontrak anyar..."
    npx hardhat deploy-zksync --script update.ts
    echo "Kontrak anyar wis sukses dipasang."
}

# Menu utama
while true; do
    echo "Pilih opsi:"
    echo "1. Instal dependensi"
    echo "2. Kompilasi kontrak"
    echo "3. Deploy kontrak"
    echo "4. Verifikasi kontrak"
    echo "5. Resik-resik"
    echo "6. Tampilake alamat kontrak"
    echo "7. Dianyari kontrak"
    echo "8. Metu"
    read -p "Pilihan sampeyan: " OPTION

    case $OPTION in
        1) install_dependencies ;;
        2) compilation ;;
        3) deploy_contracts ;;
        4) verify_contracts ;;
        5) clean_up ;;
        6) display_contract_addresses ;;
        7) update_contract ;;
        8) echo "Metu..."; exit ;;
        *) echo "Pilihan ora valid, coba maneh." ;;
    esac
done

# Ngajak gabung ing Airdrop Node
echo -e "\n🎉 **Rampung! ** 🎉"
echo -e "\n👉 **[Gabung Airdrop Node](https://t.me/airdrop_node)** 👈"
