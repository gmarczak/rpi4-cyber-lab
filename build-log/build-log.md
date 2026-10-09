# Dziennik budowy / Build log

Datowane notatki: co zrobione, co poszło nie tak, czego się nauczyłem.
Dated notes: what was done, what broke, what I learned.

Najnowsze na górze / Newest first.

---

## 2026-10-09 — Honeypot OpenCanary / OpenCanary honeypot

🇵🇱 Etap 2 ruszył. OpenCanary 0.9.10 zainstalowany w `/opt/opencanary` (venv), udaje SSH (22), stronę logowania „DiskStation” (80) i FTP (21), działa jako osobny użytkownik `opencanary`, logi idą na pendrive. Test z PC: otwarcie strony, logowanie `admin`/`admin132` i `ssh test@…` z hasłem `haslo123` — wszystko zapisane w logu z adresem, programem, loginem i hasłem. Na koniec usługa systemd; po restarcie honeypot wstaje sam.

🇬🇧 Stage 2 started. OpenCanary 0.9.10 in a venv under `/opt/opencanary`, faking SSH (22), a "DiskStation" login page (80) and FTP (21), running as a dedicated `opencanary` user, logging to the USB stick. Tests from the PC (web login and SSH login) were logged with source, client, username and password. Runs as a systemd service and comes back after reboot.

**Wpadki / Gotchas:** `opencanaryd --copyconfig` pod `sudo` użył systemowego Pythona i wypisał „ready”, choć nic nie skopiował — naprawione przez `sudo env PATH=/opt/opencanary/bin:$PATH`. Cztery komendy `ufw` wklejone naraz — wykonała się tylko pierwsza. `ssh honeypi.local` na porcie 22 zablokowany przez `REMOTE HOST IDENTIFICATION HAS CHANGED` — tak ma być, to ochrona przed podszyciem.

**Lekcja / Lesson:** komunikat „gotowe” to nie dowód — sprawdzaj wynik. / A "done" message is not proof — check the result.

Opis / Walkthrough: [docs/03, część 1](../docs/03-defender-raspberry.md)

---

## 2026-10-09 — Montaż i pierwsze logowanie / Assembly and first login

🇵🇱 Nagrałem Raspberry Pi OS Lite (64-bit) w Raspberry Pi Imager: nazwa hosta `honeypi`, strefa Europe/Warsaw, własny użytkownik, SSH z logowaniem hasłem. Wi-Fi i Raspberry Pi Connect zostawiłem wyłączone, bo obrońca ma chodzić po kablu i mieć jak najmniej furtek z zewnątrz. Potem radiatory: procesor, RAM, kontroler USB (VIA) i kontroler Ethernet. Czwarty radiator miał iść na układ zasilania przy USB-C, ale stał na otaczających go cewkach, a nie na chipie, więc przeniosłem go na Ethernet. Płytka w dwuczęściowej obudowie, gumowe nóżki, karta, pendrive, LAN, zasilanie. Pierwsze `ssh` z Windowsa po `honeypi.local` zadziałało od razu.

🇬🇧 Flashed Raspberry Pi OS Lite (64-bit) with Raspberry Pi Imager: hostname `honeypi`, Europe/Warsaw, custom user, SSH with password auth. Left Wi-Fi and Raspberry Pi Connect off, since the defender runs wired and should expose as few ways in as possible. Heatsinks on the CPU, RAM, USB controller (VIA) and Ethernet controller. The fourth one was meant for the power IC next to USB-C, but it rested on the surrounding inductors instead of the chip, so it went on the Ethernet chip instead. Board into a two-part case, rubber feet, SD card, USB stick, LAN, power. First `ssh` from Windows via `honeypi.local` worked straight away.

**Lekcja / Lesson:** radiator, który nie leży płasko na chipie, nic nie chłodzi. Lepiej go przenieść albo pominąć niż wciskać na siłę. / A heatsink that doesn't sit flat on the chip doesn't cool anything. Move it or skip it rather than forcing it.

**Zrzuty / Screenshots:** [`../screenshots/2026-10-09-assembly/`](../screenshots/2026-10-09-assembly/)

