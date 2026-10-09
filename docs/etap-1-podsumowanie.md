# Etap 1 — Fundamenty: podsumowanie

**Data:** 2026-10-09 · **Czas:** jedno popołudnie · **Szczegóły krok po kroku:** [02b](02b-usb-log-drive.md), [02c](02c-ssh-hardening.md), [02d](02d-network-basics.md)

Ten plik zbiera cały Etap 1 w jednym miejscu: co zrobiłem, po co, jakimi komendami, na jakie problemy trafiłem i jak sprawdzić, że wszystko działa. Pełne wyjaśnienia każdej komendy i zrzuty ekranu są w rozdziałach podlinkowanych przy każdym kroku.

---

## Cel etapu

Zanim Raspberry zacznie udawać podatne urządzenie (honeypot w Etapie 2), samo musi być solidnie zabezpieczone i przewidywalne:

- **jedno, dobrze pilnowane wejście**: SSH tylko kluczem, na niestandardowym porcie, za firewallem,
- **logi poza kartą SD**: monitoring będzie dużo zapisywał, a karta z systemem ma przetrwać,
- **przewidywalna sieć**: tylko kabel i zawsze ten sam adres.

## Przed i po

| | Przed (świeży system) | Po Etapie 1 |
|---|---|---|
| System | zainstalowany z Imagera | zaktualizowany |
| Logowanie SSH | hasłem, port 22 | **tylko kluczem**, port **2222**, bez roota |
| Logowanie z PC | `ssh grzesiek@honeypi.local` + hasło | `ssh honeypi`, bez hasła |
| Firewall | brak, wszystkie porty dostępne | `ufw`: wszystko przychodzące zamknięte poza 2222 |
| Logi (`/var/log`) | na karcie SD | na pendrivie (`/mnt/logs/var-log`) |
| Port 22 | prawdziwe SSH | **wolny**, czeka na honeypota |
| Wi-Fi, Bluetooth | włączone | wyłączone sprzętowo |
| Adres IP | z puli DHCP, mógł się zmienić | `192.168.1.134`, zarezerwowany w routerze |

## Jak to teraz wygląda

```
   PC (Windows)                  Router FunBox                 Raspberry Pi 4 "honeypi"
 ┌──────────────┐             ┌────────────────┐            ┌──────────────────────────────┐
 │ ssh honeypi  │── kabel ───►│ 192.168.1.1    │── kabel ──►│ eth0  192.168.1.134 (stały)  │
 │ klucz        │             │ DHCP: .134     │   Eth. 2   │                              │
 │ id_ed25519   │             │ zarezerwowany  │            │ ufw: wpuszcza tylko 2222/tcp │
 └──────────────┘             └────────────────┘            │  ├─ 2222 → SSH (tylko klucz) │
                                                            │  └─ 22   → wolny (honeypot)  │
                                                            │                              │
                                                            │ karta SD  → system           │
                                                            │ pendrive  → /var/log (logi)  │
                                                            │ Wi-Fi, BT → wyłączone        │
                                                            └──────────────────────────────┘
```

---

## Kroki

### 1. Aktualizacja systemu

**Po co:** system z Imagera ma pakiety sprzed kilku tygodni. Aktualizacje łatają znane luki, więc robi się je przed wszystkim innym.

