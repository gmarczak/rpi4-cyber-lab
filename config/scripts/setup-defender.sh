#!/usr/bin/env bash
# setup-defender.sh
# Instaluje obronę na Raspberry: OpenCanary (honeypot) + Suricata + ntopng.
# Installs the defender stack on the Raspberry Pi: OpenCanary + Suricata + ntopng.
#
# Uruchom na Raspberry (Raspberry Pi OS Lite) / Run on the Raspberry Pi:
#   chmod +x setup-defender.sh && ./setup-defender.sh
#
# UWAGA / NOTE: skrypt NIE zawiera haseł ani adresów. OpenCanary skonfiguruj
# ręcznie wg docs/03-defender-raspberry.md (krok 10).

set -euo pipefail

echo "[*] System update..."
sudo apt update && sudo apt full-upgrade -y

echo "[*] OpenCanary (honeypot) w /opt/opencanary (szczegoly: docs/03, czesc 1)..."
sudo apt install -y python3-dev python3-pip python3-venv libssl-dev libpcap-dev
sudo python3 -m venv /opt/opencanary
sudo /opt/opencanary/bin/pip install --upgrade pip
sudo /opt/opencanary/bin/pip install opencanary
# opencanaryd woła python3 z PATH, a sudo podmienia PATH — stąd env PATH=...
sudo env PATH=/opt/opencanary/bin:$PATH opencanaryd --copyconfig
id opencanary >/dev/null 2>&1 || sudo useradd --system --no-create-home --shell /usr/sbin/nologin opencanary
sudo install -d -o opencanary -g opencanary -m 750 /var/log/opencanary
echo "    -> ustaw pulapki w /etc/opencanaryd/opencanary.conf (docs/03, krok 10)"
echo "    -> otworz porty: sudo ufw allow 21/tcp; 22/tcp; 80/tcp (po jednej komendzie)"
echo "    -> usluga: sudo cp config/systemd/opencanary.service /etc/systemd/system/ && sudo systemctl daemon-reload && sudo systemctl enable --now opencanary"

echo "[*] Suricata (IDS)..."
sudo apt install -y suricata
sudo suricata-update
sudo systemctl enable --now suricata

echo "[*] ntopng (traffic view)..."
sudo apt install -y ntopng
sudo systemctl enable --now ntopng
echo "    -> panel: http://<ADRES_PI>:3000  (admin/admin — ZMIEN haslo!)"

echo "[+] Gotowe. Sprawdz logi: ./check-logs.sh"
