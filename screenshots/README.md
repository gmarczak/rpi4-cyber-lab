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

## ⚠️ Zanim wrzucisz / Before committing

Zrzuty terminala przycinamy do samego okna, bez tła pulpitu. / Terminal screenshots are cropped to the window, without the desktop background.


To repo jest **publiczne**. Przed wrzuceniem obrazka zamaż / usuń:
This repo is **public**. Before committing an image, blur or crop out:

- hasła i tokeny / passwords and tokens
- prawdziwe adresy IP i MAC z Twojej sieci / real IPs and MACs from your network
- nazwy Wi-Fi (SSID) i cokolwiek, co identyfikuje Twoją sieć / Wi-Fi names and anything identifying your network