```bash
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

- `apt update` pobiera listę dostępnych wersji, `full-upgrade` instaluje nowsze (także gdy wymagają dodania lub usunięcia zależności), `-y` = bez pytania.
- Restart wczytuje nowe jądro systemu.

### 2. Pendrive na logi → [02b, część 1](02b-usb-log-drive.md)

**Po co:** karta microSD zużywa się od ciągłego zapisu, a na niej jest cały system. Logi idą na tani, wymienny pendrive.

```bash
lsblk                                         # znajdź pendrive (u mnie sda, 57 GB)
sudo wipefs -a /dev/sda                       # wyczyść stare oznaczenia
sudo parted /dev/sda --script mklabel gpt mkpart logs ext4 0% 100%   # jedna partycja
sudo mkfs.ext4 -L logs /dev/sda1              # format ext4, etykieta "logs"
sudo mkdir -p /mnt/logs                       # punkt montowania
echo 'LABEL=logs /mnt/logs ext4 defaults,noatime,nofail 0 2' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a
df -h /mnt/logs                               # 57G, zamontowany
```

Najważniejsze: **etykieta** `logs` zamiast `/dev/sda1` (nazwa urządzenia może się zmienić), **`noatime`** (mniej zapisów), **`nofail`** (bez pendrive'a system i tak wystartuje).

### 3. `/var/log` na pendrive → [02b, część 2](02b-usb-log-drive.md#część-2-logi-z-varlog-na-pendrive)

**Po co:** zamiast przestawiać każdy program osobno, podmieniamy cały folder logów. Wszystko, co pisze do `/var/log` (system, a w Etapie 2 Suricata i ntopng), automatycznie trafia na pendrive.

```bash
sudo mkdir -p /mnt/logs/var-log
sudo cp -a /var/log/. /mnt/logs/var-log/      # przenieś obecne logi z uprawnieniami
echo '/mnt/logs/var-log /var/log none bind,nofail,x-systemd.requires-mounts-for=/mnt/logs 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo reboot
findmnt /var/log                              # /dev/sda1[/var-log]
```

*Bind mount* pokazuje jeden folder w miejscu drugiego. `x-systemd.requires-mounts-for` pilnuje kolejności: najpierw pendrive, potem podmiana.

### 4. Logowanie kluczem SSH → [02c, część 1](02c-ssh-hardening.md)

**Po co:** klucz to para plików: prywatny zostaje na PC, publiczny trafia na Raspberry. Hasło nie leci przez sieć, a klucza nie da się zgadnąć.

Na PC (wiersz poleceń Windows):

```bat
ssh-keygen -t ed25519
type %USERPROFILE%\.ssh\id_ed25519.pub | ssh grzesiek@honeypi.local "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
ssh grzesiek@honeypi.local                    # loguje bez hasła
```

### 5. Wyłączenie haseł i roota → [02c, część 2](02c-ssh-hardening.md#część-2-wyłączenie-logowania-hasłem)

**Po co:** skoro klucz działa, hasło jest tylko celem dla botów zgadujących hasła (*brute force*).

```bash
ls /etc/ssh/sshd_config.d/                    # był tam 50-cloud-init.conf od Imagera
printf 'PasswordAuthentication no\nKbdInteractiveAuthentication no\nPermitRootLogin no\n' | sudo tee /etc/ssh/sshd_config.d/01-hardening.conf
sudo sshd -t && sudo systemctl reload ssh
```

Test na PC: `ssh -o PubkeyAuthentication=no grzesiek@honeypi.local` → `Permission denied (publickey)`.

### 6. SSH na porcie 2222 i skrót `ssh honeypi` → [02c, części 3–4](02c-ssh-hardening.md#część-3-prawdziwy-ssh-na-porcie-2222)

**Po co:** port 22 zwalniamy dla honeypota. Skanery zaglądają właśnie tam, więc tam stanie pułapka. Prawdziwe SSH działa na 2222.

```bash
systemctl is-active ssh.socket ssh.service    # inactive / active → klasyczna usługa
echo 'Port 2222' | sudo tee /etc/ssh/sshd_config.d/02-port.conf
sudo sshd -t && sudo systemctl reload ssh
sudo ss -tlnp | grep sshd                     # tylko :2222
```

Na PC plik `C:\Users\Grzesiek\.ssh\config`:

```
Host honeypi
    HostName honeypi.local
    User grzesiek
    Port 2222
