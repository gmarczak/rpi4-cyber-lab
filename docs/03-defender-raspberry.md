# 03 — Obrońca: honeypot i monitoring na Raspberry

Raspberry pełni rolę obrońcy: udaje podatne urządzenie (honeypot) i monitoruje ruch. Każde połączenie do niego to sygnał, że coś skanuje sieć.

## 3a. Honeypot — OpenCanary

OpenCanary udaje usługi (SSH, WWW, FTP...). Nikt prawdziwy nie ma powodu się z nimi łączyć, więc każde połączenie to alert.

```bash
sudo apt install -y python3-pip python3-venv python3-dev
python3 -m venv ~/canary
source ~/canary/bin/activate
pip install opencanary scapy
opencanaryd --copyconfig
```

Config pojawi się w `~/.opencanary.conf`. Włącz wybrane usługi-pułapki, ustawiając ich `enabled` na `true` (przykład: [`../config/opencanary/opencanary.conf.example`](../config/opencanary/opencanary.conf.example)).

Uruchomienie **z uprawnieniami roota** (porty 21 i 80 tego wymagają):

```bash
sudo ~/canary/bin/opencanaryd --start
```

Alerty lądują w `/var/tmp/opencanary.log` (można też wysyłać na e-mail).

```bash
tail -f /var/tmp/opencanary.log
```

## 3b. Monitoring ruchu — Suricata

Suricata analizuje ruch sieciowy i dopasowuje go do reguł znanych ataków.

```bash
sudo apt install -y suricata
sudo suricata-update            # pobiera reguły
sudo systemctl enable --now suricata
```

Alerty:

```bash
sudo tail -f /var/log/suricata/fast.log
```

> ⚠️ **Zakres:** Suricata na Pi widzi tylko ruch **do/z samego Pi**. Ataki na cele w sieci wirtualnej komputera przez Pi nie przechodzą — patrz [network-topology.md](network-topology.md).

## 3c. Podgląd ruchu — ntopng (opcjonalnie)

```bash
sudo apt install -y ntopng
sudo systemctl enable --now ntopng
```

Panel: `http://ADRES_PI:3000` (domyślnie `admin`/`admin` — **zmień od razu**). Widać, które urządzenie z czym się łączy.

## Skrypty pomocnicze

- [`../config/scripts/setup-defender.sh`](../config/scripts/setup-defender.sh) — instaluje wszystko za jednym razem
- [`../config/scripts/check-logs.sh`](../config/scripts/check-logs.sh) — podgląd alertów z obu źródeł

➡️ Następnie: [04 — Atakujący](04-attacker-kali.md)
