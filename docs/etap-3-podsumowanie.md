# Etap 3 — Atakujący: podsumowanie

**Data:** 2026-10-10 · **Czas:** jeden długi dzień · **Szczegóły krok po kroku:** [04b](04b-sieci-virtualbox.md) · [04c](04c-instalacja-kali-i-celow.md) · [04d](04d-docker-dvwa-juice-shop.md) · [04e](04e-zabezpieczenie-kali-i-stabilnosc.md)

Ten plik zbiera cały Etap 3 w jednym miejscu: co zrobiłem, po co, jakimi komendami, na jakie problemy trafiłem i jak sprawdzić, że wszystko działa. Pełne wyjaśnienia każdej komendy i zrzuty ekranu są w rozdziałach 04b–04e.

---

## Cel etapu

Obrońca z Etapu 2 czeka na Raspberry. Teraz potrzebny jest ktoś, kto go zaatakuje, i coś, na czym da się ćwiczyć ataki na strony WWW:

- **atakujący:** Kali Linux w maszynie wirtualnej na PC, z dwiema kartami sieciowymi: jedną do sieci domowej (żeby widział Raspberry), drugą do zamkniętej sieci labu,
- **cele ataku:** celowo dziurawe aplikacje DVWA i OWASP Juice Shop, na osobnej maszynie `cele`, **odcięte od internetu i od sieci domowej**,
- **bezpieczeństwo samego labu:** Kali jest widoczny w domu, więc musi być zabezpieczony jak każde inne urządzenie,
- **punkty powrotu:** snapshoty obu maszyn, żeby każde ćwiczenie można było cofnąć jednym kliknięciem,
- **stabilność:** lab ma działać na moim PC (4 rdzenie, 16 GB RAM) bez zawieszania.

## Przed i po

| | Przed (po Etapie 2) | Po Etapie 3 |
|---|---|---|
| Atakujący | brak (testy z PC Windows) | **Kali Linux 2026.2** w VirtualBoxie 7.2.14, 4 GB RAM, 2 procesory |
| Sieć Kali | — | `eth1` mostkowana (sieć domowa, internet), `eth0` w `labnet`: **10.10.10.5** |
| Cele ataku | brak | maszyna **`cele`**: Ubuntu Server 26.04.1, Docker 29.9, **DVWA** (:4280) i **Juice Shop** (:3000), 1 procesor, 2 GB RAM |
| Sieć `cele` | — | tylko `labnet`: **10.10.10.10**, bez bramy, **bez internetu** |
| Kto widzi DVWA i Juice Shop | — | tylko Kali, przez `labnet` |
| SSH na Kali | — | wyłączone |
| Firewall na Kali | — | `ufw`: blokuje cały ruch przychodzący; skan z Raspberry: 1000 portów `filtered` |
| Czas Kali | — | `Europe/Warsaw` (CEST), jak na Raspberry |
| Snapshoty | — | „Kali zabezpieczony (ufw, SSH off, CEST)”, „cele czyste (1 CPU, bez czekania na sieć)” + wcześniejsze |
| Start `cele` | — | 18 s |
| Rezerwacje DHCP w routerze | Raspberry, PC | + Kali (karta mostkowana) |

## Jak to teraz wygląda

```
                         [ Router Orange ]  internet, DHCP
                                |
        +-----------------------+---------------------------------+
        |                                                         |  kabel
 [ Raspberry "honeypi" ]       +--------------------------- PC (Windows 10, 4 rdzenie) ---------+
 192.168.1.134                 |                                                                 |
 honeypot + Suricata           |   VirtualBox 7.2.14 (pod hypervisorem Windowsa: "żółw")         |
        ^                      |                                                                 |
        |  skan z Kali         |   +------------- Kali 2026.2 --------------+                    |
        +----------------------|---| eth1 (mostkowana) ufw: deny incoming   |                    |
           przez sieć domową   |   | SSH off, ip_forward = 0, czas CEST     |                    |
                               |   | eth0 = 10.10.10.5                      |                    |
                               |   +-------------------|--------------------+                    |
                               |                       |                                         |
                               |   [======== labnet: sieć wewnętrzna, bez routera i internetu ==] |
                               |                       |                                         |
                               |   +-------------------|--------------------+                    |
                               |   | cele = 10.10.10.10 (Ubuntu Server)     |                    |
                               |   | Docker: DVWA :4280 (+ MariaDB w środku)|                    |
                               |   |         Juice Shop :3000               |                    |
                               |   | SSH :22 (hasło, celowo słaby cel)      |                    |
                               |   +----------------------------------------+                    |
                               +-----------------------------------------------------------------+
```