```

Od teraz: `ssh honeypi`.

### 7. Firewall `ufw` → [02c, część 5](02c-ssh-hardening.md#część-5-firewall-ufw)

**Po co:** zasada „wszystko zamknięte, otwieramy tylko to, co potrzebne”.

```bash
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp comment 'SSH'
sudo ufw enable
sudo ufw status verbose
```

### 8. Tylko kabel → [02d, część 1](02d-network-basics.md)

**Po co:** każde włączone radio to dodatkowa droga do urządzenia i dodatkowy interfejs do pilnowania.

```bash
printf '\n# lab: tylko kabel\ndtoverlay=disable-wifi\ndtoverlay=disable-bt\n' | sudo tee -a /boot/firmware/config.txt
sudo reboot
ip -br link                                   # tylko lo i eth0
```

### 9. Stały adres IP → [02d, część 2](02d-network-basics.md#część-2-stały-adres-ip-rezerwacja-dhcp-w-funboxie)

**Po co:** reguły, skany i konfiguracja honeypota odwołują się do adresu Raspberry, więc nie może się zmieniać.

W panelu FunBoxa (`http://192.168.1.1`): **Ustawienia zaawansowane → Sieć → DHCP → Statyczne adresy IP** → wybierz `honeypi` → **Dodaj**. Router rozpoznaje Raspberry po adresie MAC i zawsze daje mu `192.168.1.134`.

---

## Problemy po drodze i czego mnie nauczyły

| # | Problem | Co było widać | Przyczyna | Rozwiązanie | Lekcja |
|---|---|---|---|---|---|
| 1 | Komenda rozdzielona przy wklejaniu | `-bash: /etc/fstab: Permission denied` | długa linijka wkleiła się w dwóch kawałkach: `tee -a` bez nazwy pliku tylko wypisał tekst, a `/etc/fstab` powłoka próbowała uruchomić | wkleiłem komendę jeszcze raz w całości, potem `cat /etc/fstab`, żeby sprawdzić, że wpis jest jeden | długie komendy sprawdzaj przed Enterem; po zmianie ważnego pliku zawsze go przejrzyj |
| 2 | Klucz SSH już istniał | `id_ed25519 already exists. Overwrite (y/n)?` | na PC był wcześniejszy klucz | **nie** nadpisałem, użyłem istniejącego | nadpisanie klucza unieważnia go wszędzie, gdzie był używany (np. GitHub) |
| 3 | Kolejność plików konfiguracji SSH | w `sshd_config.d/` był już `50-cloud-init.conf` od Imagera | SSH bierze **pierwszą** znalezioną wartość, pliki czyta alfabetycznie | nasz plik nazwałem `01-hardening.conf`, czytany przed `50-` | nie edytuj plików zostawionych przez instalator, dodaj własny z niższym numerem |
| 4 | Notatnik dopisał `.txt` | `ssh honeypi` → `port 22: Connection refused` | Notatnik zapisał `config.txt`, a SSH szuka pliku `config` | `ren "%USERPROFILE%\.ssh\config.txt" config`, sprawdzone przez `dir` | na Windowsie pliki bez rozszerzenia sprawdzaj w `dir`, bo Eksplorator ukrywa rozszerzenia |
| 5 | Komendy wklejone w trakcie instalacji | pomieszany tekst `tgoing`, `'SSH'sudo ufw...` | wklejone, zanim `apt` skończył; terminal wyświetlił je od razu, wykonał później | nic nie trzeba było poprawiać, wykonały się po kolei | wklejaj następną komendę dopiero przy znaku zachęty `$`; przy pytaniach `(y/n)` wklejony tekst mógłby zostać wzięty za odpowiedź |
| 6 | Firewall a IPv6 | „Last login … from `fe80::…`” | Windows łączy się z `honeypi.local` przez IPv6 (adres lokalny łącza) | reguła SSH bez ograniczenia do `192.168.1.0/24` | reguła tylko dla IPv4 odcięłaby mi dostęp; przed internetem chroni router |
| 7 | Logi na pendrive wymagają restartu | — | działające programy trzymają otwarte pliki w starym `/var/log` | `reboot` zamiast `mount -a` | po podmianie folderu, w którym programy już piszą, trzeba je uruchomić od nowa |

**Zasada, która uratowała mi kilka razy dostęp:** przy każdej zmianie SSH i firewalla stare okno z sesją zostaje otwarte, a test robię w nowym. Jak coś nie działa, cofam zmianę w starym oknie.

