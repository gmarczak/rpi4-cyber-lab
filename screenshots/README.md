# Zrzuty ekranu i zdjęcia / Screenshots & photos

Wrzucaj tu zrzuty i zdjęcia z budowy, np.:
Drop build screenshots and photos here, e.g.:

- `01-imager.png` — Raspberry Pi Imager
- `02-assembly.jpg` — złożone Raspberry / assembled Pi
- `03-pihole-first-boot.png`
- `04-opencanary-alert.png` — pierwszy alert honeypota / first honeypot alert
- `05-suricata-detect.png` — wykryty skan / detected scan

## Galerie / Galleries

- [`2026-10-09-assembly/`](2026-10-09-assembly/): nagrywanie systemu w Imagerze, radiatory, obudowa, pierwsze logowanie SSH / OS flashing in Imager, heatsinks, case, first SSH login
  - `01`–`07`: kroki Raspberry Pi Imager / Raspberry Pi Imager steps
  - `10`–`14`: zdjęcia z montażu / assembly photos
  - `20`: pierwsze logowanie SSH (adres IPv6 i odcisk klucza zamazane) / first SSH login (IPv6 address and key fingerprint blurred)
  - `21`: restart po aktualizacji i `lsblk` (adres IPv6 zamazany) / reboot after the update and `lsblk` (IPv6 address blurred)
  - `22`: temperatura procesora / CPU temperature
  - `23`–`24`: formatowanie i montowanie pendrive'a, komendy ponumerowane jak w [docs/02b](../docs/02b-usb-log-drive.md) / USB stick formatting and mounting, numbered as in docs/02b
  - `25`: sprawdzenie `/etc/fstab` / `/etc/fstab` check
  - `26`–`27`: przeniesienie `/var/log` na pendrive i sprawdzenie po restarcie (adres IPv6 zamazany) / moving `/var/log` to the USB stick and checking after reboot (IPv6 blurred)
  - `28`: klucz SSH z Windowsa (adres IP z sieci domowej zamazany) / SSH key from Windows (home LAN IP blurred)
  - `29`–`31`: wyłączenie logowania hasłem i testy z kluczem i bez (adres IPv6 zamazany) / password login disabled, tests with and without the key (IPv6 blurred)
  - `32`–`35`: SSH na porcie 2222, test portów, pułapka Notatnika z `config.txt` i poprawka (adres IPv6 zamazany) / SSH on port 2222, port tests, the Notepad `config.txt` trap and the fix (IPv6 blurred)
  - `36`–`38`: firewall `ufw`: instalacja, reguły i test SSH (adres IPv6 zamazany) / `ufw` firewall: install, rules and SSH test (IPv6 blurred)
  - `39`: wyłączenie Wi-Fi i Bluetooth (adres MAC i IPv6 zamazane) / Wi-Fi and Bluetooth disabled (MAC and IPv6 blurred)
  - `40`–`46`: stały adres IP w FunBoxie (nazwy innych urządzeń, ich adresy i wszystkie adresy MAC zamazane) / static IP in the FunBox (other devices' names and addresses, and all MACs hidden)
  - `47`–`61`: honeypot OpenCanary: instalacja, konfiguracja, firewall, pierwsze alerty, usługa systemd (adres PC i IPv6 zamazane) / OpenCanary honeypot: install, config, firewall, first alerts, systemd service (PC address and IPv6 blurred)
  - `62`–`64`: Suricata: instalacja, konfiguracja, reguły i test / Suricata: install, config, rules and test
  - `65`–`67`: Suricata: `EXTERNAL_NET`, uruchomienie, diagnoza i pierwsze alerty (adres PC zamazany) / Suricata: `EXTERNAL_NET`, start, diagnosis and first alerts (PC address blurred)

  - `68`–`69`: codzienna aktualizacja reguł Suricaty i pierwsza wersja `check-logs.sh` (adres PC zamazany) / daily Suricata rule updates and the first `check-logs.sh` (PC address blurred)
- [`2026-10-09-forensics/`](2026-10-09-forensics/): zdjęcia i zrzuty z ćwiczenia [docs/06](../docs/06-forensics-karty-sd.md) / photos and screenshots from the forensics exercise
  - `01`: karta SanDisk microSD 16 GB (klasa 10) i adapter SD z zaznaczonym suwakiem LOCK; zdjęcie przycięte do kart, bez metadanych EXIF / SanDisk 16 GB microSD (class 10) and its SD adapter with the LOCK slider marked; cropped, EXIF removed
  - `02`–`03`: instalacja Homebrew i narzędzi (`testdisk`, `f3`), kroki P1–P3 / Homebrew and tool install, steps P1–P3
  - `04`–`10`: karta SanDisk: `diskutil`, `dd` z `Operation timed out`, trzy różne sumy, mapa różnic, test rozmiaru bloku i `stab` / SanDisk card: `diskutil`, `dd` timeout, three different hashes, diff map, block-size test and `stab`
  - `11`–`12`: karta bez marki: `diskutil`, `stab`, obraz i trzy zgodne sumy SHA-256, `chmod 444` / no-name card: `diskutil`, `stab`, image and three matching SHA-256 hashes, `chmod 444`
  - `13`–`17`: TestDisk na obrazie; **nazwy usuniętych plików zamazane** (cudze dane) / TestDisk on the image; **deleted file names blurred** (someone else's data)
  - `18`–`22`: PhotoRec: menu, wpadki (`0 files saved`, log i pliki sesji w repo), 314 odzyskanych plików i liczenie typów / PhotoRec: menus, gotchas (`0 files saved`, log and session files in the repo), 314 recovered files and type counts
  - `23`–`32`: kontrolowany eksperyment: formatowanie, pliki testowe (z wpadkami `cp`/`head`), usunięcie, obraz, TestDisk (4 z 4 identyczne), PhotoRec (111 plików, 3 z 4 identyczne) / controlled experiment: format, test files (with `cp`/`head` gotchas), delete, image, TestDisk (4 of 4 identical), PhotoRec (111 files, 3 of 4 identical)
- [`2026-10-09-pc-self-scan/`](2026-10-09-pc-self-scan/): misja [docs/07](../docs/07-skan-wlasnego-pc.md), Raspberry skanuje mój PC / side mission, the Pi scans my PC
  - `01`: ping do całej sieci (adresy innych urządzeń i PC zamazane) / ping sweep (other devices' and the PC's addresses blurred)
  - `02`: profil sieci i nasłuchujące porty (nazwa sieci Wi-Fi/SSID zamazana) / network profile and listening ports (network name blurred)
  - `03`: `nmap` z Raspberry przed zmianami, 4 otwarte porty (adres i nazwa PC zamazane) / `nmap` before, 4 open ports (PC address and name blurred)
  - `04`: reguły firewalla otwierające porty / firewall rules opening the ports
  - `05`: `nmap` po zmianach, wszystko `filtered` (adres i nazwa PC zamazane) / `nmap` after, everything filtered (PC address and name blurred)

- [`2026-10-10-kali-cele/`](2026-10-10-kali-cele/): instalacja Kali i maszyny z celami, ramki numerowane jak w [docs/04c](../docs/04c-instalacja-kali-i-celow.md) / Kali and target VM install, numbered as in docs/04c
  - `01`–`07`: pobranie Kali, 7-Zip, suma SHA-256 (`05`: wpadka ze złym folderem) / Kali download, 7-Zip, SHA-256 (`05`: wrong-folder gotcha)
  - `08`–`15`: VirtualBox, rozpakowanie, import, RAM, dwie karty sieciowe (adresy MAC zamazane) / VirtualBox, extract, import, RAM, two adapters (MACs blurred)
  - `16`–`22`: pierwszy start Kali, `passwd`, `ip a`, aktualizacja, ping do Raspberry, snapshot (adres Kali, MAC i IPv6 zamazane) / first boot, `passwd`, `ip a`, update, ping to the Pi, snapshot (Kali address, MACs and IPv6 blurred)
  - `23`–`28`: Ubuntu Server: suma (wpadka `shasum`), nowa maszyna `cele`, karta NAT (MAC zamazany) / Ubuntu Server: checksum (`shasum` gotcha), new `cele` VM, NAT adapter (MAC blurred)
  - `29`–`42`: instalator Ubuntu Server, ostrzeżenie „soft lockup”, koniec instalacji (MAC i IPv6 zamazane) / Ubuntu Server installer, soft lockup warning, install complete (MAC and IPv6 blurred)
  - `43`–`44`: pierwszy start `cele`: klucze SSH, `hostnamectl`, `ip a` (odciski kluczy, Machine ID, MAC i IPv6 zamazane) / first boot: SSH host keys, `hostnamectl`, `ip a` (key fingerprints, machine ID, MAC and IPv6 blurred)

## ⚠️ Zanim wrzucisz / Before committing

Zrzuty terminala przycinamy do samego okna, bez tła pulpitu. / Terminal screenshots are cropped to the window, without the desktop background.


To repo jest **publiczne**. Przed wrzuceniem obrazka zamaż / usuń:
This repo is **public**. Before committing an image, blur or crop out:

- hasła i tokeny / passwords and tokens
- prawdziwe adresy IP i MAC z Twojej sieci / real IPs and MACs from your network
- nazwy Wi-Fi (SSID) i cokolwiek, co identyfikuje Twoją sieć / Wi-Fi names and anything identifying your network
