# Roadmap 🗺️

Lista zadań z odhaczaniem. Po skończeniu zadania zmień `[ ]` na `[x]` i dopisz wpis w [dzienniku budowy](build-log/build-log.md).
Task checklist. When a task is done, change `[ ]` to `[x]` and add an entry to the [build log](build-log/build-log.md).

📋 **Na koniec każdego etapu:** jeden plik `docs/etap-N-podsumowanie.md` z całym etapem: cel, komendy, problemy i ich rozwiązania, kontrola stanu. / At the end of each stage: one summary file with goals, commands, problems and fixes, and a status check.

**Cel końcowy / End goal:** atakuję Raspberry z Kali, a obrońca to wykrywa i zapisuje w logach. / I attack the Pi from Kali and the defender detects and logs it.

---

## Etap 0: Sprzęt i system / Hardware & OS ✅

- [x] Zamówienie części / Parts ordered (2026-10-08)
- [x] Raspberry Pi OS Lite (64-bit) nagrany w Imagerze / flashed with Imager
- [x] Radiatory i obudowa / Heatsinks and case
- [x] Pierwsze logowanie SSH (`honeypi.local`) / First SSH login (2026-10-09)

## Etap 1: Fundamenty / Foundations ✅ — 📋 [podsumowanie / summary](docs/etap-1-podsumowanie.md)

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

## Etap 2: Obrońca / Defender ✅ — [docs/03](docs/03-defender-raspberry.md) — 📋 [podsumowanie / summary](docs/etap-2-podsumowanie.md)