| | |
|---|---|
| ![Imager: wybór systemu / OS choice](../screenshots/2026-10-09-assembly/01-imager-os.png) | ![Imager: podsumowanie / summary](../screenshots/2026-10-09-assembly/07-imager-summary.png) |
| ![Płytka po rozpakowaniu / Board unboxed](../screenshots/2026-10-09-assembly/10-board-unboxed.jpg) | ![Mapa radiatorów / Heatsink map](../screenshots/2026-10-09-assembly/11-heatsink-map.jpg) |
| ![Radiatory przyklejone / Heatsinks mounted](../screenshots/2026-10-09-assembly/13-heatsinks-mounted.jpg) | ![Części obudowy / Case parts](../screenshots/2026-10-09-assembly/14-case-parts.jpg) |

![Pierwsze logowanie SSH / First SSH login](../screenshots/2026-10-09-assembly/20-first-ssh-login.png)

**Po aktualizacji / After the update:** pełna aktualizacja systemu, restart i ponowne logowanie. `lsblk` pokazuje kartę SD (`mmcblk0`, 59,5 GB: `/boot/firmware` i `/`) oraz pendrive (`sda`, 57,3 GB, jedna partycja `sda1`, na razie niezamontowana). Następny krok to sformatowanie pendrive'a pod logi. / Full system upgrade, reboot and login again. `lsblk` shows the SD card (`mmcblk0`, 59.5 GB: `/boot/firmware` and `/`) and the USB stick (`sda`, 57.3 GB, one partition `sda1`, not mounted yet). Next: format the stick for logs.

![Restart i lsblk / Reboot and lsblk](../screenshots/2026-10-09-assembly/21-reboot-lsblk.png)

Temperatura procesora w zamkniętej obudowie, bez obciążenia: **51,1°C**, w normie. / CPU temperature in the closed case at idle: **51.1°C**, within normal range.

![Temperatura / CPU temperature](../screenshots/2026-10-09-assembly/22-cpu-temp.png)

**Pendrive na logi / USB log drive:** sformatowany na ext4 (etykieta `logs`) i montowany przy starcie w `/mnt/logs`, 54 GB wolnego. Przy wklejaniu komenda z `tee` rozdzieliła się na dwie linijki (`Permission denied`); po poprawce wpis w `/etc/fstab` jest jeden. Opis komenda po komendzie: [docs/02b](../docs/02b-usb-log-drive.md). / Formatted as ext4 (label `logs`) and auto-mounted at `/mnt/logs`, 54 GB free. The `tee` command split into two lines when pasted (`Permission denied`); after the fix there is a single `/etc/fstab` entry. Command-by-command walkthrough: docs/02b.