Dwa osobne ćwiczenia, tak jak w [05](05-first-exercise.md): **atak na Raspberry** idzie przez sieć domową i widzi go obrońca; **atak na DVWA i Juice Shop** dzieje się w `labnet` i przez Raspberry nie przechodzi.

---

## Kroki

### 1. Teoria sieci w VirtualBoxie → [04b](04b-sieci-virtualbox.md)

**Po co:** zanim podłączyłem maszynę z narzędziami ataku do domowej sieci, musiałem wiedzieć, kto kogo widzi. Tryb **mostkowany** robi z maszyny pełnoprawne urządzenie w sieci domowej; tryb **wewnętrzny** to wirtualny kabel tylko między maszynami; **NAT** chowa maszynę za adresem PC. Rozdział opisuje też, jak ktoś z sieci domowej mógłby przejąć Kali z domyślnym hasłem `kali`/`kali` i jak temu zapobiec.

### 2. Kali Linux → [04c, część 1](04c-instalacja-kali-i-celow.md#część-1-kali)

**Po co:** gotowa maszyna dla VirtualBoxa z kali.org, bez instalatora. Suma SHA-256 potwierdza, że plik dotarł cały.

```powershell
cd $HOME\Downloads
Get-FileHash .\kali-linux-2026.2-virtualbox-amd64.7z -Algorithm SHA256
# rozpakowanie 7-Zipem do C:\VMs\, VirtualBox → Open → plik .vbox
# Ustawienia: RAM 4096 MB, 2 CPU; Karta 1: Sieć wewnętrzna "labnet"; Karta 2: Mostkowana (Killer E2500)
```

```bash
passwd                                    # od razu, zamiast kali/kali
ip a                                      # eth0 bez adresu (labnet), eth1 z adresem od routera
sudo apt update && sudo apt full-upgrade -y
sudo reboot
uname -r                                  # 7.1.5+kali-amd64
ping -c 4 192.168.1.134                   # Kali widzi Raspberry
sudo poweroff                             # potem snapshot "Kali 2026.2 czysty po aktualizacji"
```

Plus rezerwacja DHCP dla karty mostkowanej Kali w routerze.

### 3. Maszyna `cele` → [04c, część 2](04c-instalacja-kali-i-celow.md#część-2-maszyna-cele)

**Po co:** podatne aplikacje nie mogą stać na Kali, bo Kali ma kartę mostkowaną i byłyby widoczne w całym domu. Osobna maszyna dostanie tylko kartę w `labnet`.

```powershell
Get-FileHash .\ubuntu-26.04.1-live-server-amd64.iso -Algorithm SHA256
# VirtualBox → Nowa: "cele", dysk 25 GB, POMIŃ instalację nienadzorowaną, karta 1: NAT (tymczasowo)
# instalator: English, klawiatura Polish, cały dysk bez LVM, użytkownik grzesiek, OpenSSH: tak, snapy: nie
```

```bash
hostnamectl                               # cele, Ubuntu 26.04.1 LTS
ip a                                      # enp0s3: 10.0.2.15 (NAT)
```

### 4. Docker, DVWA i Juice Shop → [04d, części 1–4](04d-docker-dvwa-juice-shop.md)

