#!/bin/bash

# setup_dji_360.sh - Configures mpv to play DJI Osmo 360 (.osv) videos on Linux

set -e

echo "=== DJI Osmo 360 Player Configurator ==="
echo ""

# 1. Verify requirements
if ! command -v mpv &> /dev/null; then
    echo "Error: 'mpv' is not installed. Please install it, for example:"
    echo "  sudo pacman -S mpv"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "Error: 'ffmpeg' is not installed. Please install it, for example:"
    echo "  sudo pacman -S ffmpeg"
    exit 1
fi

# 2. Create mpv configuration directories if they do not exist
MPV_CONF_DIR="$HOME/.config/mpv"
mkdir -p "$MPV_CONF_DIR/scripts"
mkdir -p "$MPV_CONF_DIR/shaders"
mkdir -p "$MPV_CONF_DIR/script-opts"

# 3. Get local repository directory
REPO_DIR="$(dirname "$(readlink -f "$0")")"

echo "Installing mpv360 plugin components..."
cp "$REPO_DIR/scripts/mpv360.lua" "$MPV_CONF_DIR/scripts/"
cp "$REPO_DIR/shaders/mpv360.glsl" "$MPV_CONF_DIR/shaders/"
cp "$REPO_DIR/script-opts/mpv360.conf" "$MPV_CONF_DIR/script-opts/"

# 4. Install wrapper scripts in ~/.local/bin/
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
WRAPPER_PATH="$BIN_DIR/dji-play-360"
GUI_PATH="$BIN_DIR/dji-play-360-gui"

echo "Installing wrapper script: dji-play-360..."
cp "$REPO_DIR/bin/dji-play-360" "$WRAPPER_PATH"
chmod +x "$WRAPPER_PATH"

echo "Installing GUI script: dji-play-360-gui..."
cp "$REPO_DIR/bin/dji-play-360-gui" "$GUI_PATH"
chmod +x "$GUI_PATH"

# Pre-create the cache directory
mkdir -p "$HOME/.cache/dji-play-360"

# 5. Install file association and desktop application entry (.desktop)
echo "Installing file associations and desktop launcher..."
APP_DIR="$HOME/.local/share/applications"
MIME_DIR="$HOME/.local/share/mime/packages"
mkdir -p "$APP_DIR"
mkdir -p "$MIME_DIR"

# Substitute relative executable command with the absolute wrapper path (crucial for Plasma KDE and other DEs)
sed "s|Exec=dji-play-360|Exec=$WRAPPER_PATH|g" "$REPO_DIR/dji-play-360.desktop" > "$APP_DIR/dji-play-360.desktop"
chmod +x "$APP_DIR/dji-play-360.desktop"

cp "$REPO_DIR/dji-osv-mime.xml" "$MIME_DIR/"

if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$APP_DIR"
fi

if command -v update-mime-database &> /dev/null; then
    update-mime-database "$HOME/.local/share/mime"
fi

echo ""
echo "=== Configuration Completed Successfully! ==="
echo ""
echo "To play your DJI videos in 360° from the terminal, run:"
echo "  dji-play-360 path/to/video.osv"
echo ""
echo "Or start the launcher GUI by typing:"
echo "  dji-play-360"
echo ""
echo "Performance presets:"
echo "  --fast      Downscales each lens to 1.4K (balanced choice)"
echo "  --fastest   Downscales each lens to 1K (maximum performance)"
echo ""
echo "Note: Make sure '$BIN_DIR' is present in your PATH."
echo "If it is not, you can add this line to your ~/.bashrc or ~/.zshrc:"
echo "  export PATH=\$PATH:\$HOME/.local/bin"
echo ""
