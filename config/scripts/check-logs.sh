#!/usr/bin/env bash
# check-logs.sh
# Czytelny podglad alertow honeypota (OpenCanary) i IDS-a (Suricata) na Raspberry.
# Readable view of honeypot + IDS alerts on the Raspberry Pi.
#
# Uzycie / usage:
#   bash check-logs.sh          # ostatnie 15 zdarzen z kazdego zrodla
#   bash check-logs.sh 50       # ostatnie 50
#   bash check-logs.sh 50 --all # razem z komunikatami startowymi honeypota (logtype 1001)

set -euo pipefail

N="${1:-15}"
ALL="${2:-}"
CANARY=/var/log/opencanary/opencanary.log
FAST=/var/log/suricata/fast.log

echo "=== OpenCanary (honeypot) — ostatnie $N zdarzen / last $N events ==="
if sudo test -f "$CANARY"; then
  sudo cat "$CANARY" | python3 -c '
import sys, json
n, show_all = int(sys.argv[1]), sys.argv[2] == "--all"
names = {
    1001: "start honeypota",
    2000: "FTP logowanie",
    3000: "HTTP wejscie na strone",
    3001: "HTTP logowanie",
    4000: "SSH polaczenie",
    4001: "SSH wersja klienta",
    4002: "SSH logowanie",
}
rows = []
for line in sys.stdin:
    try:
        e = json.loads(line)
    except ValueError:
        continue
    t = e.get("logtype")
    if t == 1001 and not show_all:
        continue
    d = e.get("logdata") or {}
    extra = ""
    if "USERNAME" in d or "PASSWORD" in d:
        extra = "login: %s  haslo: %s" % (d.get("USERNAME", "?"), d.get("PASSWORD", "?"))
    elif "REMOTEVERSION" in d:
        extra = d["REMOTEVERSION"]
    elif "PATH" in d:
        extra = d["PATH"]
    elif "msg" in d:
        extra = str(d["msg"].get("logdata", ""))
    when = str(e.get("local_time_adjusted", ""))[:19]
    src = e.get("src_host") or "-"
    port = e.get("dst_port", "")
    rows.append("%s  %-15s -> :%-4s  %-22s %s" % (when, src, port, names.get(t, "logtype %s" % t), extra))
for r in rows[-n:]:
    print(r)
if not rows:
    print("(brak zdarzen / no events)")
' "$N" "$ALL"
else
  echo "(brak pliku / no file yet)"
fi

echo
echo "=== Suricata (IDS) — ostatnie $N alertow / last $N alerts ==="
if sudo test -s "$FAST"; then
  sudo tail -n "$N" "$FAST" | sed -E 's/ \[\*\*\] / | /g; s/\[Classification: ([^]]*)\] //; s/\[Priority: ([0-9])\]/P\1/'
else
  echo "(brak alertow / no alerts yet)"
fi

echo
echo "Podglad na zywo / live follow:"
echo "  sudo tail -f $CANARY"
echo "  sudo tail -f $FAST"