**Po co:** każda aplikacja przychodzi jako gotowy obraz z własnym PHP, bazą czy Node.js, więc na `cele` nie instaluję niczego poza Dockerem. Wszystko trzeba pobrać, **zanim** `cele` straci internet.

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu resolute stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
# NAT → Przekierowanie portów: TCP 127.0.0.1:2201 → 22, potem z PowerShella:
#   ssh -p 2201 grzesiek@127.0.0.1
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker grzesiek          # potem exit i ponowne logowanie
docker run hello-world
cd ~ && git clone https://github.com/digininja/DVWA.git && cd DVWA
sed -i 's/pull_policy: always/pull_policy: missing/; s/127.0.0.1:4280:80/4280:80/' compose.yml
docker compose pull
docker compose up -d
docker pull bkimminich/juice-shop
docker run -d --name juice-shop --restart unless-stopped -p 3000:3000 bkimminich/juice-shop
docker ps
curl -sI http://localhost:4280 | head -1  # HTTP/1.1 302 Found
curl -sI http://localhost:3000 | head -1  # HTTP/1.1 200 OK
```

### 5. `cele` do `labnet`, bez internetu → [04d, część 5](04d-docker-dvwa-juice-shop.md#część-5-przełączenie-do-labnet)

**Po co:** stały adres w sieci, w której nie ma DHCP, i celowo **bez bramy**: `cele` nie zna żadnej drogi do internetu. Najpierw trzeba wyłączyć cloud-init, który przy starcie nadpisałby ustawienia sieci.

```bash
sudo tee /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg <<'EOF'
network: {config: disabled}
EOF
sudo mkdir -p /root/netplan-backup
sudo mv /etc/netplan/*.yaml /root/netplan-backup/
sudo tee /etc/netplan/01-labnet.yaml <<'EOF'
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      optional: true
      addresses: [10.10.10.10/24]
EOF
sudo chmod 600 /etc/netplan/01-labnet.yaml
sudo netplan generate
sudo poweroff
# snapshot "cele z Dockerem, przed labnet", potem Karta 1 → Sieć wewnętrzna "labnet"
ip -br a                                  # enp0s3 UP 10.10.10.10/24
ping -c 2 8.8.8.8                         # Network is unreachable
```

Linijka `optional: true` doszła później (krok 11 poniżej); tu jest od razu, żeby plik był w wersji końcowej.

### 6. Kali w `labnet` i pierwszy kontakt → [04d, część 6](04d-docker-dvwa-juice-shop.md#część-6-pierwszy-kontakt-z-kali)

**Po co:** Kali dostaje stały adres w tej samej sieci co `cele`, też bez bramy (internet zostaje na `eth1`). Testy potwierdzają, że widać obie aplikacje, a bazy nie.

```bash
sudo nmcli connection add type ethernet ifname eth0 con-name labnet ipv4.method manual ipv4.addresses 10.10.10.5/24 ipv6.method disabled connection.autoconnect-priority 10
sudo nmcli connection up labnet
ping -c 3 10.10.10.10
nmap -sV 10.10.10.10                      # tylko 22 i 3000: domyślnie 1000 portów
nmap -sV -p- 10.10.10.10                  # 22, 3000, 4280; bazy 3306 nie widać
ssh grzesiek@10.10.10.10                  # odcisk porównać ze wzorcem z konsoli cele
# Firefox: http://10.10.10.10:4280 i http://10.10.10.10:3000
```

### 7. Baza DVWA → [04d, część 7](04d-docker-dvwa-juice-shop.md#część-7-baza-dvwa-i-snapshot-cele-czyste)

**Po co:** kontener z bazą działa, ale baza jest pusta, więc logowanie nie działa. Bazę tworzy jeden przycisk.

```text
Firefox na Kali: http://10.10.10.10:4280/setup.php → Create / Reset Database
logowanie admin / password; okno „Save password” → Not now
(przy ćwiczeniach: DVWA Security → low)
```

### 8. Zabezpieczenie Kali → [04e, część 1](04e-zabezpieczenie-kali-i-stabilnosc.md#część-1-zabezpieczenie-kali)

**Po co:** Kali jest widoczny w całej sieci domowej. Wyłączone usługi, firewall i brak kluczy przerywają łańcuch przejęcia z [04b](04b-sieci-virtualbox.md#-jak-ktoś-z-sieci-domowej-mógłby-przejąć-kali-z-hasłem-kalikali) w kilku miejscach naraz.

```bash
systemctl is-active ssh                   # inactive
systemctl is-enabled ssh                  # disabled
sysctl net.ipv4.ip_forward                # = 0
sudo apt install -y ufw
sudo ufw enable
sudo ufw status verbose                   # deny (incoming), allow (outgoing), disabled (routed)
ls -la ~/.ssh                             # brak kluczy prywatnych
sudo timedatectl set-timezone Europe/Warsaw
date                                      # CEST
```

Na Raspberry:

```bash
nmap -Pn ADRES_KALI                       # 1000 filtered, ~200 s
```

### 9. Snapshoty → [04d, krok 33](04d-docker-dvwa-juice-shop.md#33-wyłączenie-i-snapshot-cele-czyste-dvwa-z-bazą), [04e, kroki 13 i 29](04e-zabezpieczenie-kali-i-stabilnosc.md#13-snapshot-kali-zabezpieczony-ufw-ssh-off-cest)

**Po co:** punkt powrotu po każdym ćwiczeniu. Zawsze na **wyłączonej** maszynie: mniejszy i czystszy, bez zawartości RAM.

| Maszyna | Snapshoty (od najstarszego) |
|---|---|
| Kali | „Kali 2026.2 czysty po aktualizacji” → **„Kali zabezpieczony (ufw, SSH off, CEST)”** |
| `cele` | „cele z Dockerem, przed labnet” → „cele czyste (DVWA z bazą)” → **„cele czyste (1 CPU, bez czekania na sieć)”** |

### 10. Stabilność: koniec zawieszania `cele` → [04e, część 2](04e-zabezpieczenie-kali-i-stabilnosc.md#część-2-śledztwo--dlaczego-cele-się-zawiesza)

**Po co:** `cele` stawała w miejscu na kilka minut (*soft lockup* do 490 s). Przyczyną były dwie rzeczy naraz: maszyny chciały wszystkie 4 rdzenie PC, a VirtualBox działał w wolnym trybie przez hypervisor Windowsa, włączony przez Integralność pamięci.

```powershell
systeminfo | Select-String "hypervisor"   # A hypervisor has been detected
(Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard).VirtualizationBasedSecurityStatus   # 2
(Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard).SecurityServicesRunning             # 2 = HVCI
# VirtualBox → cele → Ustawienia → System: Procesor 1, Płyta główna 2048 MB
```

```bash
nproc                                     # 1
free -h                                   # total 1.6Gi (część zarezerwowana na crashkernel)
```

Integralność pamięci zostaje włączona **na stałe**: na tym PC działa anty-cheat FACEIT, który wymaga VBS ([04e, decyzja](04e-zabezpieczenie-kali-i-stabilnosc.md#wynik-testu-i-decyzja)). Lab musi więc żyć z żółwiem: suma procesorów maszyn ≤ 3.

### 11. Start `cele` bez czekania na sieć → [04e, część 3](04e-zabezpieczenie-kali-i-stabilnosc.md#część-3-start-cele-bez-czekania-na-sieć)

**Po co:** sieć bez bramy nigdy nie wygląda na „gotową”, więc `systemd-networkd-wait-online` przy każdym starcie czekało 2 minuty.

```bash
sudo nano /etc/netplan/01-labnet.yaml     # pod "dhcp4: false" dopisać "optional: true"
sudo netplan generate
sudo reboot
systemd-analyze                           # 17.937s
```

---

## Problemy po drodze i czego mnie nauczyły

| # | Problem | Co było widać | Przyczyna | Rozwiązanie | Lekcja |
|---|---|---|---|---|---|
| 1 | `Get-FileHash` nic nie zwraca | brak wyniku i brak błędu | PowerShell był w innym folderze niż plik | `cd $HOME\Downloads` | cisza w terminalu nie znaczy sukcesu; sprawdzam, gdzie jestem |
| 2 | `shasum` nie istnieje | `The term 'shasum' is not recognized` | polecenie ze strony Ubuntu jest dla Linuksa/macOS | `Get-FileHash` i porównanie ręczne | instrukcje są pisane pod konkretny system |
| 3 | Instalacja nienadzorowana z kontem bez hasła | konto `vboxuser`, czerwony wykrzyknik | kreator VirtualBoxa chce zainstalować system sam | „Pomiń instalację nienadzorowaną” | domyślne ustawienia kreatorów czytam przed „Dalej” |
| 4 | Brak monitu logowania po pierwszym starcie `cele` | ekran komunikatów `cloud-init` | komunikaty przykryły `cele login:` | Enter | system czekał; ekran tylko tego nie pokazywał |
| 5 | Trzy literówki przy repozytorium Dockera | `downolad`, `dev` zamiast `deb`, `lisat.d` | ręczne przepisywanie w konsoli VirtualBoxa | krótsza linijka z gotowymi wartościami | długie komendy wklejam, nie przepisuję |
| 6 | `Invalid operation udpate` | czerwone `Error:` | literówka | `sudo apt update` | `apt` nie zgaduje |
| 7 | Nie da się wkleić do konsoli VirtualBoxa | wszystko trzeba przepisywać | schowek nie sięga do maszyny bez Guest Additions | przekierowanie portu NAT i SSH z PowerShella | do pracy na serwerze używam SSH, konsola jest awaryjna |
| 8 | `Connection refused` przy pierwszym `ssh -p 2201` | nikt nie słucha na porcie | reguła przekierowania jeszcze niezatwierdzona | OK w obu oknach | „refused” = nikt nie słucha na tym porcie |
| 9 | Odcisk klucza zaakceptowany bez porównania | `yes` od razu | pośpiech | porównanie ze wzorcem z konsoli | wzorzec bierzemy z konsoli, nie z sieci |
| 10 | Pomieszany ekran przy `apt` przez SSH | białe paski, `^[[B` | pasek postępu źle rysuje się w PowerShellu | nic | wygląd terminala to nie stan systemu |
| 11 | DVWA pobrane, ale nieuruchomione | brak `docker compose up -d` w wyniku | wklejona paczka komend zgubiła linijkę | `docker compose up -d` osobno | po wklejeniu kilku linijek sprawdzam każdą |
| 12 | Timeout przy pobieraniu Juice Shop | `timeout awaiting response headers` | Docker Hub nie odpowiedział na czas | `docker pull` ponownie | pobieranie wznawia się od miejsca przerwania |
| 13 | Wklejony blok „zjedzony” przez `sudo` | `Password:` w środku wklejania, `command not found` | `sudo` zapytało o hasło w połowie wklejania | wklejanie po jednej komendzie | przed blokiem z `sudo` najpierw `sudo true` (zasada w CLAUDE.md) |
| 14 | `ipa`, `sSnmap` zamiast `ip`, `nmap -sV` | `command not found` z propozycją instalacji | literówki | poprawna komenda | podpowiedź instalacji nie znaczy, że czegoś brakuje |
| 15 | DVWA nie widać w `nmap -sV` | tylko 22 i 3000 | domyślnie `nmap` skanuje 1000 popularnych portów, 4280 do nich nie należy | `nmap -sV -p-` | domyślny skan nie widzi wszystkiego |
| 16 | Okno „Save password” w Firefoksie | propozycja zapisania `admin`/`password` | domyślne zachowanie Firefoksa | Not now | na maszynie do ataków nie zapisuję haseł |
| 17 | *Soft lockup* przy instalacji `cele` | `CPU#0 stuck for 26s` | wirtualny procesor nie dostał czasu od Windowsa | nic, instalacja się udała | „BUG” w ostrzeżeniu jądra nie znaczy awarii; patrzę, czy wraca |
| 18 | Lockupy na `cele` do 490 s, oba procesory naraz | sześć ostrzeżeń `watchdog` | cała maszyna stała ponad 8 minut (pierwsze podejrzenie: uśpiony PC) | obserwacja | patrzę, ile procesorów i kiedy |
| 19 | `cele` przestała reagować, lockup 361 s przy pracy przy PC | brak reakcji na klawiaturę, `CPU#1 stuck for 361s!` | Kali 2 + `cele` 2 = wszystkie 4 rdzenie; VirtualBox przez hypervisor Windowsa (Integralność pamięci, żółw) | `Host+H` (ACPI), `cele` → 1 CPU i 2048 MB | suma procesorów maszyn < liczba rdzeni; diagnozę zaczynam od gospodarza |
| 19a | Więcej RAM-u dla `cele` nie pomogło | 4096 MB zamiast 2048 MB, zawieszenia dalej | problem dotyczył czasu procesora, nie pamięci (`cele` używała ~650 MB) | z powrotem 2048 MB, za to 1 procesor | najpierw czytam, o czym mówi błąd; zasoby „na ślepo” zabiera się gospodarzowi |
| 20 | Pierwszy ping Kali → `cele` po włączeniu `ufw` nie przeszedł | `Destination Host Unreachable` od 10.10.10.5 | `cele` jeszcze startowała | ponowny ping po chwili | „Unreachable” od własnego adresu = cel milczy, nie firewall |
| 21 | 2 minuty czekania na sieć przy starcie `cele` | `Job systemd-networkd-wait-online.service/start running` | sieć bez bramy nigdy nie jest „gotowa” | `optional: true` | w sieciach odciętych od świata kartę oznaczam jako opcjonalną |
| 22 | `free -h` pokazało 1,6 GiB zamiast ~1,9 | mniej pamięci, niż się spodziewałem | rezerwa na jądro awaryjne (*crashkernel*) | nic | „brakująca” pamięć to często rezerwa jądra |
| 23 | `vmwgfx … unsupported hypervisor` przy starcie `cele` | trzy linijki `*ERROR*` | sterownik grafiki wykrył VirtualBoxa pod hypervisorem | nic | nie każdy `ERROR` dotyczy czegoś, czego używam |

---

## Wszystkie zmienione pliki

**Na PC (Windows):**

| Co | Gdzie / co w nim jest |
|---|---|
| VirtualBox 7.2.14 (był wcześniej) | maszyny `kali-linux-2026.2-virtualbox-amd64` i `cele` |
| `C:\VMs\kali-linux-2026.2-virtualbox-amd64\` | maszyna Kali (`.vbox`, `.vdi`), ~15 GB |
| `C:\VMs\CELE\cele.vdi` | dysk `cele`, 25 GB dynamiczny |
| 7-Zip 26.04 | rozpakowanie obrazu Kali |
| sieć wewnętrzna `labnet` | tworzy ją VirtualBox; nie ma jej w Windowsie |
| `.7z` i `.iso` w Pobranych i `C:\VMs` | do usunięcia po imporcie (~7 GB) |

**Na Kali:**

| Plik / ustawienie | Co w nim jest |
|---|---|
| hasło użytkownika `kali` | zmienione |
| połączenie NetworkManager `labnet` | `eth0`: 10.10.10.5/24, bez bramy, IPv6 wyłączone |
| pakiet `ufw`, `/etc/ufw/` | firewall: `deny incoming`, włączany przy starcie |
| strefa czasowa | `Europe/Warsaw` |
| `~/.ssh/known_hosts` | odcisk klucza `cele` |

**Na `cele`:**

| Plik / folder | Co w nim jest |
|---|---|
| `/etc/apt/keyrings/docker.asc`, `/etc/apt/sources.list.d/docker.list` | klucz i adres repozytorium Dockera |
| Docker 29.9, grupa `docker` z użytkownikiem `grzesiek` | silnik kontenerów |
| `~/DVWA/compose.yml` | port `4280:80`, `pull_policy: missing` |
| kontenery `dvwa-dvwa-1`, `dvwa-db-1`, `juice-shop`; wolumen `dvwa_dvwa` | aplikacje i baza DVWA |
| `/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg` | cloud-init nie zarządza siecią |
| `/etc/netplan/01-labnet.yaml` | 10.10.10.10/24, bez bramy, `optional: true` |
| `/root/netplan-backup/` | stare pliki sieci z instalacji |
| ustawienia maszyny | 1 procesor, 2048 MB RAM, karta 1: `labnet` |

**W routerze:** rezerwacja DHCP dla karty mostkowanej Kali.

**Na Raspberry:** bez zmian (tylko skan kontrolny).

---

## Kontrola stanu: czy wszystko dalej działa

Uruchom obie maszyny. **W Kali:**

```bash
systemctl is-active ssh
sysctl net.ipv4.ip_forward
sudo ufw status verbose
ip -br a
timedatectl | grep "Time zone"
ping -c 2 10.10.10.10
nmap -p 22,3000,3306,4280 10.10.10.10
curl -sI http://10.10.10.10:4280 | head -1
curl -sI http://10.10.10.10:3000 | head -1
```

**W konsoli `cele`:**

```bash
nproc
ip -br a | grep enp0s3
ping -c 2 8.8.8.8
docker ps --format '{{.Names}}: {{.Status}}'
systemd-analyze | head -1
```

**Na Raspberry** (`ssh honeypi`):

```bash
nmap -Pn ADRES_KALI
```

| Komenda | Ma pokazać |
|---|---|
| `systemctl is-active ssh` | `inactive` |
| `sysctl net.ipv4.ip_forward` | `net.ipv4.ip_forward = 0` |
| `ufw status verbose` | `Status: active`, `deny (incoming), allow (outgoing), disabled (routed)` |
| `ip -br a` (Kali) | `eth0 UP 10.10.10.5/24`, `eth1` z adresem domowym |
| `timedatectl …` | `Europe/Warsaw (CEST, +0200)` |
| `ping 10.10.10.10` | 2 odpowiedzi (jeśli `cele` dopiero wstaje: `Unreachable`, poczekać chwilę) |
| `nmap -p 22,3000,3306,4280` | 22, 3000, 4280 `open`; **3306 `closed`** (baza niewidoczna z zewnątrz) |
| `curl …:4280` / `…:3000` | `HTTP/1.1 302 Found` / `HTTP/1.1 200 OK` |
| `nproc` (`cele`) | `1` |
| `ip -br a \| grep enp0s3` | `enp0s3 UP 10.10.10.10/24` |
| `ping 8.8.8.8` (`cele`) | `Network is unreachable` |
| `docker ps …` | `juice-shop`, `dvwa-dvwa-1`, `dvwa-db-1`: `Up …` |
| `systemd-analyze` | ok. 20 s, nie ponad 2 minuty |
| `nmap -Pn ADRES_KALI` (Raspberry) | `1000 filtered tcp ports (no-response)` |
| przez cały test (`cele`) | żadnego `soft lockup` |

---

## Słowniczek

| Pojęcie | Znaczenie |
|---|---|
| **maszyna wirtualna (VM)** | „komputer w komputerze”: program udaje sprzęt, na którym działa osobny system |
| **VirtualBox** | darmowy program do maszyn wirtualnych |
| **karta mostkowana (Bridged)** | wirtualna karta podpięta do prawdziwej; VM jest osobnym urządzeniem w sieci domowej |
| **sieć wewnętrzna (Internal)** | wirtualny kabel tylko między maszynami o tej samej nazwie sieci; bez routera i internetu |
| **NAT** (w VirtualBoxie) | VM schowana za adresem PC; ma internet, z sieci jej nie widać |
| **przekierowanie portu** | furtka w NAT: połączenie na port PC trafia na port w VM |
| **snapshot (migawka)** | zapisany stan maszyny, do którego można wrócić jednym kliknięciem |
| **suma SHA-256** | „odcisk palca” pliku; zgodny = plik nieuszkodzony w drodze |
| **podpis GPG** | podpis kluczem wydawcy; chroni także przed podmianą pliku i sumy na stronie |
| **Docker, obraz, kontener** | narzędzie do uruchamiania programów w paczkach; obraz = zamrożona paczka, kontener = jej uruchomiona kopia |
| **Docker Compose** | kilka kontenerów opisanych w jednym pliku `compose.yml` |
| **wolumen** | dysk kontenera, który przetrwa jego usunięcie (tu: baza DVWA) |
| **DVWA** | *Damn Vulnerable Web Application*: celowo dziurawa strona w PHP do nauki ataków WWW |
| **OWASP Juice Shop** | celowo dziurawy sklep internetowy z ponad setką wyzwań |
| **cloud-init** | program, który przy starcie Ubuntu Server ustawia m.in. sieć i klucze SSH |
| **netplan** | pliki YAML w `/etc/netplan/`, z których Ubuntu składa ustawienia sieci |
| **brama (gateway)** | adres, przez który system wysyła ruch do innych sieci, np. internetu; `cele` celowo jej nie ma |
| **odcisk klucza SSH** | skrót klucza serwera; porównany ze wzorcem z konsoli dowodzi, że łączę się z właściwą maszyną |
| **EUI-64** | sposób budowania adresu IPv6 `fe80::…` z adresu MAC; dlatego IPv6 zamazuję jak MAC |
| **`ufw`** | prosty firewall Linuksa (*Uncomplicated Firewall*) |
| **`ip_forward`** | ustawienie jądra: czy system przekazuje pakiety między kartami jak router |
| **Connect Scan / skan SYN** | `nmap` bez `sudo` nawiązuje pełne połączenia; z `sudo` tylko je zaczyna (szybciej, mniej widocznie) |
| **soft lockup** | ostrzeżenie jądra: procesor nie zrobił postępu przez ponad 20 s |
| **hypervisor** | warstwa, która dzieli prawdziwy procesor między systemy |
| **VBS / Integralność pamięci (HVCI)** | zabezpieczenia Windowsa oparte na wirtualizacji; włączają hypervisor Microsoftu |
| **żółw (NEM)** | tryb VirtualBoxa działającego przez hypervisor Windowsa: działa, ale wolniej |
| **ACPI** | sygnał „wyłącz się grzecznie”, jak krótkie naciśnięcie przycisku zasilania |
| **crashkernel** | zarezerwowana pamięć na awaryjne jądro, które zapisuje raport po awarii |
| **`systemd-networkd-wait-online`** | usługa, która przy starcie czeka, aż sieć będzie gotowa |
| **strefa czasowa / CEST** | sposób wyświetlania czasu; CEST = polski czas letni, UTC+2 |

---

## Co dalej

**Etap 4: pętla atak–wykrycie**, sedno całego labu. Z Kali skanuję Raspberry (`nmap -sV`, potem z `sudo`, czyli skan SYN) i sprawdzam w logach OpenCanary i Suricaty, czy obrońca to zauważył. Zgodna strefa czasowa Kali i Raspberry ułatwi porównanie godzin. Na koniec własna reguła Suricaty, która łapie coś, co wcześniej przeszło. Plan w [ROADMAP](../ROADMAP.md), instrukcja w [05 — Pierwsze ćwiczenie](05-first-exercise.md).

Poza etapem: decyzja o Windows 10 przed 13.10.2026 (Windows 11 czy PC tylko do labu; na nią wpływa też FACEIT, który na Windows 10 wymaga rozszerzonych aktualizacji ESU) i zrzuty z [04e](04e-zabezpieczenie-kali-i-stabilnosc.md#zrzuty-do-dodania) do obrobienia.
