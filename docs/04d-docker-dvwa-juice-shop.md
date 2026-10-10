# 04d — Docker, DVWA i Juice Shop na maszynie `cele`

**Data:** 2026-10-10 · **Czas:** ~1,5 godziny · **Gdzie:** maszyna `cele` (Ubuntu Server 26.04.1) w VirtualBoxie na PC z Windows 10

Ciąg dalszy [04c](04c-instalacja-kali-i-celow.md). Maszyna `cele` jest zainstalowana i ma internet przez NAT. W tym rozdziale:

1. instaluję Dockera z oficjalnego repozytorium,
2. uruchamiam dwie celowo dziurawe aplikacje: **DVWA** i **OWASP Juice Shop**,
3. odcinam `cele` od internetu i przełączam ją do zamkniętej sieci `labnet`, gdzie widzi ją tylko Kali.

Kolejność jest ważna: wszystko, co trzeba pobrać, pobieram **przed** przełączeniem karty. Po przełączeniu `cele` nie ma już skąd ściągać.

> ⚠️ DVWA i Juice Shop są dziurawe celowo. Nie mogą być widoczne ani w sieci domowej, ani w internecie, dlatego stoją na osobnej maszynie, w sieci, do której dostęp ma tylko Kali (art. 267 kk).

## Wynik w skrócie

| Co | Stan |
|---|---|
| Docker Engine 29.9.0 z repozytorium `download.docker.com` (wydanie `resolute`) | ✅ działa, test `hello-world` |
| DVWA + baza MariaDB 10 (`docker compose`), port 4280 | ✅ `HTTP/1.1 302 Found` |
| OWASP Juice Shop (`docker run`), port 3000 | ✅ `HTTP/1.1 200 OK` |
| Kontenery wstają same po restarcie (`restart: unless-stopped`) | ✅ |
| `cele` w `labnet` pod stałym adresem 10.10.10.10, bez internetu | ✅ `ping 8.8.8.8` → `Network is unreachable` |
| Snapshot „cele z Dockerem, przed labnet” | ✅ |

---

## Komendy w skrócie

Numery zgadzają się z ramkami na zrzutach w [`screenshots/2026-10-10-cele-docker/`](../screenshots/2026-10-10-cele-docker/). Krok 6 to klikanie w VirtualBoxie, opisane niżej.

```bash
# --- w konsoli VirtualBoxa, na cele ---
# 1. aktualizacja całego systemu
sudo apt update && sudo apt full-upgrade -y

# 2. narzędzia potrzebne do dodania repozytorium
sudo apt install -y ca-certificates curl git

# 3. klucz, którym Docker podpisuje swoje pakiety
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
ls -l /etc/apt/keyrings/docker.asc

# 4. adres repozytorium Dockera (amd64 = procesor, resolute = Ubuntu 26.04)
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu resolute stable" | sudo tee /etc/apt/sources.list.d/docker.list

# 5. odświeżenie list pakietów; szukam linijek z download.docker.com
sudo apt update
```

```powershell
# --- na PC, w PowerShellu (po kroku 6 w VirtualBoxie) ---
# 7. logowanie na cele przez przekierowany port; od teraz komendy można wklejać
ssh -p 2201 grzesiek@127.0.0.1
```

```bash
# --- na cele, przez SSH ---
# 8. Docker i jego dodatki
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 9. docker bez sudo; grupa działa dopiero po ponownym zalogowaniu
sudo usermod -aG docker grzesiek
exit
#    (na PC: ssh -p 2201 grzesiek@127.0.0.1)

# 10. test: Docker pobiera i uruchamia malutki obraz
docker run hello-world

# 11. DVWA: pobranie repozytorium z plikiem compose.yml
cd ~
git clone https://github.com/digininja/DVWA.git
cd DVWA

# 12. dwie zmiany w compose.yml i sprawdzenie
sed -i 's/pull_policy: always/pull_policy: missing/; s/127.0.0.1:4280:80/4280:80/' compose.yml
grep -n -E "pull_policy|4280" compose.yml

# 13. pobranie obrazów DVWA i bazy
docker compose pull

# 14. uruchomienie DVWA w tle
docker compose up -d

# 15. pobranie obrazu Juice Shop (powtarzać przy timeoucie)
docker pull bkimminich/juice-shop

# 16. uruchomienie Juice Shop w tle
docker run -d --name juice-shop --restart unless-stopped -p 3000:3000 bkimminich/juice-shop

# 17. lista działających kontenerów
docker ps

# 18. czy aplikacje odpowiadają
curl -sI http://localhost:4280 | head -1
curl -sI http://localhost:3000 | head -1
```