---

## Wszystkie zmienione pliki

**Na Raspberry:**

| Plik | Co w nim jest |
|---|---|
| `/etc/fstab` | 2 nowe linijki: pendrive w `/mnt/logs` i bind mount `/var/log` |
| `/etc/ssh/sshd_config.d/01-hardening.conf` | bez haseł, bez „klawiaturowego” logowania, bez roota |
| `/etc/ssh/sshd_config.d/02-port.conf` | `Port 2222` |
| `/boot/firmware/config.txt` | na końcu: `dtoverlay=disable-wifi`, `dtoverlay=disable-bt` |
| `~/.ssh/authorized_keys` | klucz publiczny z PC |
| reguły `ufw` | deny incoming, allow outgoing, allow 2222/tcp |

**Na PC:** `C:\Users\Grzesiek\.ssh\config` (skrót `honeypi`).

**W routerze:** rezerwacja DHCP `honeypi` → `192.168.1.134`.

---

## Kontrola stanu: czy wszystko dalej działa

Jeden zestaw komend do sprawdzenia całego Etapu 1, np. po aktualizacji albo awarii prądu. Na Raspberry (`ssh honeypi`):

```bash
findmnt /mnt/logs /var/log
sudo sshd -T | grep -Ei '^(port|passwordauthentication|kbdinteractiveauthentication|permitrootlogin) '
sudo ufw status
ip -br link
ip -4 -br addr show eth0
```

Oczekiwany wynik:

| Komenda | Ma pokazać |
|---|---|
| `findmnt /mnt/logs /var/log` | `/mnt/logs` z `/dev/sda1` oraz `/var/log` z `/dev/sda1[/var-log]` |
| `sudo sshd -T \| grep ...` | `port 2222`, `passwordauthentication no`, `kbdinteractiveauthentication no`, `permitrootlogin no` |
| `sudo ufw status` | `Status: active` i `2222/tcp ALLOW` (IPv4 i v6) |
| `ip -br link` | tylko `lo` i `eth0` (bez `wlan0`) |
| `ip -4 -br addr show eth0` | `192.168.1.134/24` |

`sshd -T` (*test, extended*) wypisuje **faktycznie obowiązującą** konfigurację SSH, już po połączeniu wszystkich plików. To najpewniejszy sposób, żeby sprawdzić, która wartość wygrała.

---

## Słowniczek

| Pojęcie | Znaczenie |
|---|---|
| **bind mount** | pokazanie jednego folderu w miejscu drugiego; programy nie widzą różnicy |
| **DHCP** | usługa routera, która rozdaje urządzeniom adresy IP |
| **rezerwacja DHCP** | router zawsze daje temu samemu urządzeniu (rozpoznanemu po MAC) ten sam adres |
| **MAC** | sprzętowy identyfikator karty sieciowej; nie publikuję go na zrzutach |
| **ext4** | standardowy system plików Linuksa, odporny na nagłe wyłączenie prądu |
| **`/etc/fstab`** | lista dysków montowanych przy starcie |
| **drop-in** (`*.conf` w `sshd_config.d/`) | osobny plik z ustawieniami, dołączany do głównej konfiguracji; łatwo dodać i usunąć |
| **`ufw`** | prosta nakładka na firewall wbudowany w Linuksa |
| **`dtoverlay`** | zmiana opisu sprzętu przekazywanego systemowi przy starcie; tak wyłączyłem radia |
| **IPv6 link-local** (`fe80::…`) | adres IPv6 działający tylko w sieci lokalnej; tak Windows łączy się z `honeypi.local` |
| **powierzchnia ataku** | wszystko, przez co da się dostać do urządzenia; w tym etapie ją zmniejszaliśmy |

---

## Co dalej

**Etap 2: obrońca.** Honeypot OpenCanary na zwolnionym porcie 22 (i 21, 80), monitoring ruchu Suricatą, otwarcie tych portów w `ufw` i pierwszy alert. Plan w [ROADMAP](../ROADMAP.md), instrukcja w [03 — Obrońca](03-defender-raspberry.md).
