#!/bin/bash

# Jalur penyimpanan script
SCRIPT_PATH="$HOME/sonicdeploy"

# Tampilkan Logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 3

# Perbarui sistem dan instal unzip
sudo apt update
sudo apt install -y unzip

# Tambahkan atau perbarui file .gitignore
function add_gitignore() {
    echo "Membuat .gitignore jika belum ada..."
    
    # Cek apakah file .gitignore sudah ada
    if [ ! -f .gitignore ]; then
        touch .gitignore
        echo "node_modules/" >> .gitignore
        echo "scripts/" >> .gitignore
        echo "hardhat.config.js" >> .gitignore
        echo "deploy.js" >> .gitignore
        echo ".env" >> .gitignore
    else
        echo ".gitignore sudah ada, tidak ada perubahan."
    fi
}

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        
        echo "================================================================"
        echo "Airdrop Node Telegram Channel: https://t.me/airdrop_node"
        echo "Untuk keluar dari script, tekan ctrl+c pada keyboard"
        echo "Pilih tindakan yang ingin dilakukan:"
        echo "1) Deploy Kontrak"
        echo "2) Keluar"

        read -p "Masukkan pilihan: " choice

        case $choice in
            1)
                deploy_contract
                ;;
            2)
                echo "Keluar dari script..."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan coba lagi"
                ;;
        esac
        read -n 1 -s -r -p "Tekan enter tombol untuk melanjutkan..."
    done
}

# Periksa dan instal perintah
function check_install() {
    command -v "$1" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "$1 belum diinstal, menginstal..."
        eval "$2"
    else
        echo "$1 sudah diinstal"
    fi
}

# Deploy kontrak menggunakan Hardhat
function deploy_contract() {
    export NVM_DIR="$HOME/.nvm"
    
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
        source "$NVM_DIR/nvm.sh"
    fi

    # Periksa dan instal Node.js versi stabil (v16 atau v18)
    if ! command -v node &> /dev/null; then
        nvm install 18
        nvm alias default 18
        nvm use default
    fi

    echo "Menginstal Hardhat..."
    npm install --save-dev hardhat
    npx hardhat

    echo "Mengonfigurasi Hardhat untuk Sonic Testnet..."
    mkdir -p scripts && cd scripts || exit

cat <<EOF > ../hardhat.config.js
require("@nomicfoundation/hardhat-toolbox");

// Replace this private key with your Sonic account private key
const SONIC_PRIVATE_KEY = "YOUR SONIC TEST ACCOUNT PRIVATE KEY";

module.exports = {
  solidity: "0.8.19",
  networks: {
    sonic: {
      url: "https://rpc.testnet.soniclabs.com",
      accounts: [SONIC_PRIVATE_KEY]
    }
  }
};
EOF

cat <<EOF > deploy.js
async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const balance = await deployer.getBalance();
  console.log("Account balance:", balance.toString());

  const ContractFactory = await ethers.getContractFactory("YourContract");
  const contract = await ContractFactory.deploy();
  console.log("Contract deployed to:", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
EOF

    # Meminta pengguna memasukkan private key akun Sonic mereka
    read -p "Masukkan private key akun Sonic Anda: " SONIC_PRIVATE_KEY
    sed -i "s|YOUR SONIC TEST ACCOUNT PRIVATE KEY|$SONIC_PRIVATE_KEY|" ../hardhat.config.js

    echo "Konfigurasi selesai. Menjalankan deploy script..."
    npx hardhat run scripts/deploy.js --network sonic

    read -p "Tekan Enter untuk kembali ke menu utama..."
}

# Menambahkan .gitignore
add_gitignore

# Jalankan menu utama
main_menu