```bash
# --- przełączenie do labnet ---
# UWAGA: wklejaj po jednym poleceniu. Wklejony cały blok trafi w pytanie sudo o hasło (wpadka 19!)
# 19. cloud-init przestaje zarządzać siecią; stały adres 10.10.10.10 bez bramy
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
      addresses: [10.10.10.10/24]
EOF
sudo chmod 600 /etc/netplan/01-labnet.yaml
sudo netplan generate && echo KONFIG_OK

# 20. wyłączenie; potem w VirtualBoxie snapshot i karta 1 → labnet
sudo poweroff

# 21. po starcie, w konsoli VirtualBoxa: adres i brak internetu
ip -br a
ping -c 2 8.8.8.8
```

---

## Część 1: Docker z oficjalnego repozytorium

**Dlaczego nie `apt install docker.io` z Ubuntu ani snap?** Wersja z Ubuntu bywa starsza. Autor DVWA wspiera tylko najnowszy Docker i pisze, że wersja z menedżera pakietów działa „w miarę możliwości”. Snapa świadomie pominąłem przy instalacji systemu ([04c, krok 19](04c-instalacja-kali-i-celow.md#19-instalator-ubuntu-server)).

### 1. Aktualizacja

Aktualizacja przeszła bez błędów. Ważna linijka: `Running kernel seems to be up-to-date`, czyli restart nie jest potrzebny. Komunikat `User sessions running outdated binaries` dotyczy tylko mojej bieżącej sesji i znika po ponownym zalogowaniu.

![Koniec aktualizacji](../screenshots/2026-10-10-cele-docker/01-full-upgrade.png)

### 2–4. Klucz i adres repozytorium

Repozytorium to „sklep” z pakietami. Żeby `apt` ufał sklepowi Dockera, potrzebuje dwóch rzeczy:

- **klucza** (`docker.asc`), którym Docker podpisuje pakiety. `apt` sprawdza tym kluczem każdy pobrany plik; podrobiony pakiet nie przejdzie,
- **adresu** w pliku `/etc/apt/sources.list.d/docker.list`. Opcja `signed-by=` wiąże ten adres tylko z tym jednym kluczem.

Pierwsze podejście miało trzy literówki, opis w [❗ Wpadkach](#-wpadki). Na zrzucie 02 widać je w czerwonych ramkach.

![Literówki przy dodawaniu repozytorium](../screenshots/2026-10-10-cele-docker/02-repo-dockera-literowki.png)

Za drugim razem wpisałem gotowe wartości zamiast `$(dpkg --print-architecture)` i nazwy wydania z `/etc/os-release`. Obie znałem już z pierwszej próby (`amd64`, `resolute`), a krótsza linijka to mniej miejsc na literówkę. Klucz ma 3817 bajtów, czyli pobrał się w całości.

### 5. `apt update`: czy Docker jest w sklepie

Bez pliku `docker.list` w wyniku są tylko serwery Ubuntu (zrzut 03). Po poprawce pojawiają się dwie nowe linijki (zielone ramki na zrzucie 04):

- `Get:2 https://download.docker.com/... resolute InRelease`: repozytorium istnieje i ma podpisany spis,
- `Get:6 ... resolute/stable amd64 Packages`: jest w nim lista pakietów dla mojego procesora.

To była realna niewiadoma: Ubuntu 26.04 jest nowe, a Docker mógł go jeszcze nie obsługiwać. Wtedy zamiast `Get` byłoby `Err` albo `does not have a Release file`.

![apt update bez repozytorium Dockera](../screenshots/2026-10-10-cele-docker/03-apt-update-bez-dockera.png)
![Repozytorium Dockera działa](../screenshots/2026-10-10-cele-docker/04-repo-dockera-ok.png)

---

## Część 2: SSH z PC, żeby móc wklejać komendy

W konsoli VirtualBoxa nie da się wkleić tekstu ze schowka Windowsa (to wymaga dodatków *Guest Additions*, a Ubuntu Server ich nie ma). Przepisywanie długich linijek skończyło się literówkami, więc wchodzę na `cele` przez SSH z PowerShella, gdzie wklejanie działa.

### 6. Przekierowanie portu w NAT

Przy karcie NAT maszyna siedzi „za routerem” VirtualBoxa i z PC nie widać jej bezpośrednio. Przekierowanie portu otwiera jedną furtkę: połączenie na port 2201 w Windowsie VirtualBox przekazuje na port 22 (SSH) w `cele`.

**Ustawienia** maszyny `cele` → **Sieć** → **Karta 1** → **Zaawansowane** → **Przekierowanie portów** → zielony plus:

| Nazwa | Protokół | IP hosta | Port hosta | IP gościa | Port gościa |
|---|---|---|---|---|---|
| ssh | TCP | 127.0.0.1 | 2201 | (puste) | 22 |

- **IP hosta `127.0.0.1`**: furtka działa tylko z mojego PC. Puste pole oznaczałoby wszystkie karty Windowsa, więc do `cele` mógłby się dobijać każdy w sieci domowej.
- **Port 2201**, a nie 2222, żeby nie mylić z SSH na Raspberry.
- Reguła znika sama, gdy karta przestanie być w trybie NAT (krok 20).

![Reguła przekierowania portu](../screenshots/2026-10-10-cele-docker/05-przekierowanie-portu.png)

### 7. Pierwsze logowanie i odcisk klucza

Przy pierwszym połączeniu SSH pokazuje odcisk klucza serwera (ED25519) i pyta, czy mu ufam. Ten odcisk powinienem porównać z ekranem pierwszego startu `cele` ([04c, krok 22](04c-instalacja-kali-i-celow.md#22-pierwszy-start-klucze-ssh-serwera), zrzut 43). Zgodny odcisk dowodzi, że rozmawiam z moją maszyną. Na zrzucie odcisk i adres IPv6 są zamazane.

Dwie drobne wpadki (czerwona i żółta ramka 7!) opisuję w [❗ Wpadkach](#-wpadki).

![SSH z PowerShella i instalacja Dockera](../screenshots/2026-10-10-cele-docker/06-ssh-z-powershella.png)

---

## Część 3: Docker

### 8. Instalacja

Pięć pakietów:

| Pakiet | Co to |
|---|---|
| `docker-ce` | silnik Dockera (usługa w tle, która uruchamia kontenery) |
| `docker-ce-cli` | polecenie `docker`, którym wydaję mu rozkazy |
| `containerd.io` | niższa warstwa, która faktycznie uruchamia procesy kontenerów |
| `docker-buildx-plugin` | budowanie obrazów (tu nieużywane, instalowane w zestawie) |
| `docker-compose-plugin` | `docker compose`: kilka kontenerów z jednego pliku |

Wersje: Docker 29.9.0, containerd 2.4.1, Compose 5.6.0. Wszystkie z dopiskiem `ubuntu.26.04~resolute`, czyli zbudowane pod mój system.

### 9. Grupa `docker` i ponowne logowanie

`usermod -aG docker grzesiek` dodaje mnie do grupy `docker`, więc mogę wydawać polecenia bez `sudo`. Grupa działa od następnego logowania, stąd `exit` i ponowne `ssh`.

> ⚠️ **Uczciwie o bezpieczeństwie:** członek grupy `docker` może uruchomić kontener z całym dyskiem maszyny podpiętym do środka, czyli w praktyce ma uprawnienia roota. Na `cele`, celowo słabej maszynie w zamkniętej sieci, to w porządku. Na Raspberry tak bym nie zrobił.

![Grupa docker i wylogowanie](../screenshots/2026-10-10-cele-docker/07-grupa-docker-exit.png)

### 10. `hello-world`

Najmniejszy możliwy test: Docker sam pobiera obraz z Docker Hub, tworzy kontener i wypisuje `Hello from Docker!` (zielona ramka). Działa więc wszystko: usługa, polecenie bez `sudo` i pobieranie z internetu.

![hello-world](../screenshots/2026-10-10-cele-docker/08-hello-world.png)

---

## Część 4: DVWA i Juice Shop

**Obraz** to gotowa, zamrożona paczka z programem i wszystkim, czego potrzebuje. **Kontener** to uruchomiona kopia obrazu. Dzięki temu nie instaluję na `cele` PHP, MariaDB ani Node.js: każda aplikacja przychodzi z własnym kompletem.

### 11–12. DVWA: repozytorium i dwie zmiany w `compose.yml`

Autor DVWA ([github.com/digininja/DVWA](https://github.com/digininja/DVWA)) dostarcza plik `compose.yml` z dwoma kontenerami: DVWA (strona w PHP) i MariaDB (baza). Dwie domyślne opcje nie pasują do mojego labu, więc zmieniam je jednym `sed`:

| W `compose.yml` | Było | Jest | Dlaczego |
|---|---|---|---|
| `ports:` | `127.0.0.1:4280:80` | `4280:80` | domyślnie DVWA odpowiada tylko z wnętrza `cele`, więc Kali by go nie zobaczył. Bez adresu nasłuchuje na wszystkich kartach. Po przełączeniu `cele` ma tylko jedną: `labnet` |
| `pull_policy:` | `always` | `missing` | `always` = przy każdym starcie pobierz najnowszą wersję z internetu. Bez internetu start by się nie udał. `missing` = pobierz tylko, gdy obrazu nie ma |

`grep` potwierdza obie zmiany (linie 14 i 25).

### 13–14. Pobranie i start DVWA

`docker compose pull` pobrał oba obrazy (`Pulled`). Polecenie `docker compose up -d` za pierwszym razem się nie wykonało, opis w [❗ Wpadkach](#-wpadki). Po uruchomieniu `up -d` tworzy sieć `dvwa_dvwa`, wolumen `dvwa_dvwa` (dysk bazy, który przetrwa usunięcie kontenera) i dwa kontenery.

### 15–16. Juice Shop

[OWASP Juice Shop](https://owasp.org/www-project-juice-shop/) to sklep internetowy z ponad setką celowych dziur. Jeden kontener, więc wystarczy `docker run` bez pliku compose. Pierwsze uruchomienie przerwał timeout przy pobieraniu (czerwone ramki 16! na zrzucie 09). Osobne `docker pull` dokończyło pobieranie; warstwy, które już przyszły, nie pobierały się drugi raz.

![DVWA pobrany, timeout Juice Shop](../screenshots/2026-10-10-cele-docker/09-dvwa-pobrany-juice-timeout.png)

### 17–18. Sprawdzenie

`docker ps` pokazuje trzy kontenery w stanie `Up`:

| Kontener | Obraz | Port |
|---|---|---|
| `juice-shop` | `bkimminich/juice-shop` | `0.0.0.0:3000->3000/tcp` |
| `dvwa-dvwa-1` | `ghcr.io/digininja/dvwa:latest` | `0.0.0.0:4280->80/tcp` |
| `dvwa-db-1` | `mariadb:10` | `3306/tcp`, tylko wewnątrz sieci `dvwa_dvwa`, nie na zewnątrz |

`0.0.0.0` oznacza „wszystkie karty”, czyli efekt zmiany z kroku 12. Baza nie ma przekierowanego portu, więc z Kali da się do niej dobrać tylko przez dziury w DVWA, i o to chodzi w ćwiczeniach.

`curl` pyta same nagłówki odpowiedzi:

- DVWA: `HTTP/1.1 302 Found`, czyli przekierowanie na stronę logowania. Strona działa,
- Juice Shop: `HTTP/1.1 200 OK`.

![Trzy kontenery działają](../screenshots/2026-10-10-cele-docker/10-cele-dzialaja.png)

---

## Część 5: przełączenie do `labnet`

### 19. Stały adres bez bramy

Do tej pory adres dawał DHCP od NAT (`10.0.2.15`). W `labnet` nie ma żadnego serwera DHCP, więc adres trzeba wpisać na stałe.

**Pułapka cloud-init:** Ubuntu Server przy starcie odtwarza ustawienia sieci z pliku `50-cloud-init.yaml`. Gdybym tylko go edytował, przy którymś restarcie wróciłby DHCP. Dlatego najpierw wyłączam zarządzanie siecią przez cloud-init, przenoszę stare pliki do `/root/netplan-backup/` i zapisuję własny `01-labnet.yaml`.

W konfiguracji celowo **nie ma bramy** (`routes`/`gateway`): `cele` zna tylko sieć 10.10.10.0/24 i nie ma którędy wyjść do internetu. To druga warstwa zabezpieczenia, obok samej sieci wewnętrznej.

`netplan generate` sprawdza plik bez stosowania zmian i odpowiada `KONFIG_OK` (zielona ramka). `netplan apply` od razu zerwałby połączenie SSH, więc nowy adres zadziała po restarcie.

Pierwsza próba się nie udała: wkleiłem cały blok naraz, a `sudo` zapytało o hasło w połowie wklejania. Opis w [❗ Wpadkach](#-wpadki) (czerwone ramki 19!). Druga próba, polecenie po poleceniu, przeszła czysto.

![Wklejanie bloku i pytanie sudo, potem poprawnie](../screenshots/2026-10-10-cele-docker/11-netplan-wklejanie-sudo.png)

### 20. Snapshot i zmiana karty

Przy wyłączonej `cele`:

1. **Migawki** → **Zrób** → snapshot „cele z Dockerem, przed labnet” (punkt powrotu),
2. **Ustawienia** → **Sieć** → **Karta 1** → *Podłączona do:* **Sieć wewnętrzna**, nazwa **`labnet`** wybrana z listy, nie wpisana ręcznie. Ta sama nazwa co karta 1 w Kali, więc obie maszyny są „w jednym kablu”. Adres MAC na zrzucie zamazany.

![Snapshot przed przełączeniem](../screenshots/2026-10-10-cele-docker/12-snapshot-przed-labnet.png)
![Karta 1 w sieci wewnętrznej labnet](../screenshots/2026-10-10-cele-docker/13-karta-labnet.png)

Po przełączeniu `ssh -p 2201` z PowerShella kończy się `Connection refused`. To dobry znak: przekierowanie portu należało do karty NAT i zniknęło razem z nią. Z PC nie da się już dostać do `cele`.

![SSH z PC już nie działa](../screenshots/2026-10-10-cele-docker/14-ssh-po-przelaczeniu.png)

### 21. Sprawdzenie

W konsoli VirtualBoxa:

- `ip -br a`: `enp0s3 UP 10.10.10.10/24` (zielona ramka). Adres z pliku netplan zadziałał i cloud-init go nie nadpisał,
- `ping -c 2 8.8.8.8`: `Network is unreachable`. System nie zna żadnej drogi poza 10.10.10.0/24, więc nawet nie próbuje wysłać pakietu. **Cele są odcięte od internetu.**

Obok `enp0s3` widać karty, które stworzył Docker. Wszystkie żyją tylko wewnątrz `cele`:

| Karta | Adres | Co to |
|---|---|---|
| `docker0` | 172.17.0.1/16 | domyślna sieć Dockera, tu nieużywana (Juice Shop z `docker run` też tu jest podpięty) |
| `br-57035d39ba6d` | 172.18.0.1/16 | sieć `dvwa_dvwa` z `compose.yml`, w której DVWA rozmawia z bazą |
| `veth…@if2` (3 sztuki) | brak | „wirtualne kable”, po jednym na kontener |

Adresy IPv6 (`fe80::…`) na zrzucie zamazane. Literówkę `ipa` opisuję w wpadkach (żółta ramka 21!).

![labnet bez internetu](../screenshots/2026-10-10-cele-docker/15-labnet-bez-internetu.png)

---

## Co robi każda komenda

| Komenda | Co robi |
|---|---|
| `sudo apt update && sudo apt full-upgrade -y` | pobiera listy pakietów, potem instaluje nowsze wersje wszystkiego. `&&` = drugie tylko, gdy pierwsze się udało; `-y` = „tak” na pytania |
| `apt install -y ca-certificates curl git` | `ca-certificates`: lista zaufanych urzędów certyfikacji do połączeń `https`; `curl`: pobieranie z sieci; `git`: pobieranie repozytoriów kodu |
| `install -m 0755 -d /etc/apt/keyrings` | tworzy folder (`-d`) z prawami `0755`: właściciel pisze, wszyscy czytają |
| `curl -fsSL URL -o PLIK` | pobiera plik. `-f` = błąd zamiast strony błędu, `-s` = cicho, `-S` = ale pokaż błędy, `-L` = idź za przekierowaniami, `-o` = zapisz pod tą nazwą |
| `chmod a+r PLIK` | daje wszystkim (`a`) prawo odczytu (`+r`), żeby `apt` mógł przeczytać klucz |
| `ls -l PLIK` | szczegóły pliku: prawa, właściciel, rozmiar w bajtach, data |
| `echo "..." \| sudo tee PLIK` | `echo` wypisuje tekst, `\|` przekazuje go dalej, `sudo tee` zapisuje do pliku z prawami roota. Samo `sudo echo > plik` by nie zadziałało, bo przekierowanie `>` robi powłoka bez roota |
| `deb [arch=amd64 signed-by=…] URL resolute stable` | wpis repozytorium: pakiety binarne (`deb`) dla procesora `amd64`, sprawdzane tym kluczem, wydanie `resolute` (Ubuntu 26.04), gałąź `stable` |
| `ssh -p 2201 grzesiek@127.0.0.1` | połączenie SSH na port 2201 mojego PC, który VirtualBox przekazuje do `cele`. `-p` = port |
| `apt install -y docker-ce …` | instaluje Dockera; pakiety opisane w kroku 8 |
| `usermod -aG docker grzesiek` | `-G docker` = grupa, `-a` = **dopisz** do obecnych grup. Bez `-a` użytkownik wypadłby z innych grup, np. `sudo` |
| `exit` | wylogowanie i zamknięcie połączenia SSH |
| `docker run hello-world` | pobiera obraz `hello-world` (jeśli go nie ma) i uruchamia z niego kontener |
| `git clone URL` | pobiera całe repozytorium do nowego folderu |
| `sed -i 's/A/B/; s/C/D/' PLIK` | edytor strumieniowy: zamienia tekst A na B i C na D. `-i` = zmień plik na miejscu |
| `grep -n -E "a\|b" PLIK` | pokazuje linie z `a` albo `b`. `-n` = z numerami linii, `-E` = rozszerzone wyrażenia (działa `\|` jako „lub”) |
| `docker compose pull` | pobiera wszystkie obrazy wymienione w `compose.yml` |
| `docker compose up -d` | tworzy i uruchamia wszystko z `compose.yml`. `-d` = w tle (*detached*), terminal wraca od razu |
| `docker pull OBRAZ` | tylko pobiera obraz, niczego nie uruchamia |
| `docker run -d --name juice-shop --restart unless-stopped -p 3000:3000 OBRAZ` | `-d` = w tle, `--name` = nazwa kontenera, `--restart unless-stopped` = wstawaj po restarcie maszyny, chyba że ręcznie zatrzymam, `-p 3000:3000` = port 3000 maszyny → port 3000 kontenera |
| `docker ps` | lista działających kontenerów: obraz, stan, porty, nazwa |
| `curl -sI URL \| head -1` | `-I` = pobierz tylko nagłówki odpowiedzi, `head -1` = pokaż pierwszą linię (kod HTTP) |
| `sudo tee PLIK <<'EOF' … EOF` | *heredoc*: wszystko do linii `EOF` trafia do pliku. Apostrofy w `'EOF'` wyłączają podmienianie `$zmiennych` w środku |
| `mv /etc/netplan/*.yaml /root/netplan-backup/` | przenosi wszystkie stare pliki sieci do kopii zapasowej (`*` = dowolna nazwa) |
| `chmod 600 PLIK` | czytać i pisać może tylko właściciel (root); `netplan` ostrzega przy luźniejszych prawach |
| `netplan generate` | sprawdza konfigurację sieci i przygotowuje ją na następny start, ale nie zmienia działającej sieci |
| `sudo poweroff` | wyłącza maszynę |
| `sudo true` | nic nie robi, ale zmusza `sudo` do zapytania o hasło. Przez kilka minut kolejne `sudo` już nie pytają |
| `ip -br a` | krótka (`-br` = *brief*) lista kart: nazwa, stan, adresy |
| `ping -c 2 8.8.8.8` | 2 pakiety do publicznego serwera DNS Google; tu ma się **nie** udać |

---

## ❗ Wpadki

| Problem | Co było widać | Przyczyna | Rozwiązanie | Lekcja |
|---|---|---|---|---|
| Literówka w adresie (krok 3) | `curl: (6) Could not resolve host: downolad.docker.com` (zrzut 02, ramka 3!) | ręcznie przepisany adres, `downolad` zamiast `download` | to samo polecenie poprawnie | błąd (6) to brak takiej nazwy w DNS; najpierw czytam adres litera po literze |
| Plik repozytorium się nie zapisał (krok 4) | `/etc/apt/sources.lisat.d/docker.list: No such file or directory` (zrzut 02, ramka 4!) | dwie literówki: `dev` zamiast `deb` i `lisat.d` zamiast `list.d`. Folder `sources.lisat.d` nie istnieje | krótsza linijka z gotowymi wartościami `amd64` i `resolute` | „No such file or directory” przy zapisie zwykle znaczy zły folder, nie zły plik |
| `apt update` bez Dockera (krok 5) | same serwery `ubuntu.com` (zrzut 03) | skutek poprzedniej wpadki: brak pliku `docker.list` | poprawny krok 4 | brak błędu nie znaczy sukcesu; szukam linijki, której się spodziewam |
| `Invalid operation udpate` (krok 5) | czerwone `Error:` (zrzut 04, ramka 5!) | literówka w poleceniu | `sudo apt update` | apt zna tylko swoje polecenia i nie zgaduje |
| Nie da się wkleić komend do konsoli VirtualBoxa | wszystko trzeba przepisywać, stąd literówki wyżej | schowek Windowsa nie sięga do konsoli maszyny bez *Guest Additions* | przekierowanie portu i SSH z PowerShella (kroki 6–7) | długie komendy zawsze wklejam, a nie przepisuję |
| `Connection refused` przy pierwszym `ssh` (krok 7) | `ssh: connect to host 127.0.0.1 port 2201: Connection refused` (zrzut 06, czerwona ramka 7!) | nic nie nasłuchiwało na porcie 2201. Najpewniej reguła nie była jeszcze zatwierdzona w ustawieniach; po chwili drugie podejście przeszło | zatwierdzić oba okna (reguły i ustawień) przyciskiem OK | „refused” = nikt nie słucha na tym porcie; sprawdzam, czy ustawienie się zapisało |
| Złe hasło przy logowaniu (krok 7) | `Permission denied, please try again.` (zrzut 06, żółta ramka 7!) | literówka w haśle (znaków nie widać) | ponowne wpisanie | SSH daje kilka prób; po nich zamyka połączenie |
| Odcisk klucza zaakceptowany bez porównania (krok 7) | `yes` od razu po pytaniu o odcisk | pośpiech | porównać odcisk ze zrzutem 43 z [04c](04c-instalacja-kali-i-celow.md#22-pierwszy-start-klucze-ssh-serwera) | to jedyny moment, w którym SSH chroni przed podszyciem; przy kolejnym razie najpierw porównuję |
| Pomieszany ekran przy instalacji Dockera (krok 8) | białe paski i `^[[B` w wyniku | pasek postępu `apt` źle rysuje się w PowerShellu przez SSH | nic; instalacja przeszła | wygląd terminala to nie stan systemu; liczy się wynik końcowy |
| DVWA pobrany, ale nie uruchomiony (krok 14) | po `docker compose pull` od razu `docker run` dla Juice Shop | wklejona paczka komend „zgubiła” linijkę `docker compose up -d` | `docker compose up -d` osobno | po wklejeniu kilku linijek sprawdzam, czy każda się wykonała |
| Wklejony blok „zjedzony” przez `sudo` (krok 19) | `[sudo: authenticate] Password:` w środku wklejanego tekstu, 3 × `Authentication failed`, potem `network:: command not found` i podobne (zrzut 11, czerwone ramki 19!) | `sudo` zapytało o hasło (minął czas zapamiętania hasła). Wklejane linijki trafiły do pola hasła, a reszta wykonała się jako zwykłe komendy | wpisać hasło przy pierwszym `sudo`, potem wklejać po jednym poleceniu | przed wklejeniem bloku z `sudo` najpierw jedno krótkie `sudo true`, żeby hasło było już podane. Nic się nie zepsuło: bez hasła żadne `sudo` się nie wykonało |
| Złe hasło przy ponownym `sudo` (krok 19) | jedno `Authentication failed`, za drugim razem przeszło (zrzut 11) | literówka w haśle | ponowne wpisanie | hasła przy `sudo` nie widać, więc łatwo o literówkę |
| `Command 'ipa' not found` (krok 21) | Ubuntu proponuje instalację `freeipa-client` (zrzut 15, żółta ramka 21!) | literówka: `ipa` zamiast `ip` | `ip -br a` | podpowiedź „can be installed with” to nie znaczy, że trzeba coś instalować; najpierw sprawdzam pisownię |
| Timeout przy pobieraniu Juice Shop (krok 16) | `failed to copy: httpReadSeeker … timeout awaiting response headers` (zrzut 09, ramki 16!) | Docker Hub nie odpowiedział na czas przy jednej z warstw dużego obrazu (ponad 20 warstw pobieranych naraz) | `docker pull bkimminich/juice-shop`, potem `docker run` | timeout to zwykle chwilowy problem z siecią; pobieranie wznawia się od miejsca przerwania |

---

## Co dalej w tym etapie

- [x] Kroki 19–21: `cele` w `labnet` pod adresem 10.10.10.10, bez internetu
- [ ] Kali: stały adres 10.10.10.5 na `eth0` (karta w `labnet`)
- [ ] Testy z Kali: ping, `nmap`, DVWA (`http://10.10.10.10:4280`, pierwsza konfiguracja bazy przyciskiem **Create / Reset Database**) i Juice Shop (`http://10.10.10.10:3000`) w przeglądarce, `ssh` z porównaniem odcisku klucza
- [ ] Snapshot „cele czyste”
- [ ] Zabezpieczenie Kali według [04b, obrona](04b-sieci-virtualbox.md#jak-się-bronić)

➡️ Następnie: [05 — Pierwsze ćwiczenie](05-first-exercise.md)
