# Roadmap 🗺️

Lista zadań z odhaczaniem. Po skończeniu zadania zmień `[ ]` na `[x]` i dopisz wpis w [dzienniku budowy](build-log/build-log.md).
Task checklist. When a task is done, change `[ ]` to `[x]` and add an entry to the [build log](build-log/build-log.md).

**Cel końcowy / End goal:** atakuję Raspberry z Kali, a obrońca to wykrywa i zapisuje w logach. / I attack the Pi from Kali and the defender detects and logs it.

---

## Etap 0: Sprzęt i system / Hardware & OS ✅

- [x] Zamówienie części / Parts ordered (2026-10-08)
- [x] Raspberry Pi OS Lite (64-bit) nagrany w Imagerze / flashed with Imager
- [x] Radiatory i obudowa / Heatsinks and case
- [x] Pierwsze logowanie SSH (`honeypi.local`) / First SSH login (2026-10-09)

## Etap 1: Fundamenty / Foundations ⬅️ teraz / now

- [x] Aktualizacja systemu (`sudo apt update && sudo apt full-upgrade -y`) / System update
- [ ] Stały adres IP: rezerwacja DHCP w routerze / Static IP via DHCP reservation
- [ ] Logowanie kluczem SSH zamiast hasła, potem wyłączenie haseł / SSH key login, then disable passwords
- [ ] Prawdziwy SSH na innym porcie (np. 2222), żeby port 22 zwolnić dla honeypota / Real SSH on another port so port 22 is free for the honeypot
- [ ] Firewall (`ufw`): tylko potrzebne porty / only the ports we need
- [x] Pendrive sformatowany i zamontowany na stałe (`/mnt/logs`) / USB stick formatted and auto-mounted — [docs/02b](docs/02b-usb-log-drive.md)
- [ ] Logi kierowane na pendrive zamiast karty / Logs written to the USB stick, not the SD card
- [ ] Wyłączone Wi-Fi i Bluetooth (Pi chodzi po kablu) / Wi-Fi and Bluetooth off (wired only)

## Etap 2: Obrońca / Defender — [docs/03](docs/03-defender-raspberry.md)

- [ ] OpenCanary zainstalowany w venv / installed in a venv
- [ ] Usługi-pułapki włączone: SSH (22), HTTP (80), FTP (21) / Trap services enabled
- [ ] OpenCanary jako usługa systemd, startuje sam po restarcie / systemd service, starts on boot
- [ ] Pierwszy alert honeypota (test z własnego PC) / First honeypot alert (test from my PC)
- [ ] Suricata zainstalowana, reguły pobrane (`suricata-update`) / installed, rules fetched
- [ ] Suricata wykrywa skan / detects a scan
- [ ] ntopng z nowym hasłem (opcjonalnie) / with a new password (optional)
- [ ] `check-logs.sh` pokazuje alerty z obu źródeł / shows alerts from both sources

## Etap 3: Atakujący / Attacker — [docs/04](docs/04-attacker-kali.md)

- [ ] VirtualBox na PC / on the PC
- [ ] Kali w VM, hasło zmienione / Kali VM, password changed
- [ ] Dwie karty sieciowe: Internal + Bridged / Two network adapters
- [ ] DVWA tylko w sieci wewnętrznej / DVWA on the internal network only
- [ ] Juice Shop tylko w sieci wewnętrznej / Juice Shop on the internal network only

## Etap 4: Pętla atak–wykrycie / Attack–detect loop — [docs/05](docs/05-first-exercise.md)

- [ ] `nmap -sV` z Kali na Raspberry / from Kali against the Pi
- [ ] Ten skan widoczny w logach OpenCanary i Suricaty / The scan shows up in both logs
- [ ] Zrzuty i wnioski w dzienniku / Screenshots and notes in the build log
- [ ] Własna reguła Suricaty, która łapie coś, co wcześniej przeszło / A custom Suricata rule that catches something it missed

## Etap 5: Nauka i rozbudowa / Learning & beyond

- [ ] TryHackMe: ścieżka „Pre Security” / “Pre Security” path
- [ ] TryHackMe: „Cyber Security 101”
- [ ] DVWA: wszystkie kategorie na poziomie *low* / all categories on *low*
- [ ] Juice Shop: pierwsze 10 wyzwań / first 10 challenges
- [ ] Alerty na e-mail albo telefon / Alerts by e-mail or phone
- [ ] Panel z alertami (np. Grafana) / Alerts dashboard
- [ ] Hack The Box: pierwsza maszyna / first machine
