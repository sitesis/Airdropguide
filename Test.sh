#!/bin/bash

# Meminta input email, password, dan proxy SOCKS5
read -p "Masukkan email: " email
read -sp "Masukkan password: " password
echo
read -p "Masukkan proxy SOCKS5 (format: socks5://user:pass@host:port atau kosongkan jika tidak menggunakan): " proxy

# Membuat file docker-compose.yml
cat <<EOF > docker-compose.yml
version: "3.9"

services:
  grass:
    container_name: grass
    hostname: my_device
    image: mrcolorrain/grass
    environment:
      - GRASS_USER=${email}
      - GRASS_PASS=${password}
EOF

# Tambahkan konfigurasi proxy jika ada
if [ -n "$proxy" ]; then
  echo "      - SOCKS5_PROXY=${proxy}" >> docker-compose.yml
fi

# Lanjutkan dengan bagian akhir file
cat <<EOF >> docker-compose.yml
    restart: unless-stopped
EOF

# Menjalankan kontainer menggunakan Docker Compose
docker-compose up -d

echo "Kontainer 'grass' telah dijalankan dengan email $email dan konfigurasi proxy SOCKS5 ${proxy}."
