#!/bin/bash

show() {
  echo -e "\033[1;35m$1\033[0m"
}

if ! [ -x "$(command -v curl)" ]; then
  show "curl ora terinstal. Mangga install curl kanggo nerusake."
  exit 1
else
  show "curl wis terinstal."
fi

IP=$(curl -s ifconfig.me)
USERNAME=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()_+' | head -c 5; echo)
PASSWORD=$(< /dev/urandom tr -dc 'A-Za-z0-9!@#$%^&*()_+' | head -c 10; echo)
CREDENTIALS_FILE="$HOME/airdropnode-browser-credentials.json"

cat <<EOL > "$CREDENTIALS_FILE"
{
  "username": "$USERNAME",
  "password": "$PASSWORD"
}
EOL

if ! [ -x "$(command -v docker)" ]; then
  show "Docker ora terinstal. Instal Docker..."
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  if [ -x "$(command -v docker)" ]; then
    show "Instalasi Docker berhasil."
  else
    show "Instalasi Docker gagal."
    exit 1
  fi
else
  show "Docker wis terinstal."
fi

show "Ngundhuh gambar Docker Chromium paling anyar..."
if ! sudo docker pull linuxserver/chromium:latest; then
  show "Gagal ngundhuh gambar Docker Chromium."
  exit 1
else
  show "Gambar Docker Chromium wis sukses diundhuh."
fi

mkdir -p "$HOME/chromium/config"

if [ "$(docker ps -q -f name=browser)" ]; then
    show "Kontainer Docker Chromium wis mlaku."
else
    show "Mbukak Kontainer Docker Chromium..."
    sudo docker run -d --name browser -e TITLE=AirdropNode -e DISPLAY=:1 -e PUID=1000 -e PGID=1000 -e CUSTOM_USER="$USERNAME" -e PASSWORD="$PASSWORD" -e LANGUAGE=en_US.UTF-8 -v "$HOME/chromium/config:/config" -p 3000:3000 -p 3001:3001 --shm-size="1gb" --restart unless-stopped lscr.io/linuxserver/chromium:latest
    if [ $? -eq 0 ]; then
        show "Kontainer Docker Chromium wis sukses dibukak."
    else
        show "Gagal mbukak kontainer Docker Chromium."
    fi
fi

show "Klik ing link iki http://$IP:3000/ utawa https://$IP:3001/ kanggo mbukak browser eksternal"
show "Lebokake username iki: $USERNAME ing browser"
show "Lebokake password iki: $PASSWORD ing browser"
show "Pastikan nyalin kredensial iki supaya bisa ngakses browser eksternal. Sampeyan uga bisa nemokake kredensial browser iki saka file $CREDENTIALS_FILE"
