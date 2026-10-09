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

## Etap 1: Fundamenty / Foundations ✅

- [x] Aktualizacja systemu (`sudo apt update && sudo apt full-upgrade -y`) / System update
- [x] Stały adres IP: rezerwacja DHCP w routerze (FunBox) / Static IP via DHCP reservation (FunBox) — [docs/02d, część 2](docs/02d-network-basics.md#część-2-stały-adres-ip)
- [x] Logowanie kluczem SSH / SSH key login — [docs/02c](docs/02c-ssh-hardening.md)
- [x] Wyłączone logowanie hasłem i jako root / Password and root login disabled — [docs/02c, część 2](docs/02c-ssh-hardening.md#część-2-wyłączenie-logowania-hasłem)
- [x] Prawdziwy SSH na porcie 2222, port 22 wolny dla honeypota / Real SSH on port 2222, port 22 free for the honeypot — [docs/02c, część 3](docs/02c-ssh-hardening.md#część-3-prawdziwy-ssh-na-porcie-2222)
- [x] Skrót `ssh honeypi` na PC / `ssh honeypi` shortcut on the PC — [docs/02c, część 4](docs/02c-ssh-hardening.md#część-4-skrót-ssh-honeypi-plik-config-na-pc)
- [x] Firewall (`ufw`): tylko port 2222 otwarty / only port 2222 open — [docs/02c, część 5](docs/02c-ssh-hardening.md#część-5-firewall-ufw)
- [x] Pendrive sformatowany i zamontowany na stałe (`/mnt/logs`) / USB stick formatted and auto-mounted — [docs/02b](docs/02b-usb-log-drive.md)
- [x] Logi kierowane na pendrive zamiast karty / Logs written to the USB stick, not the SD card — [docs/02b, część 2](docs/02b-usb-log-drive.md#część-2-logi-z-varlog-na-pendrive)
- [x] Wyłączone Wi-Fi i Bluetooth (Pi chodzi po kablu) / Wi-Fi and Bluetooth off (wired only) — [docs/02d](docs/02d-network-basics.md)

## Etap 2: Obrońca / Defender ⬅️ teraz / now — [docs/03](docs/03-defender-raspberry.md)

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