- [x] OpenCanary zainstalowany w venv (`/opt/opencanary`) / installed in a venv — [docs/03, krok 1](docs/03-defender-raspberry.md#krok-1-instalacja)
- [x] Usługi-pułapki włączone: SSH (22), HTTP (80), FTP (21), porty otwarte w `ufw` / Trap services enabled — [docs/03, krok 2](docs/03-defender-raspberry.md#krok-2-konfiguracja-pułapek-i-firewall)
- [x] OpenCanary jako usługa systemd, startuje sam po restarcie / systemd service, starts on boot — [docs/03, krok 4](docs/03-defender-raspberry.md#krok-4-honeypot-jako-usługa)
- [x] Pierwszy alert honeypota (test z własnego PC) / First honeypot alert (test from my PC) — [docs/03, krok 3](docs/03-defender-raspberry.md#krok-3-pierwszy-test-i-pierwsze-alerty)
- [x] Suricata zainstalowana, reguły pobrane (`suricata-update`) / installed, rules fetched — [docs/03, część 2](docs/03-defender-raspberry.md#część-2-monitoring-ruchu--suricata)
- [x] Suricata wykrywa skaner (podpis Nmap w zapytaniu WWW z PC; pełny skan portów w Etapie 4) / detects a scanner (Nmap user agent from the PC; full port scan in stage 4) — [docs/03, krok 2](docs/03-defender-raspberry.md#krok-2-atakujący-z-domu-uruchomienie-i-pierwszy-alert)
- [x] Codzienna aktualizacja reguł Suricaty (systemd timer) / Daily Suricata rule updates — [docs/03, część 2, krok 3](docs/03-defender-raspberry.md#krok-3-codzienna-aktualizacja-reguł)
- [x] `check-logs.sh` pokazuje alerty z obu źródeł / shows alerts from both sources — [docs/03, część 3](docs/03-defender-raspberry.md#część-3-podgląd-alertów--check-logssh)
- [x] Podsumowanie etapu w [`docs/etap-2-podsumowanie.md`](docs/etap-2-podsumowanie.md) / Stage summary

## Etap 3: Atakujący / Attacker ⬅️ teraz / now — [docs/04](docs/04-attacker-kali.md)

- [ ] VirtualBox na PC / on the PC
- [ ] Kali w VM, hasło zmienione / Kali VM, password changed — dlaczego / why: [docs/04b](docs/04b-sieci-virtualbox.md#-jak-ktoś-z-sieci-domowej-mógłby-przejąć-kali-z-hasłem-kalikali)
- [ ] Dwie karty sieciowe: Internal + Bridged / Two network adapters — [docs/04b](docs/04b-sieci-virtualbox.md)
- [ ] Kali zabezpieczony: SSH wyłączone, `ufw`, skan z Raspberry bez otwartych portów / Kali hardened: SSH off, `ufw`, no open ports from the Pi — [docs/04b, obrona](docs/04b-sieci-virtualbox.md#jak-się-bronić)
- [ ] DVWA tylko w sieci wewnętrznej / DVWA on the internal network only
- [ ] Juice Shop tylko w sieci wewnętrznej / Juice Shop on the internal network only
- [ ] Podsumowanie etapu w `docs/etap-3-podsumowanie.md` / Stage summary

## Etap 4: Pętla atak–wykrycie / Attack–detect loop — [docs/05](docs/05-first-exercise.md)

- [ ] `nmap -sV` z Kali na Raspberry / from Kali against the Pi
- [ ] Ten skan widoczny w logach OpenCanary i Suricaty / The scan shows up in both logs
- [ ] Zrzuty i wnioski w dzienniku / Screenshots and notes in the build log
- [ ] Własna reguła Suricaty, która łapie coś, co wcześniej przeszło / A custom Suricata rule that catches something it missed
- [ ] Podsumowanie etapu w `docs/etap-4-podsumowanie.md` / Stage summary

## Etap 5: Nauka i rozbudowa / Learning & beyond

- [ ] TryHackMe: ścieżka „Pre Security” / “Pre Security” path
- [ ] TryHackMe: „Cyber Security 101”
- [ ] DVWA: wszystkie kategorie na poziomie *low* / all categories on *low*
- [ ] Juice Shop: pierwsze 10 wyzwań / first 10 challenges
- [ ] Alerty na e-mail albo telefon / Alerts by e-mail or phone
- [ ] Panel z alertami (np. Grafana) / Alerts dashboard
- [ ] ntopng: wykresy ruchu w sieci, z nowym hasłem (przeniesione z Etapu 2) / traffic charts, with a new password (moved from stage 2)
- [ ] Hack The Box: pierwsza maszyna / first machine
- [ ] Podsumowanie etapu w `docs/etap-5-podsumowanie.md` / Stage summary

## Misja dodatkowa: skan własnego PC / Side mission: scanning my own PC ✅ — [docs/07](docs/07-skan-wlasnego-pc.md)

Raspberry w roli atakującego skanuje mój PC z Windowsem, żeby sprawdzić, co widać z sieci domowej. / The Pi plays attacker and scans my Windows PC to see what is exposed on the home network.

- [x] Rozpoznanie sieci i portów PC od środka / Network and listening-port recon from the PC — [docs/07, komendy 1–3](docs/07-skan-wlasnego-pc.md#komendy-w-skrócie)
- [x] Skan `nmap` z Raspberry: 4 otwarte porty (135, 139, 445, 2179) / `nmap` from the Pi: 4 open ports (2026-10-09)
- [x] Reguły firewalla znalezione i zamknięte: udostępnianie w profilu Public, NetBIOS, Hyper-V / Firewall rules found and closed
- [x] Skan kontrolny: wszystkie 1000 portów `filtered` / Verification scan: all 1000 ports filtered (2026-10-09)
- [ ] Pulpit zdalny (RDP) wyłączony / Remote Desktop off
- [ ] Pełny skan TCP (`-p-`) i UDP (`-sU`) / Full TCP and UDP scan
- [ ] Decyzja o Windows 10 przed końcem ESU (13.10.2026) / Windows 10 decision before ESU ends

## Ćwiczenie dodatkowe: forensics kart microSD / Side exercise: microSD forensics — [docs/06](docs/06-forensics-karty-sd.md)

Poza etapami, na MacBooku, na dwóch starych kartach 16 GB (SanDisk klasa 10 i karta bez marki klasa 4). Nie blokuje Etapu 3. / Outside the stages, on the MacBook, with two old 16 GB cards. Does not block stage 3.

- [x] Obraz karty (`dd`) i dowód wierności sumą SHA-256 / Disk image and SHA-256 proof — [docs/06, część 1](docs/06-forensics-karty-sd.md#część-1-obraz-karty)
- [x] Odzyskiwanie usuniętych plików: TestDisk i PhotoRec, porównanie metod / Undelete vs carving — [docs/06, część 2](docs/06-forensics-karty-sd.md#część-2-co-jest-na-karcie-dwie-metody-odzysku)
- [x] Kontrolowany eksperyment: znane pliki, usunięcie, odzysk, porównanie odcisków / Controlled experiment — [docs/06, część 3](docs/06-forensics-karty-sd.md#część-3-kontrolowany-eksperyment)
- [ ] Bezpieczne kasowanie (nadpisanie zerami) i dowód, że nic nie wraca / Secure wipe and proof — [docs/06, część 4](docs/06-forensics-karty-sd.md#część-4-bezpieczne-kasowanie-i-dowód)
- [ ] Test autentyczności karty bez marki (`f3write`/`f3read`) / Fake-capacity test on the no-name card — [docs/06, część 5](docs/06-forensics-karty-sd.md#część-5-test-autentyczności-karty-bez-marki-f3)
