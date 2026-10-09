#!/usr/bin/env bash
# check-logs.sh
# Szybki podglad alertow honeypota i IDS-a na Raspberry.
# Quick view of honeypot + IDS alerts on the Raspberry Pi.

set -euo pipefail

LOG=/var/log/opencanary/opencanary.log
echo "=== OpenCanary (honeypot) — $LOG ==="
if sudo test -f "$LOG"; then
  sudo tail -n 20 "$LOG"
else
  echo "(brak pliku / no file yet — honeypot nie zapisal jeszcze nic)"
fi

echo
echo "=== Suricata (IDS) — /var/log/suricata/fast.log ==="
if [ -f /var/log/suricata/fast.log ]; then
  sudo tail -n 20 /var/log/suricata/fast.log
else
  echo "(brak pliku / no file yet)"
fi

echo
echo "Podglad na zywo / live follow:"
echo "  sudo tail -f /var/log/opencanary/opencanary.log"
echo "  sudo tail -f /var/log/suricata/fast.log"
