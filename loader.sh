#!/bin/bash

# Fungsi untuk menampilkan loader
show_loader() {
  local spinner='|/-\'
  local delay=0.1
  while true; do
    for i in ${spinner}; do
      echo -ne "\r$i"
      sleep $delay
    done
  done
}

# Menjalankan loader di latar belakang
show_loader &
LOADER_PID=$!

# Simulasikan proses dengan sleep
echo "Processing, please wait..."
sleep 10

# Hentikan loader
kill $LOADER_PID
echo -e "\rDone!            "
