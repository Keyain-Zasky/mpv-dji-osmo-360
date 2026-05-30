#!/bin/bash

# setup_dji_360.sh - Configura mpv per riprodurre video DJI Osmo 360 (.osv) su Arch Linux / Nvidia GPU

set -e

echo "=== DJI Osmo 360 Player Configurator ==="
echo ""

# 1. Verifica dei requisiti
if ! command -v mpv &> /dev/null; then
    echo "Errore: 'mpv' non è installato. Installalo con:"
    echo "  sudo pacman -S mpv"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "Errore: 'ffmpeg' non è installato. Installalo con:"
    echo "  sudo pacman -S ffmpeg"
    exit 1
fi

# 2. Crea le directory di configurazione di mpv se non esistono
MPV_CONF_DIR="$HOME/.config/mpv"
mkdir -p "$MPV_CONF_DIR/scripts"
mkdir -p "$MPV_CONF_DIR/shaders"
mkdir -p "$MPV_CONF_DIR/script-opts"

# 3. Ottieni la directory del repository locale
REPO_DIR="$(dirname "$(readlink -f "$0")")"

echo "Installazione del plugin mpv360..."
cp "$REPO_DIR/scripts/mpv360.lua" "$MPV_CONF_DIR/scripts/"
cp "$REPO_DIR/shaders/mpv360.glsl" "$MPV_CONF_DIR/shaders/"
cp "$REPO_DIR/script-opts/mpv360.conf" "$MPV_CONF_DIR/script-opts/"

# 4. Installa lo script wrapper in ~/.local/bin/
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
WRAPPER_PATH="$BIN_DIR/dji-play-360"

echo "Installazione dello script wrapper dji-play-360..."
cp "$REPO_DIR/bin/dji-play-360" "$WRAPPER_PATH"
chmod +x "$WRAPPER_PATH"

# 5. Installa l'associazione file e il lanciatore desktop (.desktop)
echo "Installazione associazione file ed elemento desktop..."
APP_DIR="$HOME/.local/share/applications"
MIME_DIR="$HOME/.local/share/mime/packages"
mkdir -p "$APP_DIR"
mkdir -p "$MIME_DIR"

cp "$REPO_DIR/dji-play-360.desktop" "$APP_DIR/"
cp "$REPO_DIR/dji-osv-mime.xml" "$MIME_DIR/"

if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$APP_DIR"
fi

if command -v update-mime-database &> /dev/null; then
    update-mime-database "$HOME/.local/share/mime"
fi

echo ""
echo "=== Configurazione Completata con Successo! ==="
echo ""
echo "Per riprodurre i tuoi video DJI in 360°, usa il seguente comando:"
echo "  dji-play-360 percorso/del/video.osv"
echo ""
echo "Opzioni di performance:"
echo "  --fast      Downscaling a 1.4K per lente (ottimo compromesso)"
echo "  --fastest   Downscaling a 1K per lente (massime performance)"
echo ""
echo "Nota: Assicurati che '$BIN_DIR' sia presente nel tuo PATH."
echo "Se non lo è, puoi aggiungere questa riga al tuo ~/.bashrc o ~/.zshrc:"
echo "  export PATH=\$PATH:\$HOME/.local/bin"
echo ""
