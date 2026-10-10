# 04e — Zabezpieczenie Kali i stabilność labu

**Data:** 2026-10-10 · **Czas:** ~2 godziny · **Gdzie:** Kali i `cele` w VirtualBoxie, PowerShell na PC, Raspberry

Ostatni rozdział Etapu 3. Trzy części:

1. **Zabezpieczenie Kali** według listy z [04b, „Jak się bronić”](04b-sieci-virtualbox.md#jak-się-bronić): Kali ma kartę mostkowaną, więc widzi go cała sieć domowa i trzeba go chronić jak każde inne urządzenie.
2. **Śledztwo: dlaczego `cele` się zawiesza.** Ostrzeżenia *soft lockup* z [04d, krok 32](04d-docker-dvwa-juice-shop.md#32-ostrzeżenia-soft-lockup-na-cele) wróciły, a raz `cele` przestała odpowiadać na kilka minut. Szukam przyczyny od strony Windowsa.
3. **Koniec czekania na sieć przy starcie `cele`**, które dokładało do każdego uruchomienia ponad 2 minuty.

> ⚠️ Atakuję tylko własne Raspberry i własne maszyny w zamkniętej sieci wewnętrznej (art. 267 kk). Skan w tym rozdziale idzie z Raspberry na moje Kali.

## Wynik w skrócie

| Co | Stan |
|---|---|
| SSH na Kali | ✅ `inactive` i `disabled` |
| Przekazywanie ruchu między kartami Kali | ✅ `net.ipv4.ip_forward = 0` |
| Firewall `ufw` na Kali | ✅ `active`, `deny (incoming)`, `allow (outgoing)`, włącza się przy starcie |
| Klucze prywatne na Kali (np. do `honeypi`) | ✅ brak, w `~/.ssh` tylko `known_hosts` |
| Strefa czasowa Kali | ✅ `Europe/Warsaw` (CEST), tak samo jak Raspberry |
| Skan Kali z Raspberry | ✅ wszystkie 1000 portów `filtered`, 201,4 s |
| Snapshot „Kali zabezpieczony (ufw, SSH off, CEST)” | ✅ |
| Przyczyna zawieszania `cele` | ✅ znaleziona: 4 rdzenie na dwie maszyny + wolny tryb VirtualBoxa przez Integralność pamięci w Windowsie |
| `cele`: 1 procesor, 2048 MB RAM | ✅ test kilkunastu minut z Kali bez lockupów |
| Start `cele` bez czekania na sieć | ✅ 17,9 s zamiast ponad 2 minut |
| Snapshot „cele czyste (1 CPU, bez czekania na sieć)” | ✅ |

---

## Komendy w skrócie

Numery zgadzają się z ramkami na zrzutach (lista zrzutów na końcu rozdziału). Kroki 13, 14, 19, 20 i 29 to klikanie, opisane niżej.

```bash
# --- w Kali ---
# 1–3. czy Kali nic nie wystawia i nie przekazuje ruchu
systemctl is-active ssh                 # inactive
systemctl is-enabled ssh                # disabled
sysctl net.ipv4.ip_forward              # = 0

# 4–7. firewall
sudo true
sudo apt install -y ufw
sudo ufw enable
sudo ufw status verbose

# 8. ruch wychodzący dalej działa
ping -c 2 10.10.10.10

# 9. czy na Kali nie leży klucz do Raspberry
ls -la ~/.ssh

# 10–11. polski czas, jak na Raspberry
sudo timedatectl set-timezone Europe/Warsaw
date
```

```bash
# --- na Raspberry (z PC: ssh honeypi) ---
# 12. co widać na Kali z sieci domowej
nmap -Pn ADRES_KALI
```

```powershell
# --- na PC, w PowerShellu ---
# 16. czy Windows działa na hypervisorze
systeminfo | Select-String "hypervisor"

# 17. czy działa VBS (2 = działa)
(Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard).VirtualizationBasedSecurityStatus

# 18. która usługa VBS działa (2 = Integralność pamięci)
(Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard).SecurityServicesRunning
```

```bash
# --- w konsoli VirtualBoxa, na cele ---
# 21–22. czy zmiana procesora i pamięci się zapisała
nproc
free -h

# 24–26. start bez czekania na sieć
sudo true
sudo nano /etc/netplan/01-labnet.yaml   # dopisać "optional: true" pod "dhcp4: false"
sudo netplan generate
sudo reboot

# 27–29. sprawdzenie i wyłączenie przed snapshotem
ip -br a
systemd-analyze
sudo poweroff
```

`ADRES_KALI` to adres karty mostkowanej Kali (`eth1`). W repo go nie podaję, tak jak adresów innych urządzeń w sieci domowej ([04b](04b-sieci-virtualbox.md#komendy-w-skrócie)).

---

## Część 1: zabezpieczenie Kali

### 1–3. Czy Kali coś wystawia

Najpierw sprawdzam, czy Kali w ogóle ma „otwarte drzwi”.

- `systemctl is-active ssh` → **`inactive`**: SSH, czyli usługa zdalnego logowania, teraz nie działa.
- `systemctl is-enabled ssh` → **`disabled`**: nie włączy się też sama po restarcie. Kali tak ma domyślnie ([polityka Kali](https://www.kali.org/docs/policy/kali-linux-network-service-policy/)); sprawdzam, bo łatwo ją kiedyś włączyć „na chwilę” i zapomnieć.
- `sysctl net.ipv4.ip_forward` → **`= 0`**: Kali nie przekazuje pakietów z karty na kartę. Gdyby przekazywał (`1`), ktoś z sieci domowej mógłby przez Kali dostać się do zamkniętej sieci `labnet` z celowo dziurawymi aplikacjami.

### 4–7. Firewall `ufw`

To ten sam prosty firewall co na Raspberry ([02c, część 5](02c-ssh-hardening.md#część-5-firewall-ufw)). Na Kali nie był zainstalowany.

- `sudo true` najpierw, żeby hasło było podane, zanim cokolwiek wkleję (wpadka z [04d](04d-docker-dvwa-juice-shop.md#-wpadki)).
- `apt install -y ufw` zainstalował wersję 0.36.2 i od razu włączył usługę `ufw.service` przy starcie (`Created symlink …ufw.service`). Lista `no longer required` to pakiety, których już nic nie używa. Można je kiedyś usunąć przez `sudo apt autoremove`, ale nic nie muszę.
- `ufw enable` → `Firewall is active and enabled on system startup`.
- `ufw status verbose` → `Default: deny (incoming), allow (outgoing), disabled (routed)`.

Co znaczą te trzy słowa:

| Kierunek | Ustawienie | Po ludzku |
|---|---|---|
| `incoming` | `deny` | nikt z zewnątrz nie nawiąże połączenia z Kali |
| `outgoing` | `allow` | Kali sam łączy się z kim chce: aktualizacje, `nmap`, przeglądarka |
| `routed` | `disabled` | firewall nie przepuszcza ruchu „przez” Kali; to druga warstwa obok `ip_forward = 0` |

Odpowiedzi na połączenia, które Kali sam zaczął (np. strona DVWA odsyłająca treść), wracają normalnie. `ufw` pamięta, kto zaczął rozmowę.

> ℹ️ **Na później (Etap 5):** w niektórych ćwiczeniach DVWA to cel łączy się z powrotem do Kali (np. `nc -lvnp 4444` na Kali). Wtedy otworzę port **tylko od strony `labnet`**: `sudo ufw allow in on eth0 to any port 4444`. Karta mostkowana zostaje zamknięta.

### 8. Ruch wychodzący dalej działa

`ping -c 2 10.10.10.10`. Za pierwszym razem: `Destination Host Unreachable` od `10.10.10.5`, czyli od samego Kali. Za drugim: 2 odpowiedzi w ~1–2 ms. Pierwsza próba nie była winą firewalla; opis w [❗ Wpadkach](#-wpadki).

### 9. Czy na Kali nie leży klucz do Raspberry

`ls -la ~/.ssh`:

| Plik / folder | Co to jest |
|---|---|
| `known_hosts` | „książka adresowa”: serwery, z którymi Kali już się łączył, z odciskami ich kluczy (tu `cele` z [04d, krok 28](04d-docker-dvwa-juice-shop.md#28-ssh-z-porównaniem-odcisku)). To nie jest klucz |
| `known_hosts.old` | poprzednia wersja tej listy, zapisana przez `ssh` |
| `agent/` | folder, w którym nowsze wersje SSH trzymają połączenie z *ssh-agentem* (programem pamiętającym odblokowane klucze) |

Nie ma plików `id_ed25519` ani `id_rsa`, czyli **kluczy prywatnych**. Gdyby ktoś przejął Kali, nie znalazłby tu niczego, co otwiera `honeypi`. Tak ma zostać ([04b, tabela „Co mógłby zrobić”](04b-sieci-virtualbox.md#co-mógłby-zrobić-po-przejęciu-kali)).

### 10–11. Strefa czasowa

Gotowa maszyna Kali ma ustawiony czas nowojorski: skan w [04d](04d-docker-dvwa-juice-shop.md#2627-skan-portów-i-lekcja-o-domyślnym-zakresie) pokazał `05:54 -0400`. W Etapie 4 będę zestawiać godzinę ataku z Kali z godziną alertu na Raspberry, więc obie maszyny muszą mówić tym samym czasem.

`sudo timedatectl set-timezone Europe/Warsaw` nic nie wypisuje. `date` → `Sat Oct 10 01:32:01 PM CEST 2026`. **CEST** to polski czas letni (UTC+2).

Sam zegar był dobry; zmieniła się tylko strefa, czyli sposób wyświetlania. `cele` zostaje w UTC: to serwer, a w jej logach czas UTC jest wręcz wygodny.

### 12. Sprawdzian z drugiej strony: skan z Raspberry

Z PC `ssh honeypi`, potem `nmap -Pn ADRES_KALI`, tak jak w [misji skanu PC](07-skan-wlasnego-pc.md):

- `All 1000 scanned ports on kali.home (…) are in ignored states` i `Not shown: 1000 filtered tcp ports (no-response)`: firewall po cichu odrzuca każdą próbę. Raspberry nie dowiaduje się nawet, czy port jest zamknięty, czy go nie ma,
- `Host is up`: wiadomo tylko tyle, że urządzenie istnieje (`-Pn` = nie sprawdzaj pingiem, skanuj od razu),
- `201.40 seconds`, prawie co do sekundy jak skan PC po hardeningu (201,4 s). Ta sama przyczyna: `nmap` przy każdym porcie czeka na odpowiedź, która nie przychodzi, i ponawia próbę.

Dwie rzeczy warte zapamiętania z tego wyniku:

- **`Connect Scan`.** `nmap` bez `sudo` robi skan „grzeczny”: przy każdym porcie próbuje nawiązać pełne połączenie, jak zwykły program. Z `sudo` robi **skan SYN**: zaczyna połączenie i go nie kończy, szybciej i mniej widocznie. Różnicę sprawdzę w Etapie 4 na logach Suricaty.
- **`kali.home`.** Router sam podpowiedział nazwę urządzenia. Każdy, kto przeskanuje moją sieć, zobaczy maszynę o nazwie „kali”, czyli od razu wie, czym jest. Nic nie jest przez to otwarte, ale nazwa zdradza informację. Pomysł na później: nijaka nazwa (`hostnamectl set-hostname`).

### 13. Snapshot „Kali zabezpieczony (ufw, SSH off, CEST)”

`sudo poweroff`, potem w VirtualBoxie: Migawki → Zrób. Powstał pod snapshotem „Kali 2026.2 czysty po aktualizacji” z [04c, krok 15](04c-instalacja-kali-i-celow.md#15-snapshot). Przy „Aktualny stan” VirtualBox dopisał „(zmieniony)”: tak oznacza bieżący stan, gdy cokolwiek różni się od chwili zdjęcia. Snapshot jest zapisany.

---

## Część 2: śledztwo — dlaczego `cele` się zawiesza

### 14. Zawieszenie i „obudzenie” przez `Ctrl+H`

Po starcie `cele` z nowego snapshotu konsola przestała reagować: nie dało się nic wpisać ani kliknąć w maszynie. W oknie VirtualBoxa: **Maszyna → Wyłącz (ACPI)**, skrót **Host+H** (Host to prawy Ctrl). To sygnał „wyłącz się grzecznie”, jak krótkie naciśnięcie przycisku zasilania.

`cele` „obudziła się” i wypisała:

```
[  549.412211] watchdog: BUG: soft lockup - CPU#1 stuck for 361s! [containerd-shim:1472]
```

Procesor nr 1 maszyny przez **6 minut** nie dostał od Windowsa ani chwili czasu, około 9 minut po starcie. Ważne: tym razem **pracowałem przy komputerze**. Rano można było podejrzewać uśpiony PC ([04d, krok 32](04d-docker-dvwa-juice-shop.md#32-ostrzeżenia-soft-lockup-na-cele)); teraz to odpada. Problem leży po stronie Windowsa, który nie przydziela maszynie procesora.

### 15. Ile rdzeni ma komputer

Menedżer zadań (`Ctrl+Shift+Esc`) → Wydajność → Procesor:

| | U mnie |
|---|---|
| Procesor | Intel Core i5-7600K, 3,80 GHz |
| Rdzenie | **4** |
| Procesory logiczne | **4** (ten model nie ma Hyper-Threadingu) |
| Wirtualizacja | Włączone |

A maszyny chciały: Kali 2 + `cele` 2 = **4 procesory, czyli wszystko**. Windows, przeglądarka i sam VirtualBox też potrzebują czasu procesora i zabierają go którejś maszynie. Najczęściej obrywa `cele`, bo na niej nic się nie dzieje na ekranie.

**Zasada:** suma procesorów włączonych naraz maszyn powinna być **mniejsza** niż liczba rdzeni komputera. Co najmniej jeden rdzeń zostaje dla Windowsa.

### 16–18. Czy VirtualBox działa w wolnym trybie

| Komenda | Wynik | Co znaczy |
|---|---|---|
| `systeminfo \| Select-String "hypervisor"` | `A hypervisor has been detected` | Windows sam działa na hypervisorze Microsoftu |
| `…VirtualizationBasedSecurityStatus` | `2` | **VBS** (zabezpieczenia oparte na wirtualizacji) działa (`0` = wyłączone, `1` = włączone, ale nie działa) |
| `…SecurityServicesRunning` | `2` | VBS trzyma włączona **Integralność pamięci** (HVCI). `1` byłoby Credential Guard |

**Po ludzku:** normalnie VirtualBox rozmawia z procesorem bezpośrednio, jak kierowca z silnikiem. Gdy działa VBS, procesor „należy” do hypervisora Microsoftu. VirtualBox musi o każdą chwilę procesora prosić Windowsa, jak pasażer, który mówi kierowcy, dokąd jechać. Działa, ale dużo wolniej.

Hyper-V wyłączyłem dzień wcześniej ([07](07-skan-wlasnego-pc.md)), ale to wyłączyło tylko funkcję do tworzenia maszyn Hyper-V. Hypervisor zostaje, bo potrzebuje go Integralność pamięci.

### 19. Żółw na pasku stanu

W prawym dolnym rogu okna `cele`, na pasku małych ikonek, zamiast niebieskiego „V” stoi **zielony żółw**. Tak VirtualBox pokazuje, że działa przez hypervisor Windowsa (tryb NEM). To potwierdza wyniki 16–18.

### 20. Naprawa: `cele` dostaje 1 procesor i 2048 MB

Przy wyłączonej `cele`: Ustawienia → System:

- **Procesor → 1**. `cele` to mały serwer: dwie strony WWW i baza. Kali zostaje z 2, bo na nim działa Firefox i `nmap`. Razem 3, więc jeden rdzeń zostaje dla Windowsa,
- **Płyta główna → 2048 MB**. Było 4096 MB, choć `cele` używała ok. 650 MB. Windows dostaje więcej wolnej pamięci.

Przy okazji widać tam *OS Version: Ubuntu 25.04 (Plucky Puffin)*. VirtualBox 7.2.14 nie zna jeszcze 26.04 i wybrał najbliższą wersję. To tylko etykieta z domyślnymi ustawieniami, na działanie nie wpływa.

### 21–22. Sprawdzenie w `cele`

- `nproc` → **`1`**: system widzi jeden procesor,
- `free -h` → `total 1.6Gi`, `used 618Mi`, `available 1.0Gi`. Spodziewałem się ok. 1,9 GiB; brakujące ~300 MB Ubuntu domyślnie rezerwuje na **jądro awaryjne** (*crashkernel*): mały zapasowy system, który przy awarii głównego jądra zapisuje raport. `free` tej rezerwy nie liczy.

### Wynik testu i decyzja

`cele` pracowała potem kilkanaście minut razem z Kali (ufw, skan z Raspberry, przeglądarka). **Ani jednego lockupu.** Wcześniej pojawiały się po 9–11 minutach.

| Opcja | Plus | Minus | Decyzja |
|---|---|---|---|
| Zostawić Integralność pamięci, `cele` na 1 procesorze | Windows dalej chroniony przed podmianą kodu jądra | VirtualBox wolniejszy (żółw) | ✅ **teraz** |
| Wyłączyć Integralność pamięci (Zabezpieczenia Windows → Zabezpieczenia urządzenia → Izolacja rdzenia) | VirtualBox szybki, żółw znika | słabsza ochrona Windowsa | jeśli lockupy wrócą |

Na decyzję wpływa też Windows 10, który od 13.10.2026 przestaje dostawać łatki ([notatki z hardeningu PC](07-skan-wlasnego-pc.md)). Jeśli PC zostanie komputerem tylko do labu, wyłączenie Integralności pamięci kosztuje mniej.

---

## Część 3: start `cele` bez czekania na sieć

### 23. `Job systemd-networkd-wait-online.service/start running`

Przy każdym starcie `cele` stała na tej linijce z licznikiem `(21s / no limit)` i dopiero po ok. 2 minutach pokazywała logowanie.

**Co to jest:** `systemd-networkd-wait-online` przy starcie czeka, aż sieć będzie „gotowa”, żeby programy, które od razu łączą się z siecią, nie wywaliły się na starcie. Na zwykłym serwerze to ma sens. W `cele` celowo nie ma bramy ani internetu ([04d, krok 19](04d-docker-dvwa-juice-shop.md#19-stały-adres-bez-bramy)), więc ten moment może nie nadejść i usługa czeka do własnego limitu (domyślnie 2 minuty). `no limit` w komunikacie dotyczy samego zadania; program w środku ma swój limit i po nim się poddaje.

### 24–25. `optional: true`

W `nano` dopisałem jedną linijkę pod `dhcp4: false`, **tymi samymi spacjami** (w YAML wcięcia mają znaczenie, tabulator jest zabroniony):

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: false
      optional: true
      addresses: [10.10.10.10/24]
```

`optional: true` mówi: ta karta nie jest potrzebna do startu, nie czekaj na nią. Adres się nie zmienia.

`sudo netplan generate` nic nie wypisał. U `netplan` brak komunikatu znaczy, że plik jest poprawny.

### 26–28. Restart i sprawdzenie

- Po `sudo reboot` linijki `wait-online` już nie było.
- Na górze ekranu pojawiły się trzy `vmwgfx … *ERROR* … unsupported hypervisor`. To sterownik grafiki, który zauważył, że działa w VirtualBoxie pod hypervisorem Windowsa. Konsoli tekstowej to nie przeszkadza; zostawiam.
- `ip -br a` → `enp0s3 UP 10.10.10.10/24`: adres bez zmian.
- `systemd-analyze` → `Startup finished in 1.411s (kernel) + 3.406s (initrd) + 13.119s (userspace) = 17.937s`. **Start trwa 18 sekund** zamiast ponad dwóch minut.

### 29. Snapshot „cele czyste (1 CPU, bez czekania na sieć)”

`sudo poweroff`, potem Migawki → Zrób. To teraz aktualny punkt powrotu dla `cele`: Docker, obie aplikacje, baza DVWA, `labnet`, 1 procesor, szybki start.

---

## Co robi każda komenda

| Komenda | Co robi |
|---|---|
| `systemctl is-active USŁUGA` | czy usługa teraz działa: `active` / `inactive` |
| `systemctl is-enabled USŁUGA` | czy usługa włącza się przy starcie systemu: `enabled` / `disabled` |
| `sysctl net.ipv4.ip_forward` | odczytuje ustawienie jądra: `0` = nie przekazuj pakietów między kartami, `1` = przekazuj (jak router) |
| `sudo true` | nic nie robi, ale wymusza podanie hasła do `sudo` na kilka następnych minut |
| `sudo apt install -y ufw` | instaluje firewall `ufw`; `-y` = „tak” na pytania |
| `sudo ufw enable` | włącza firewall teraz i przy każdym starcie |
| `sudo ufw status verbose` | stan firewalla, domyślne zasady (`verbose` = ze szczegółami) i reguły |
| `ping -c 2 ADRES` | 2 pakiety „echo”; `-c` = count |
| `ls -la ~/.ssh` | zawartość folderu SSH użytkownika: `-l` = szczegóły (prawa, rozmiar, data), `-a` = także pliki ukryte; `~` = folder domowy |
| `sudo timedatectl set-timezone Europe/Warsaw` | ustawia strefę czasową systemu; listę nazw pokazuje `timedatectl list-timezones` |
| `date` | bieżąca data, godzina i strefa |
| `nmap -Pn ADRES` | skan 1000 najpopularniejszych portów; `-Pn` = nie sprawdzaj najpierw pingiem. Bez `sudo` robi *Connect Scan* |
| `systeminfo` | informacje o Windowsie; na końcu sekcja o wymaganiach Hyper-V |
| `\| Select-String "tekst"` | w PowerShellu: przepuszcza tylko linijki zawierające tekst (jak `grep` w Linuksie) |
| `Get-CimInstance -Namespace … -ClassName Win32_DeviceGuard` | odczytuje stan zabezpieczeń opartych na wirtualizacji. `(…).Pole` wybiera jedno pole z wyniku |
| `nproc` | ile procesorów widzi system |
| `free -h` | pamięć: `total` = cała, `used` = zajęta, `available` = dostępna dla nowych programów; `-h` = w czytelnych jednostkach (Mi, Gi) |
| `sudo nano PLIK` | prosty edytor tekstu w terminalu. `Ctrl+O` + Enter = zapisz, `Ctrl+X` = wyjdź |
| `sudo netplan generate` | sprawdza pliki w `/etc/netplan/` i przygotowuje konfigurację na następny start; brak komunikatu = poprawnie |
| `sudo reboot` | restart systemu |
| `ip -br a` | krótka lista kart sieciowych z adresami |
| `systemd-analyze` | ile trwał ostatni start: jądro, *initrd* (mały system startowy) i reszta (*userspace*) |
| `systemd-analyze blame` | lista usług od najdłużej startujących (przydatne przy szukaniu, co spowalnia start) |
| `sudo poweroff` | wyłącza system |

---

## ❗ Wpadki

| Problem | Co było widać | Przyczyna | Rozwiązanie | Lekcja |
|---|---|---|---|---|
| Pierwszy ping do `cele` się nie udał (krok 8) | `From 10.10.10.5 icmp_seq=1 Destination Host Unreachable` | `cele` jeszcze startowała (czekała na sieć, krok 23). Kali sam sobie odpowiedział: pod tym adresem nikt się nie zgłasza | ponowny ping po chwili: 2/2 | „Unreachable” od **własnego** adresu znaczy, że cel milczy. Firewall Kali ruchu wychodzącego nie blokuje |
| `cele` przestała reagować (krok 14) | nie da się nic wpisać ani kliknąć w maszynie | wirtualny procesor `cele` przez minuty nie dostawał czasu od Windowsa | Maszyna → Wyłącz (ACPI), `Host+H`; maszyna się „obudziła” | zanim wyłączę maszynę na twardo, próbuję grzecznego sygnału ACPI; a przy zawieszeniu sprawdzam najpierw, czy klawiatura w ogóle trafia do okna maszyny |
| *Soft lockup* 361 s mimo pracy przy PC (krok 14) | `CPU#1 stuck for 361s!` | Kali 2 + `cele` 2 procesory = wszystkie 4 rdzenie, a VirtualBox działał przez hypervisor Windowsa (Integralność pamięci, żółw) | `cele` → 1 procesor i 2048 MB; Integralność pamięci na razie zostaje | suma procesorów maszyn < liczba rdzeni komputera. Diagnozę zaczynam od tego, co widzi gospodarz (Menedżer zadań, `systeminfo`), nie tylko gość |
| Moja zapowiedź `1.9Gi` się nie sprawdziła (krok 22) | `free -h` → `total 1.6Gi` | Ubuntu rezerwuje ok. 300 MB na jądro awaryjne (*crashkernel*) | nic; wszystko w porządku | „brakująca” pamięć to często rezerwa jądra, nie usterka |
| 2 minuty czekania na sieć przy starcie (krok 23) | `Job systemd-networkd-wait-online.service/start running (21s / no limit)` | sieć bez bramy i internetu nigdy nie wygląda na „gotową”, więc usługa czeka do swojego limitu | `optional: true` w `01-labnet.yaml` | w sieciach odciętych od świata kartę oznaczam jako opcjonalną, żeby start na nią nie czekał |
| `vmwgfx … unsupported hypervisor` (krok 26) | trzy linijki `*ERROR*` na początku ekranu | sterownik grafiki wykrył VirtualBoxa pod hypervisorem Windowsa | nic | `ERROR` w logu startu nie zawsze dotyczy czegoś, czego używam; serwer bez pulpitu grafiki nie potrzebuje |

---

## Zrzuty do dodania

Zrzuty z tego rozdziału czekają na obróbkę według [zasad z CLAUDE.md](../CLAUDE.md#zrzuty-ekranu-screenshots) i trafią do `screenshots/2026-10-10-kali-zabezpieczenie/`. Plan:

| Plik | Kroki | Co zamazać / przyciąć |
|---|---|---|
| `01-kali-ssh-ufw-instalacja.png` | 1–5 | przyciąć pasek innego okna z lewej |
| `02-kali-ufw-ping.png` | 6–8 (8! żółta ramka przy pierwszym pingu) | przyciąć do terminala, bez paska Kali i VirtualBoxa |
| `03-kali-ssh-strefa-czasu.png` | 9–11 | — |
| `04-raspberry-nmap-kali.png` | 12 | **adres `fe80::…` w `Last login`** i **adres Kali** (w komendzie i w wyniku dwa razy) |
| `05-kali-snapshot.png` | 13 | — |
| `06-cele-zawieszona.png`, `07-cele-lockup-361s.png` | 14 (czerwone ramki) | przyciąć pasek innego okna z lewej |
| `08-menedzer-zadan-cpu.png` | 15 | przyciąć do nazwy procesora i tabeli na dole |
| `09-powershell-hypervisor-vbs.png`, `10-powershell-hvci.png` | 16–18 | przyciąć tło pulpitu |
| `11-zolw.png` | 19 | wycinek prawego dolnego rogu okna `cele`, powiększony |
| `12-cele-ustawienia-przed.png` | 20 (4096 MB, etykieta Ubuntu 25.04) | — |
| `13-cele-nproc-free.png` | 21–22 | — |
| `14-cele-wait-online.png` | 23 | przyciąć pasek innego okna z lewej |
| `15-netplan-optional.png` | 24–25 | — |
| `16-cele-szybki-start.png` | 26–29 | **adresy `fe80::…` w wyniku `ip -br a`** |

Do folderu [`2026-10-10-cele-docker/`](../screenshots/2026-10-10-cele-docker/) dochodzi jeszcze `25-snapshot-cele-czyste.png` (snapshot z [04d, krok 33](04d-docker-dvwa-juice-shop.md#33-wyłączenie-i-snapshot-cele-czyste-dvwa-z-bazą), przycięty bez tła pulpitu).

---

## Co dalej

Etap 3 jest zamknięty: 📋 [podsumowanie Etapu 3](etap-3-podsumowanie.md).

➡️ **Następnie:** [05 — Pierwsze ćwiczenie: pętla atak–wykrycie](05-first-exercise.md) (Etap 4)
