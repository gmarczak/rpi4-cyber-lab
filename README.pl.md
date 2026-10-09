# Domowy cyberlab na Raspberry Pi 4 🛡️⚔️

Domowy lab cyberbezpieczeństwa zbudowany na Raspberry Pi 4. Dokumentuję cały proces — od rozpakowania po działający zestaw **blue team (obrona) / red team (atak)**.

🇬🇧 **English:** [README.md](README.md)

> ⚠️ **Etyka i prawo:** Wszystko tutaj działa na **moim własnym sprzęcie i mojej własnej sieci**, albo na platformach, które wprost na to pozwalają. Cele ataku stoją w odizolowanej sieci wirtualnej, nigdy nie wystawione do internetu. Skanowanie i atakowanie cudzych systemów jest nielegalne (art. 267 kk). To repo służy do nauki bezpieczeństwa na sprzęcie, który kontroluję.

## O co chodzi

Dwie role na dwóch maszynach:

- **Raspberry Pi 4 = obrońca (blue team).** Działa 24/7, pełni rolę honeypota (OpenCanary) i monitoruje ruch sieciowy (Suricata, ntopng). Zapisuje każdego, kto go sonduje.
- **Laptop/PC = atakujący (red team).** Kali Linux w VirtualBoxie plus celowo podatne cele (DVWA, OWASP Juice Shop) w odizolowanej sieci.

Pętla nauki: **przeprowadź atak → sprawdź w logach, czy obrońca go złapał → dostrój reguły.**

![Diagram sieci](diagrams/network-topology.svg)

## Sprzęt

| Część | Model | Cena (zł) |
|-------|-------|-----------|
| Płytka | Raspberry Pi 4 Model B, 4GB | 479,90 |
| Zasilacz | Oryginalny USB-C 5,1V/3A | 37,90 |
| Obudowa | Oficjalna Pi 4B (grafitowa) | 23,90 |
| Radiatory | Zestaw do Pi 4B (×4) | 4,90 |
| Karta (system) | SanDisk Extreme microSD 64GB A2 | 139,00 |
| Pendrive (logi) | SanDisk Ultra Fit 64GB USB 3.1 | 79,90 |

Szczegóły: [`docs/01-hardware.md`](docs/01-hardware.md).

## Dokumentacja budowy

1. [Sprzęt i lista zakupów](docs/01-hardware.md)
2. [Instalacja systemu — nagranie karty i pierwszy start](docs/02-os-setup.md)
   - [Pendrive na logi — formatowanie i montowanie, komenda po komendzie](docs/02b-usb-log-drive.md)
   - [Zabezpieczenie SSH — klucz, wyłączenie hasła, port, firewall](docs/02c-ssh-hardening.md)
   - [Sieć — tylko kabel i stały adres IP](docs/02d-network-basics.md)
3. [Obrońca — honeypot i monitoring na Pi](docs/03-defender-raspberry.md)
4. [Atakujący — Kali i cele na PC](docs/04-attacker-kali.md)
5. [Pierwsze ćwiczenie — pętla atak-wykrycie](docs/05-first-exercise.md)
6. [Topologia sieci — wyjaśnienie](docs/network-topology.md)

🗺️ **Roadmap:** [`ROADMAP.md`](ROADMAP.md) — lista zadań z odhaczaniem, co zrobione i co dalej.

📓 **Dziennik budowy:** [`build-log/build-log.md`](build-log/build-log.md) — datowane notatki, co zrobione i na co się natknąłem.

⚙️ **Configi i skrypty:** [`config/`](config/) — przykładowy config OpenCanary, notatki do Suricaty, skrypty pomocnicze (bez haseł i prawdziwych IP).

## Status

🚧 Budowa w toku — Raspberry złożone i dostępne przez SSH (2026-10-09). Śledź [dziennik budowy](build-log/build-log.md).

## Licencja

[MIT](LICENSE) — rób co chcesz, bez gwarancji.
