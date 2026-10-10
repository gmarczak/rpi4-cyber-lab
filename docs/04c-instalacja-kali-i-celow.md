# 04c — Instalacja Kali i maszyny z celami

**Data:** 2026-10-10 · **Czas:** ~3 godziny (z pobieraniem) · **Gdzie:** PC z Windows 10, VirtualBox

W tym rozdziale stawiam dwie maszyny wirtualne:

1. **Kali Linux**, czyli atakującego, z gotowego obrazu ze strony kali.org,
2. **`cele`**, czyli Ubuntu Server, na którym w następnym kroku postawię podatne aplikacje DVWA i OWASP Juice Shop.

Teorię sieci (czym jest karta mostkowana, wewnętrzna i NAT) opisuje [04b](04b-sieci-virtualbox.md). Tutaj jest praktyka: co kliknąłem, co wpisałem i na co trafiłem.

> ⚠️ Atakuję tylko własne Raspberry i własne maszyny w zamkniętej sieci wewnętrznej. Żadnych innych urządzeń w domu i nic z internetu (art. 267 kk).

## Wynik w skrócie

| Maszyna | System | RAM / CPU / dysk | Karty sieciowe | Stan |
|---|---|---|---|---|
| Kali | Kali Linux 2026.2, jądro 7.1.5 | 4096 MB / 2 / 80 GB dynamiczny | 1: wewnętrzna `labnet` · 2: mostkowana (Killer E2500) | ✅ zaktualizowany, widzi Raspberry, snapshot |
| `cele` | Ubuntu Server 26.04.1 LTS, jądro 7.0.0 | 2048 MB / 2 / 25 GB dynamiczny | 1: NAT (tymczasowo, do instalacji) | ✅ zainstalowany, czeka na Dockera i przełączenie na `labnet` |

Wersje programów na PC: VirtualBox 7.2.14 (był już zainstalowany; najnowszy w dniu instalacji: 7.2.20), 7-Zip 26.04.

---

## Komendy w skrócie

Numery zgadzają się z ramkami na zrzutach w [`screenshots/2026-10-10-kali-cele/`](../screenshots/2026-10-10-kali-cele/). Kroki bez komendy (klikanie w VirtualBoxie) są opisane niżej.

```powershell
# --- na PC, w PowerShellu ---
# 3. suma kontrolna pobranego obrazu Kali (najpierw wejdź do folderu z plikiem!)
cd $HOME\Downloads
Get-FileHash .\kali-linux-2026.2-virtualbox-amd64.7z -Algorithm SHA256

# 16. to samo dla obrazu Ubuntu Server
Get-FileHash .\ubuntu-26.04.1-live-server-amd64.iso -Algorithm SHA256
```

```bash
# --- w Kali ---
# 10. zmiana domyślnego hasła kali/kali
passwd

# 11. jakie karty sieciowe ma Kali i jakie adresy dostały
ip a

# 12. aktualizacja całego systemu, potem restart
sudo apt update && sudo apt full-upgrade -y
sudo reboot

# 13. czy działa nowe jądro i czy Kali widzi Raspberry
uname -r
ping -c 4 192.168.1.134

# 15. wyłączenie przed snapshotem
sudo poweroff
```

```bash
# --- w maszynie cele (Ubuntu Server) ---
# 23. nazwa, wersja systemu i adres
hostnamectl
ip a

# na koniec dnia
sudo poweroff
```

---

## Część 1: Kali

### 1. Gotowa maszyna zamiast instalatora

