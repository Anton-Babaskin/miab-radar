#!/bin/bash
set -e

INSTALL_PATH="/usr/local/bin/miab-radar"

echo "[+] Installing miab-radar..."
cp miab-radar.sh $INSTALL_PATH
chmod +x $INSTALL_PATH

echo "[+] Done. Run: miab-radar"
