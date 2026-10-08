#!/usr/bin/env bash
# setup-defender.sh
# Instaluje obronę na Raspberry: OpenCanary (honeypot) + Suricata + ntopng.
# Installs the defender stack on the Raspberry Pi: OpenCanary + Suricata + ntopng.
#
# Uruchom na Raspberry (Raspberry Pi OS Lite) / Run on the Raspberry Pi:
#   chmod +x setup-defender.sh && ./setup-defender.sh
#
# UWAGA / NOTE: skrypt NIE zawiera haseł ani adresów. OpenCanary skonfiguruj
# ręcznie wg config/opencanary/opencanary.conf.example.

set -euo pipefail

echo "[*] System update..."
sudo apt update && sudo apt full-upgrade -y

echo "[*] OpenCanary (honeypot) in a venv..."
sudo apt install -y python3-pip python3-venv python3-dev
python3 -m venv "$HOME/canary"
# shellcheck disable=SC1091
source "$HOME/canary/bin/activate"
pip install --upgrade pip
pip install opencanary scapy
opencanaryd --copyconfig || true
echo "    -> edytuj ~/.opencanary.conf (patrz config/opencanary/opencanary.conf.example)"
echo "    -> start:  sudo $HOME/canary/bin/opencanaryd --start   (root: porty 21/80)"

echo "[*] Suricata (IDS)..."
sudo apt install -y suricata
sudo suricata-update
sudo systemctl enable --now suricata

echo "[*] ntopng (traffic view)..."
sudo apt install -y ntopng
sudo systemctl enable --now ntopng
echo "    -> panel: http://<ADRES_PI>:3000  (admin/admin — ZMIEN haslo!)"

echo "[+] Gotowe. Sprawdz logi: ./check-logs.sh"
