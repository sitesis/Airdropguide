#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# Fungsi untuk meminta pengguna memasukkan key
function prompt_key() {
  echo -e "\n>> Masukkan kunci Anda:"
  read -r user_key
  if [[ -z "$user_key" ]]; then
    echo -e "\n** Kunci tidak boleh kosong. Silakan coba lagi. **"
    prompt_key
  fi
}

# Memulai script
echo -e "\n============================================"
echo "        Memulai Instalasi Titan Agent       "
echo "============================================"

# Update sistem
echo -e "\n>> Mengupdate sistem..."
sudo apt update -y

# Install snapd
echo -e "\n>> Menginstall snapd..."
sudo apt install snapd -y

# Enable dan start snapd socket
echo -e "\n>> Mengaktifkan dan memulai snapd.socket..."
sudo systemctl enable --now snapd.socket

# Install Multipass
echo -e "\n>> Menginstall Multipass..."
sudo snap install multipass

# Verifikasi instalasi Multipass
echo -e "\n>> Memeriksa versi Multipass..."
multipass --version

# Download paket instalasi
echo -e "\n>> Mengunduh paket instalasi Titan Agent..."
wget https://pcdn.titannet.io/test4/bin/agent-linux.zip

# Buat direktori instalasi
echo -e "\n>> Membuat direktori instalasi..."
mkdir -p /opt/titanagent

# Ekstrak paket instalasi
echo -e "\n>> Mengekstrak paket instalasi..."
unzip agent-linux.zip -d /opt/titanagent
cd /opt/titanagent || { echo -e "\n** Gagal masuk ke direktori /opt/titanagent **"; exit 1; }

# Meminta pengguna memasukkan key
prompt_key

# Jalankan Titan Agent di screen
echo -e "\n>> Menjalankan Titan Agent dalam sesi screen..."
screen -dmS titan_agent ./agent --working-dir=/opt/titanagent --server-url=https://test4-api.titannet.io --key="$user_key"

# Pesan akhir
echo -e "\n============================================"
echo "       Instalasi Selesai! Titan Agent       "
echo "    Sedang Berjalan di Sesi Screen 'titan_agent'."
echo "============================================"
echo -e "\n>> Jangan lupa bergabung dengan komunitas kami di Telegram!"
echo "   Klik di sini untuk bergabung: https://t.me/airdrop_node"
echo -e "============================================\n"
