#!/bin/bash

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 5

# URL untuk mengunduh file
INIMINER_URL="https://github.com/Project-InitVerse/ini-miner/releases/download/v1.0.0/iniminer-linux-x64"

# Nama file miner
INIMINER_FILE="iniminer-linux-x64"

# Nama sesi screen

# ==============================================
# Fungsi: Memperbarui Sistem dan Menginstal Screen
# ==============================================
}

# ==============================================
# Fungsi: Mengunduh File Miner
# ==============================================
download_inichain() {
    echo
    echo "========================================"
    echo "⬇️  Mengunduh file InitVerse Miner..."
    echo "========================================"
    wget -q $INIMINER_URL -O $INIMINER_FILE
    if [ $? -eq 0 ]; then
        echo "✅ File berhasil diunduh."
    else
        echo "❌ Gagal mengunduh file. Periksa URL atau koneksi internet Anda."
        exit 1
    fi
    echo
}

# ==============================================
# Fungsi: Memberikan Izin Eksekusi
# ==============================================
give_permission() {
    echo
    echo "========================================"
    echo "🔑 Memberikan izin eksekusi ke file..."
    echo "========================================"
    chmod +x $INIMINER_FILE
    if [ $? -eq 0 ]; then
        echo "✅ Izin eksekusi berhasil diberikan."
    else
        echo "❌ Gagal memberikan izin eksekusi."
        exit 1
    fi
    echo
}

# ==============================================
# Fungsi: Menjalankan Miner dalam Screen
# ==============================================
run_inichain_miner() {
    echo
    echo "========================================"
    echo "🚀 Menjalankan InitVerse Miner dalam screen..."
    echo "========================================"
    read -p "Masukkan alamat dompet Anda: " WALLET_ADDRESS
    read -p "Masukkan nama Worker (misal: Worker001): " WORKER_NAME

    # Validasi input
    if [[ -z "$WALLET_ADDRESS" || -z "$WORKER_NAME" ]]; then
        echo "❌ Alamat dompet atau nama Worker tidak boleh kosong."
        exit 1
    fi

    echo
    echo "Pilih pool URL mainnet:"
    echo "1. pool-a.yatespool.com:31588"
    echo "2. pool-b.yatespool.com:32488"
    read -p "Masukkan pilihan Anda (1 atau 2): " POOL_CHOICE

    # Pilih URL pool berdasarkan pilihan
    case $POOL_CHOICE in
        1)
            POOL_URL="stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@pool-a.yatespool.com:31588"
            ;;
        2)
            POOL_URL="stratum+tcp://${WALLET_ADDRESS}.${WORKER_NAME}@pool-b.yatespool.com:32488"
            ;;
        *)
            echo "❌ Pilihan tidak valid. Harap masukkan 1 atau 2."
            exit 1
            ;;
    esac

    nohup ./$INIMINER_FILE --pool $POOL_URL > / dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ InitVerse Miner sedang berjalan dalam sesi screen bernama '$SCREEN_NAME'."
        echo "ℹ️  Gunakan perintah berikut untuk memantau:"
        echo "   ps aux | grep iniminer"
    else
        echo "❌ Gagal menjalankan InitVerse Miner."
        exit 1
    fi
    echo
}

# ==============================================
# Eksekusi Fungsi
# ==============================================
update_system_and_install_screen
download_inichain
give_permission
run_inichain_miner

echo
echo "========================================"
echo "🎉 Selesai! InitVerse Miner telah diatur dan berjalan."
echo "========================================"
