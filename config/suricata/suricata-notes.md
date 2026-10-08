# Suricata — notatki / notes

## Instalacja / Install

```bash
sudo apt install -y suricata
sudo suricata-update
sudo systemctl enable --now suricata
```

## Interfejs / Interface

Suricata domyślnie nasłuchuje na wskazanym interfejsie. Sprawdź nazwę (`ip a` — zwykle `eth0` na Pi) i upewnij się, że zgadza się w `/etc/suricata/suricata.yaml` (sekcja `af-packet`).

Suricata listens on a named interface. Check it (`ip a` — usually `eth0` on the Pi) and make sure it matches `/etc/suricata/suricata.yaml` (the `af-packet` section).

## Reguły / Rules

```bash
sudo suricata-update            # pobiera/aktualizuje reguły / fetch & update rules
sudo suricata-update list-sources
```

## Alerty / Alerts

```bash
sudo tail -f /var/log/suricata/fast.log     # szybki podgląd / quick view
sudo tail -f /var/log/suricata/eve.json     # pełne zdarzenia (JSON) / full events
```

## Test

Z Kali (przez Bridged) zrób głośny skan Pi i sprawdź, czy pojawia się alert:
From Kali (over Bridged) run a loud scan of the Pi and check for an alert:

```bash
nmap -sV --version-intensity 9 ADRES_RASPBERRY
```

## ⚠️ Zakres / Scope

Suricata na Pi widzi tylko ruch do/z samego Pi — nie ruch między maszynami w Internal Network komputera.
Suricata on the Pi only sees traffic to/from the Pi itself — not traffic between VMs in the PC's Internal Network.