**Logi na pendrive / Logs on the USB stick:** cały `/var/log` przeniesiony na pendrive przez *bind mount* (`/mnt/logs/var-log` → `/var/log`). Po restarcie `findmnt /var/log` pokazuje `/dev/sda1[/var-log]`, więc system i wszystkie przyszłe narzędzia piszą logi na pendrive, a nie na kartę. / The whole `/var/log` moved to the stick with a bind mount. After reboot `findmnt /var/log` shows `/dev/sda1[/var-log]`, so the OS and every future tool log to the stick, not the SD card. Opis / Walkthrough: [docs/02b, część 2](../docs/02b-usb-log-drive.md#część-2-logi-z-varlog-na-pendrive)

**Klucz SSH / SSH key:** na PC był już klucz `id_ed25519`, więc go nie nadpisałem i wysłałem na Raspberry ten istniejący. Logowanie działa bez hasła. Klucz nie ma passphrase, do rozważenia. / An `id_ed25519` key already existed on the PC, so I kept it and copied it to the Pi. Login works without a password. The key has no passphrase, worth revisiting. Opis / Walkthrough: [docs/02c](../docs/02c-ssh-hardening.md)

**Bez haseł / No passwords:** nowy plik `/etc/ssh/sshd_config.d/01-hardening.conf` wyłącza logowanie hasłem i jako root. Imager zostawił `50-cloud-init.conf`, ale nasz `01-` jest czytany pierwszy, więc wygrywa. Test: z kluczem loguje, bez klucza `Permission denied (publickey)`. / New drop-in disables password and root login; it sorts before Imager's `50-cloud-init.conf`, so it wins. Key login works, no key gives `Permission denied (publickey)`. Opis / Walkthrough: [docs/02c, część 2](../docs/02c-ssh-hardening.md#część-2-wyłączenie-logowania-hasłem)

**Port 2222 i skrót / Port 2222 and shortcut:** SSH przeniesione na port 2222 (`02-port.conf`), port 22 wolny dla honeypota. Na PC plik `.ssh\config` ze skrótem `ssh honeypi`. Pułapka: Notatnik zapisał go jako `config.txt`, więc SSH go nie widział; poprawione przez `ren`. / SSH moved to port 2222, port 22 left for the honeypot. On the PC a `.ssh\config` with an `ssh honeypi` shortcut. Gotcha: Notepad saved it as `config.txt`, fixed with `ren`. Opis / Walkthrough: [docs/02c, części 3–4](../docs/02c-ssh-hardening.md#część-3-prawdziwy-ssh-na-porcie-2222)

**Firewall:** `ufw` z domyślną blokadą ruchu przychodzącego i jednym wyjątkiem: 2222/tcp (SSH), dla IPv4 i IPv6. Bez ograniczenia do `192.168.1.0/24`, bo Windows łączy się przez IPv6 (`fe80::`). Komendy wklejone w trakcie `apt install` wyświetliły się pomieszane, ale wykonały się poprawnie. / `ufw` denies all incoming traffic except 2222/tcp for IPv4 and IPv6. Not limited to the home subnet because Windows connects over IPv6 link-local. Commands pasted during `apt install` displayed garbled but ran fine. Opis / Walkthrough: [docs/02c, część 5](../docs/02c-ssh-hardening.md#część-5-firewall-ufw)

**Tylko kabel / Wired only:** Wi-Fi i Bluetooth wyłączone sprzętowo w `/boot/firmware/config.txt` (`dtoverlay=disable-wifi`, `disable-bt`). Po restarcie `ip -br link` pokazuje tylko `lo` i `eth0`. / Wi-Fi and Bluetooth disabled at boot via device tree overlays; after reboot only `lo` and `eth0` remain. Opis / Walkthrough: [docs/02d](../docs/02d-network-basics.md)

**Stały adres IP / Static IP:** rezerwacja DHCP w FunBoxie (Ustawienia zaawansowane → Sieć → DHCP → Statyczne adresy IP): `honeypi` ma na stałe `192.168.1.134`. **Etap 1 zamknięty.** / DHCP reservation in the FunBox pins `honeypi` to `192.168.1.134`. **Stage 1 done.** 📋 Podsumowanie etapu / Stage summary: [docs/etap-1-podsumowanie.md](../docs/etap-1-podsumowanie.md). Opis / Walkthrough: [docs/02d, część 2](../docs/02d-network-basics.md#część-2-stały-adres-ip-rezerwacja-dhcp-w-funboxie)

---

## 2026-10-08 — Części zamówione / Parts ordered

🇵🇱 Zamówiłem cały zestaw w Botlandzie (darmowa wysyłka, InPost). Dostawa w czwartek. Wersja 4 GB zamiast 1 GB — z myślą o monitoringu i ewentualnym Home Assistant w przyszłości. Firmową kartę 32 GB za 148 zł odpuściłem na rzecz SanDisk Extreme 64 GB (szybsza, większa, podobna cena). Pendrive na logi, żeby nie zajeżdżać karty.

🇬🇧 Ordered the full kit from Botland (free shipping, InPost). Arrives Thursday. Went with 4 GB over 1 GB for monitoring headroom and a possible future Home Assistant. Skipped the 148 PLN branded 32 GB card for a SanDisk Extreme 64 GB instead. Separate USB drive for logs to spare the SD card.

**Lekcja / Lesson:** firmowe karty z wgranym systemem są mocno przepłacone — system nagrywasz sam za darmo. / Pre-loaded branded cards are heavily overpriced — you flash the OS yourself for free.

---

## Szablon wpisu / Entry template

```
## RRRR-MM-DD — Tytuł / Title

🇵🇱 Co zrobiłem, na co się natknąłem.
🇬🇧 What I did, what I ran into.

Lekcja / Lesson: ...
Zrzuty / Screenshots: ../screenshots/...
```

<!-- Kolejne wpisy dopisuj POWYŻEJ tej sekcji / Add new entries ABOVE this template, below the title -->
