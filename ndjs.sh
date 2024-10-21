#!/bin/bash

# Fungsi untuk memeriksa apakah perintah tersedia
periksa_perintah() {
    command -v "$1" >/dev/null 2>&1
}

# Fungsi untuk menginstal NVM
pasang_nvm() {
    # Beralih ke direktori home untuk menghindari masalah jalur
    cd ~ || exit

    # Instal NVM
    echo "Menginstal NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

    # Muat NVM ke dalam shell saat ini
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Fungsi untuk menginstal Node.js dan npm
pasang_node() {
    echo "Menginstal Node.js..."
    nvm install node
}

# Fungsi untuk memperbarui profil untuk NVM
perbarui_profil() {
    echo "Memperbarui profil untuk sesi mendatang..."
    {
        echo "# Konfigurasi NVM"
        echo "export NVM_DIR=\"$HOME/.nvm\""
        echo "[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\""
        echo "[ -s \"$NVM_DIR/bash_completion\" ] && \. \"$NVM_DIR/bash_completion\""
    } >> ~/.bashrc
}

# Periksa apakah pengguna adalah root
if [ "$(id -u)" -eq 0 ]; then
    echo "Dijalankan sebagai pengguna root."
else
    echo "Dijalankan sebagai pengguna non-root."
fi

# Periksa apakah NVM sudah terinstal
if ! periksa_perintah "nvm"; then
    echo "NVM belum terinstal."
    pasang_nvm
else
    echo "NVM sudah terinstal."
fi

# Muat NVM untuk sesi saat ini
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Periksa apakah Node.js sudah terinstal
if ! periksa_perintah "node"; then
    echo "Node.js belum terinstal."
    pasang_node
else
    echo "Node.js sudah terinstal."
fi

# Periksa apakah npm sudah terinstal
if ! periksa_perintah "npm"; then
    echo "npm belum terinstal."
    pasang_node
else
    echo "npm sudah terinstal."
fi

# Periksa apakah jalur sudah diekspor untuk shell saat ini
echo "Jalur shell saat ini:"
echo "NVM: $NVM_DIR"
echo "Node: $(command -v node)"
echo "NPM: $(command -v npm)"

# Perbarui profil untuk shell mendatang jika belum dilakukan
if ! grep -q "NVM_DIR" ~/.bashrc; then
    perbarui_profil
fi

echo "Eksekusi skrip selesai"