Na [kali.org/get-kali](https://www.kali.org/get-kali/#kali-virtual-machines) w zakładce **Pre-built VMs** wybrałem kafelek **VirtualBox**. To gotowa, zainstalowana maszyna wirtualna. Nie trzeba przechodzić instalatora, a domyślny login to `kali`/`kali`. Plik: `kali-linux-2026.2-virtualbox-amd64.7z`, 3,7 GB. 2026.2 była najnowszą wersją w dniu pobrania.

![Pobieranie zakończone](../screenshots/2026-10-10-kali-cele/01-kali-pobrany.png)
![Kafelek VirtualBox w Pre-built VMs](../screenshots/2026-10-10-kali-cele/02-kali-prebuilt-virtualbox.png)

### 2. 7-Zip

Obraz jest spakowany w formacie `.7z`, którego Windows nie otwiera sam. Zainstalowałem 7-Zip 26.04 (64-bit) z [7-zip.org](https://www.7-zip.org).

![7-Zip na stronie](../screenshots/2026-10-10-kali-cele/03-7zip-strona.png)
![7-Zip zainstalowany](../screenshots/2026-10-10-kali-cele/04-7zip-zainstalowany.png)

### 3. Suma kontrolna SHA-256

**Po co:** suma SHA-256 to „odcisk palca” pliku. Jeśli zgadza się co do znaku z sumą na stronie kali.org, plik dotarł cały i nikt go po drodze nie podmienił. Przy narzędziach do ataku to podstawowy nawyk: obraz z podmienionym kodem dałby komuś dostęp do mojej sieci.

Na kali.org pod kafelkiem VirtualBox jest link **sum**. Wynik z PowerShella był taki sam: `41ed7ec5…16909f3cee`. PowerShell pisze wielkimi literami, strona małymi; w zapisie szesnastkowym to bez znaczenia.

![Suma na kali.org](../screenshots/2026-10-10-kali-cele/06-suma-kali-org.png)
![Suma w PowerShellu](../screenshots/2026-10-10-kali-cele/07-suma-powershell.png)

> ℹ️ **Czego suma nie załatwia (poprawka po przeglądzie).** Zgodna suma dowodzi, że plik dotarł **cały i niezmieniony w drodze**. Ale sumę wziąłem z tej samej strony co plik. Gdyby ktoś przejął samą stronę kali.org, podmieniłby i obraz, i sumę, a moje porównanie i tak by się zgodziło. Przed tym chroni dopiero **podpis GPG**: Kali podpisuje plik z sumami (`SHA256SUMS.gpg`) swoim kluczem, a podpisu nie da się podrobić bez tego klucza. Do labu w domu wystarczy suma; w pracy przy narzędziach bezpieczeństwa sprawdza się też podpis.

Pierwsza próba nic nie zwróciła, opis w [❗ Wpadkach](#-wpadki).

### 4. Wersja VirtualBoxa

VirtualBox był już na PC: **7.2.14** (Pomoc → O VirtualBox). Na stronie była 7.2.20, ale do tego labu starsza wersja z linii 7.2 wystarcza. Extension Pack pominąłem, bo nie jest tu potrzebny (dodaje m.in. USB 3.0 i szyfrowanie dysków).

![Wersja VirtualBoxa](../screenshots/2026-10-10-kali-cele/08-virtualbox-wersja.png)

### 5. Rozpakowanie

Plik skopiowałem do `C:\VMs\` i rozpakowałem 7-Zipem (prawy przycisk → 7-Zip → Wypakuj do „kali-linux-2026.2-virtualbox-amd64\”). 3,7 GB rozpakowało się do ~15 GB w około pół minuty.

![Plik w C:\VMs](../screenshots/2026-10-10-kali-cele/09-folder-vms.png)
![Rozpakowywanie](../screenshots/2026-10-10-kali-cele/10-rozpakowywanie.png)

### 6. Import przez „Open”

W folderze są dwa pliki: `.vbox` (opis maszyny: RAM, karty, dyski) i `.vdi` (wirtualny dysk). W VirtualBoxie: **Open** → plik `.vbox`.

Nie **Importuj**: ten przycisk jest dla plików `.ova` (spakowana maszyna do przeniesienia). Kali dla VirtualBoxa przychodzi już rozpakowany.

Domyślnie maszyna ma 2048 MB RAM, 2 procesory i dysk 80 GB. Dysk jest **dynamiczny**: na PC zajmuje tyle, ile jest na nim danych (~15 GB), a nie 80 GB.

![Wybór pliku .vbox](../screenshots/2026-10-10-kali-cele/11-wybor-vbox.png)
![Maszyna na liście](../screenshots/2026-10-10-kali-cele/12-vm-zaimportowana.png)

### 7. Pamięć: 4096 MB

PC ma 16 GB RAM, więc Kali dostał 4 GB (Ustawienia → System → Płyta główna). Przy 8 GB w PC lepiej zostawić 2–3 GB. Procesory zostały 2.

![RAM 4096 MB](../screenshots/2026-10-10-kali-cele/13-ram-4096.png)

### 8. Karta 1: sieć wewnętrzna `labnet`

Ustawienia → Sieć → Karta 1 → **Sieć wewnętrzna**, nazwa `labnet`. Tą kartą Kali będzie atakować cele. W sieci wewnętrznej są tylko maszyny wirtualne z tą samą nazwą sieci; nie ma tam ani routera, ani internetu.

![Karta 1: labnet](../screenshots/2026-10-10-kali-cele/14-karta1-labnet.png)

### 9. Karta 2: mostkowana

Karta 2 → **Włącz** → **Mostkowana karta sieciowa** → karta Ethernet PC (Killer E2500). Dzięki niej Kali jest osobnym urządzeniem w sieci domowej i widzi Raspberry. Przez nią idzie też internet do aktualizacji.

*Promiscuous Mode* został na **Odmawiaj** na obu kartach. Ten tryb pozwala podsłuchiwać cudzy ruch na karcie; do skanowania `nmap` nie jest potrzebny.

![Karta 2: mostkowana](../screenshots/2026-10-10-kali-cele/15-karta2-mostkowana.png)

### 10. Pierwsze logowanie i hasło

Logowanie `kali`/`kali` i od razu `passwd`. **Po co od razu:** przez kartę mostkowaną Kali jest widoczny dla całej sieci domowej, a hasło `kali` zna każdy. Dlaczego to groźne: [04b, sekcja ❗](04b-sieci-virtualbox.md#-jak-ktoś-z-sieci-domowej-mógłby-przejąć-kali-z-hasłem-kalikali).

![Ekran logowania](../screenshots/2026-10-10-kali-cele/16-logowanie-kali.png)
![passwd](../screenshots/2026-10-10-kali-cele/17-passwd.png)

### 11. Sprawdzenie kart: `ip a`

- `eth0` (karta 1, `labnet`): `state UP`, ale **bez adresu IP**. Tak ma być: w sieci wewnętrznej nie ma jeszcze nikogo, kto rozdaje adresy (DHCP). Adres ustawię ręcznie razem z celami.
- `eth1` (karta 2, mostkowana): adres `192.168.1.x` od routera. Router dostał rezerwację DHCP, więc Kali ma zawsze ten sam adres i w logach Raspberry atakujący będzie zawsze pod jednym adresem.

Adres Kali, adresy MAC i IPv6 są na zrzucie zamazane.

![ip a w Kali](../screenshots/2026-10-10-kali-cele/18-ip-a-kali.png)

### 12. Aktualizacja

`sudo apt update` pobrał listy pakietów (77 MB w 8 s), `sudo apt full-upgrade -y` zainstalował nowsze wersje, w tym nowe jądro 7.1.5. Nowe jądro działa dopiero po restarcie.

![apt update](../screenshots/2026-10-10-kali-cele/19-apt-update.png)
![Koniec aktualizacji, nowe jądro](../screenshots/2026-10-10-kali-cele/20-upgrade-koniec.png)

### 13. Nowe jądro i ping do Raspberry

Po restarcie `uname -r` pokazał `7.1.5+kali-amd64`. `ping -c 4 192.168.1.134`: 4 wysłane, 4 odebrane, 0% strat, średnio 1,4 ms. **Kali widzi Raspberry**, czyli karta mostkowana działa.

![uname i ping](../screenshots/2026-10-10-kali-cele/21-uname-ping.png)

### 14. Rezerwacja DHCP dla Kali

W routerze (Statyczne adresy IP) dodałem Kali z adresem MAC karty mostkowanej, tak samo jak wcześniej Raspberry i PC. Bez zrzutu: na tej stronie są adresy i MAC innych urządzeń.

### 15. Snapshot

Maszyna wyłączona (`sudo poweroff`) → Migawki → **Zrób** → „Kali 2026.2 czysty po aktualizacji”.

**Po co:** snapshot to zapisany stan maszyny. Jeśli coś zepsuję albo maszynę „zainfekuję” w ćwiczeniu, wracam do tego punktu jednym kliknięciem (zaznacz snapshot → Przywróć, przy wyłączonej maszynie). Na wyłączonej maszynie snapshot jest najczystszy i najmniejszy, bo nie zapisuje zawartości RAM.

![Snapshot](../screenshots/2026-10-10-kali-cele/22-snapshot.png)

---

## Część 2: maszyna `cele`

**Dlaczego osobna maszyna, a nie Docker na Kali?** Kali ma kartę mostkowaną. Podatna aplikacja uruchomiona na Kali byłaby widoczna dla całej sieci domowej. `cele` będą miały tylko kartę w `labnet`, więc DVWA i Juice Shop zobaczy wyłącznie Kali.

### 16. Ubuntu Server i suma

Z [ubuntu.com/download/server](https://ubuntu.com/download/server): `ubuntu-26.04.1-live-server-amd64.iso` (LTS, wsparcie przez lata). Suma z `Get-FileHash` zgodna ze stroną: `cc8a95cd…a117f1d927`.

![Suma Ubuntu w PowerShellu](../screenshots/2026-10-10-kali-cele/23-ubuntu-suma-powershell.png)
![Instrukcja na stronie Ubuntu](../screenshots/2026-10-10-kali-cele/24-ubuntu-suma-strona.png)

Polecenie ze strony Ubuntu skończyło się błędem, opis w [❗ Wpadkach](#-wpadki).

### 17. Nowa maszyna w VirtualBoxie

**Nowa** → nazwa `cele`, typ Linux / Ubuntu (64-bit), obraz ISO z kroku 16:

- RAM **2048 MB**, **2** procesory, EFI wyłączone,
- dysk `C:\VMs\CELE\cele.vdi`, **25 GB**, VDI, dynamiczny,
- **Pomiń instalację nienadzorowaną** (zaznaczone w pierwszej sekcji kreatora).

**Po co pomijać:** kreator wypełnił instalację nienadzorowaną kontem `vboxuser` bez hasła (czerwony wykrzyknik). Instalacja ręczna pozwala samemu ustawić użytkownika, hasło i SSH.

![RAM i procesory](../screenshots/2026-10-10-kali-cele/25-cele-ram-cpu.png)
![Dysk 25 GB](../screenshots/2026-10-10-kali-cele/26-cele-dysk.png)
![Instalacja nienadzorowana z kontem bez hasła](../screenshots/2026-10-10-kali-cele/27-cele-nienadzorowana.png)

### 18. Karta 1: NAT, na razie

Na czas instalacji karta jest w trybie **NAT**: maszyna ma internet (do aktualizacji i pobrania Dockera), ale nikt z sieci domowej się do niej nie dostanie, bo NAT jej nie wystawia. Po zainstalowaniu aplikacji przełączę kartę na `labnet` i maszyna straci internet na stałe.

![Karta NAT](../screenshots/2026-10-10-kali-cele/28-cele-karta-nat.png)

### 19. Instalator Ubuntu Server

| Ekran | Wybór | Dlaczego |
|---|---|---|
| Język | English | komunikaty błędów łatwiej znaleźć w internecie |
| Klawiatura | Polish | polskie znaki i układ klawiszy |
| Typ instalacji | Ubuntu Server (pełny) | wersja *minimized* nie ma narzędzi dla człowieka przy konsoli |
| Sieć | `enp0s3`, DHCP: `10.0.2.15` | adres od wbudowanego „routera” NAT w VirtualBoxie |
| Dysk | cały dysk, bez LVM i szyfrowania | maszyna labowa, prostota wygrywa |
| Partycje | 1 MB na GRUB + ~25 GB ext4 na `/` | układ automatyczny |
| Potwierdzenie | Continue | formatuje tylko wirtualny dysk `cele.vdi`, nie dysk PC |
| Profil | użytkownik `grzesiek`, serwer `cele` | własne konto z silnym hasłem |
| Ubuntu Pro | Skip for now | niepotrzebne w labie |
| SSH | **Install OpenSSH server** | będzie celem skanu i logowania z Kali |
| Snapy | żadne | Dockera zainstaluję z oficjalnego repozytorium, nie jako snap |

![Język](../screenshots/2026-10-10-kali-cele/29-ubuntu-jezyk.png)
![Klawiatura](../screenshots/2026-10-10-kali-cele/30-ubuntu-klawiatura.png)
![Typ instalacji](../screenshots/2026-10-10-kali-cele/31-ubuntu-typ.png)
![Sieć](../screenshots/2026-10-10-kali-cele/32-ubuntu-siec.png)
![Dysk](../screenshots/2026-10-10-kali-cele/33-ubuntu-dysk.png)
![Partycje](../screenshots/2026-10-10-kali-cele/34-ubuntu-partycje.png)
![Potwierdzenie](../screenshots/2026-10-10-kali-cele/35-ubuntu-potwierdzenie.png)
![Profil](../screenshots/2026-10-10-kali-cele/36-ubuntu-profil.png)
![Ubuntu Pro](../screenshots/2026-10-10-kali-cele/37-ubuntu-pro.png)
![OpenSSH](../screenshots/2026-10-10-kali-cele/38-ubuntu-openssh.png)
![Snapy](../screenshots/2026-10-10-kali-cele/39-ubuntu-snapy.png)

> ℹ️ SSH na `cele` przyjmuje logowanie hasłem. Na Raspberry to wyłączyłem ([02c](02c-ssh-hardening.md)), ale `cele` to celowo słaby cel w zamkniętej sieci, więc tu zostaje.

### 20. Ostrzeżenie „soft lockup”

W trakcie pobierania aktualizacji pojawił się komunikat jądra. Opis w [❗ Wpadkach](#-wpadki). Instalacja poszła dalej.

![soft lockup](../screenshots/2026-10-10-kali-cele/40-soft-lockup.png)

### 21. Koniec instalacji

Log kończy się `finish: cmd-in-target: SUCCESS`. **Close** → **Reboot Now**.

![Instalacja zakończona](../screenshots/2026-10-10-kali-cele/41-instalacja-zakonczona.png)
![Reboot Now](../screenshots/2026-10-10-kali-cele/42-reboot-now.png)

### 22. Pierwszy start: klucze SSH serwera

Przy pierwszym starcie usługa **cloud-init** wygenerowała klucze SSH serwera (RSA, ECDSA, ED25519) i wypisała ich odciski. Klucze serwera to jego „dowód osobisty”: przy pierwszym `ssh` z Kali zobaczę odcisk i porównam go z tym ekranem. Zgodny odcisk znaczy, że łączę się z prawdziwą maszyną `cele`, a nie z kimś, kto się pod nią podszywa. Odciski i obrazki *randomart* są na zrzucie zamazane.

Komunikaty przykryły monit logowania. Wystarczy nacisnąć Enter.

![Klucze SSH przy pierwszym starcie](../screenshots/2026-10-10-kali-cele/43-pierwszy-start-klucze-ssh.png)

### 23. Sprawdzenie: `hostnamectl` i `ip a`

- `hostnamectl`: nazwa `cele`, Ubuntu 26.04.1 LTS, jądro 7.0.0-38, `Virtualization: oracle` (system wie, że działa w VirtualBoxie),
- `ip a`: `enp0s3` w stanie `UP` z adresem `10.0.2.15/24` z NAT.

Machine ID, Boot ID, adres MAC i adresy IPv6 zamazane.

![hostnamectl i ip a](../screenshots/2026-10-10-kali-cele/44-hostnamectl-ip-a.png)

---

## Co robi każda komenda

| Komenda | Co robi |
|---|---|
| `cd $HOME\Downloads` | przechodzi do folderu Pobrane. `$HOME` to folder użytkownika, np. `C:\Users\Grzesiek` |
| `Get-FileHash PLIK -Algorithm SHA256` | liczy sumę SHA-256 pliku. `-Algorithm SHA256` wybiera algorytm; strony podają zwykle właśnie SHA-256 |
| `passwd` | zmienia hasło zalogowanego użytkownika. Pyta o stare hasło, potem dwa razy o nowe. Znaki nie są wyświetlane |
| `ip a` | skrót od `ip address`: lista kart sieciowych z ich stanem (`UP`/`DOWN`), adresem MAC (`link/ether`) i adresami IP (`inet` to IPv4, `inet6` to IPv6) |
| `sudo` | uruchamia polecenie jako administrator (root) |
| `apt update` | pobiera aktualne listy pakietów z serwerów. Niczego nie instaluje |
| `apt full-upgrade -y` | instaluje nowsze wersje wszystkich pakietów; może usuwać lub dodawać pakiety, jeśli wymaga tego aktualizacja. `-y` odpowiada „tak” na pytania |
| `&&` | uruchamia drugie polecenie tylko wtedy, gdy pierwsze się udało |
| `sudo reboot` | restart systemu |
| `uname -r` | wersja działającego jądra Linuksa (`-r` = release) |
| `ping -c 4 ADRES` | wysyła 4 pakiety „echo” i czeka na odpowiedź. `-c 4` = count, bez tego ping działa w nieskończoność |
| `sudo poweroff` | wyłącza system |
| `hostnamectl` | nazwa maszyny, system, jądro, sprzęt i informacja o wirtualizacji |

---

## ❗ Wpadki

| Problem | Co było widać | Przyczyna | Rozwiązanie | Lekcja |
|---|---|---|---|---|
| `Get-FileHash` nic nie zwraca (krok 3) | brak wyniku i brak błędu ([zrzut 05](../screenshots/2026-10-10-kali-cele/05-hash-zly-folder.png)) | PowerShell był w `C:\Users\Grzesiek`, a plik w Pobranych. Wzorzec z `*` nie pasował do niczego, więc nie było czego liczyć | `cd $HOME\Downloads` przed `Get-FileHash` | cisza w terminalu nie znaczy sukcesu; sprawdzam, w jakim folderze jestem |
| `shasum` nie istnieje (krok 16) | `The term 'shasum' is not recognized…` ([zrzut 23](../screenshots/2026-10-10-kali-cele/23-ubuntu-suma-powershell.png)) | polecenie ze strony Ubuntu jest dla Linuksa i macOS; w PowerShellu go nie ma | `Get-FileHash` i ręczne porównanie z sumą ze strony | instrukcje w internecie są pisane pod konkretny system; sprawdzam, pod który |
| Instalacja nienadzorowana z kontem bez hasła (krok 17) | czerwony wykrzyknik, konto `vboxuser` ([zrzut 27](../screenshots/2026-10-10-kali-cele/27-cele-nienadzorowana.png)) | kreator VirtualBoxa domyślnie chce zainstalować system sam | zaznaczone „Pomiń instalację nienadzorowaną” | domyślne ustawienia kreatorów warto przeczytać, zanim kliknę „Dalej” |
| `watchdog: BUG: soft lockup - CPU#0 stuck for 26s` (krok 20) | komunikat na dole ekranu instalatora ([zrzut 40](../screenshots/2026-10-10-kali-cele/40-soft-lockup.png)) | wirtualny procesor przez 26 s nie dostał czasu od komputera, bo Windows był zajęty (pobieranie i zapis na dysk). Jądro to zauważyło i ostrzegło | nic, poczekać. Instalacja skończyła się `SUCCESS` | „BUG” w ostrzeżeniu jądra nie znaczy awarii; patrzę, czy system dalej robi postęp. Jeśli wraca często: sprawdzić, czy VirtualBox nie działa przez Hyper-V (zielony żółw na pasku stanu) |
| Brak monitu logowania po restarcie (krok 22) | ekran pełen komunikatów `cloud-init`, kursor na dole | komunikaty wypisały się po monicie `cele login:` i go przykryły | Enter | system czekał na login cały czas; ekran tylko tego nie pokazywał |

---

## Co dalej w tym etapie

- [x] Na `cele`: aktualizacja, Docker z oficjalnego repozytorium, DVWA i OWASP Juice Shop → [04d, części 1–4](04d-docker-dvwa-juice-shop.md)
- [x] Karta `cele` przełączona z NAT na `labnet`; stałe adresy w `labnet` dla `cele` i dla `eth0` w Kali → [04d, części 5–6](04d-docker-dvwa-juice-shop.md#część-5-przełączenie-do-labnet)
- [x] Testy z Kali: ping, `nmap`, obie aplikacje w przeglądarce, `ssh` z porównaniem odcisku klucza; `cele` bez internetu → [04d, część 6](04d-docker-dvwa-juice-shop.md#część-6-pierwszy-kontakt-z-kali)
- [x] Baza DVWA → [04d, część 7](04d-docker-dvwa-juice-shop.md#część-7-baza-dvwa-i-snapshot-cele-czyste)
- [ ] Snapshot „cele czyste (DVWA z bazą)”
- [ ] Zabezpieczenie Kali według [04b, obrona](04b-sieci-virtualbox.md#jak-się-bronić)

➡️ Następnie: [04d — Docker, DVWA i Juice Shop na `cele`](04d-docker-dvwa-juice-shop.md)
