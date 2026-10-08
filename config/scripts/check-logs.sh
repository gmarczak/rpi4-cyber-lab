#!/usr/bin/env bash
# check-logs.sh
# Szybki podglad alertow honeypota i IDS-a na Raspberry.
# Quick view of honeypot + IDS alerts on the Raspberry Pi.

set -euo pipefail

echo "=== OpenCanary (honeypot) — /var/tmp/opencanary.log ==="
if [ -f /var/tmp/opencanary.log ]; then
  tail -n 20 /var/tmp/opencanary.log
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
echo "  tail -f /var/tmp/opencanary.log"
echo "  sudo tail -f /var/log/suricata/fast.log"
