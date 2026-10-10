# 04b — Sieci w VirtualBoxie i ryzyko domyślnego hasła Kali

Rozdział do [04 — Atakujący](04-attacker-kali.md). Robię to pierwszy raz, więc najpierw tłumaczę, czym jest karta sieciowa i tryby sieci w VirtualBoxie, a potem pokazuję, jak ktoś z sieci domowej mógłby przejąć Kali, gdybym nie zmienił hasła `kali`/`kali`.

## Komendy w skrócie

```bash
# --- w Kali ---
# 1. zmiana domyślnego hasła (zaraz po pierwszym uruchomieniu)
passwd

# 2. jakie karty sieciowe ma Kali i jakie mają adresy
ip -br a

# 3. czy SSH jest wyłączone (oczekiwane: inactive)
systemctl is-active ssh

# 4. czy Kali przekazuje ruch między kartami (oczekiwane: 0)
sysctl net.ipv4.ip_forward

# 5. firewall: blokada ruchu przychodzącego
sudo apt install -y ufw
sudo ufw enable
sudo ufw status verbose
```

```bash
# --- na Raspberry ---
# 6. co widać na Kali z sieci domowej (oczekiwane: wszystkie porty closed/filtered)
nmap -Pn ADRES_KALI
```

`ADRES_KALI` to adres karty mostkowanej (`eth1`) z komendy 2. W repo go nie podaję, tak jak adresów innych urządzeń w sieci domowej.

---

## Karta sieciowa i wirtualna karta

**Karta sieciowa** to część komputera, przez którą wychodzi on do sieci. W moim PC to Killer E2500 z wpiętym kablem. Każda karta ma dwa adresy:

| Adres | Co to jest | Przykład |
|---|---|---|
| MAC | stały „numer seryjny” karty, nadany fabrycznie | `1C-1B-…` |
| IP | „adres domowy” w sieci, który karta dostaje od routera | `192.168.1.x` |

**Wirtualna karta** to program, który udaje kartę sieciową. Maszyna wirtualna (Kali) to „komputer w komputerze” i potrzebuje własnych kart, więc VirtualBox je symuluje. Kali ma dwie: `eth0` i `eth1`. Ich adresy MAC zaczynają się od `08:00:27`, czyli prefiksu VirtualBoxa.

O wszystkim decyduje to, **do czego wirtualną kartę podłączysz**: pole „Podłączona do” w ustawieniach sieci maszyny wirtualnej.

## Jak wygląda sieć labu

```text
                    [ Router ]  rozdaje adresy IP
                        |
            +-----------+------------------+
            |                              |   kabel
     [ Raspberry ]          +--------------|---------------- PC (Windows) ----+
     192.168.1.134          |     [ Karta Killer ]  prawdziwa, z kablem        |
                            |              ^                                   |
                            |              | eth1: most (Bridged)              |
                            |  +-----------|-------- VirtualBox ------------+  |
                            |  |       [ Kali ]          [ DVWA, Juice Shop ] |  |
                            |  |           | eth0               |           |  |
                            |  |  [====== sieć wewnętrzna labnet =======]   |  |
                            |  |          (bez routera, bez internetu)      |  |
                            |  +--------------------------------------------+  |
                            +--------------------------------------------------+
```

Karta `eth1` przez most wychodzi do sieci domowej, więc router, Raspberry i wszystkie urządzenia w domu widzą Kali. Karta `eth0` jest tylko w zamkniętej sieci `labnet` z celami ataku.

## Tryby sieci w VirtualBoxie

| Tryb | Z kim się łączy | Internet | W tym labie |
|---|---|---|---|
| **Mostkowana** (Bridged) | cała sieć domowa, VM jak osobne urządzenie | tak | Kali `eth1` → Raspberry i aktualizacje |
| **Wewnętrzna** (Internal) | tylko maszyny wirtualne z tą samą nazwą sieci | nie | Kali `eth0` → DVWA, Juice Shop w `labnet` |
| **Host-only** | maszyny wirtualne + mój PC | nie | nieużywana |
| **NAT** (domyślna) | VM schowana za adresem PC, z sieci jej nie widać | tak | nieużywana |

**Mostkowana** podpina wirtualną kartę Kali do prawdziwej karty Killer, jak rozdzielacz na kablu. Router widzi Kali jako nowe urządzenie z własnym MAC i daje mu własny adres IP, inny niż ma PC. Kali widzi całą sieć domową, ale **cała sieć domowa widzi też Kali**. Most nie tworzy nowej karty w Windowsie, tylko podpina się pod Killera (we właściwościach karty Ethernet widać to jako „VirtualBox NDIS6 Bridged Networking Driver”).

**Wewnętrzna** to wirtualny kabel tylko między maszynami wirtualnymi o tej samej nazwie sieci. Nie ma tam routera, internetu ani mojego PC, który tej sieci w ogóle nie widzi. Nikt nie rozdaje adresów IP, więc `eth0` w Kali jest na początku bez adresu i to jest normalne. Celowo dziurawe programy (DVWA, Juice Shop) stoją tylko tam, więc nikt z domu ani z internetu ich nie dosięgnie.

**Host-only** to kabel między maszynami wirtualnymi a samym PC. VirtualBox tworzy dla niego wirtualną kartę w Windowsie: w „Połączeniach sieciowych” to „Ethernet 2 — VirtualBox Host-Only Ethernet Adapter” z adresem `192.168.56.1`. W tym labie jej nie używam i niczemu nie przeszkadza.

**NAT** to tryb domyślny: maszyna wirtualna wychodzi do internetu „pod adresem” PC i nikt z sieci domowej jej nie widzi. Bezpieczny, ale Kali nie zobaczyłby wtedy Raspberry.

Kali ma po jednej karcie w obu światach, ale **sama nie przepuszcza ruchu między nimi**: Linux domyślnie nie przekazuje pakietów z karty na kartę (komenda 4 pokazuje `0`). Dlatego `labnet` zostaje zamknięty.

---

## Co robi każda komenda

| Komenda | Co robi |
|---|---|
| `passwd` | zmienia hasło bieżącego użytkownika. Pyta o stare hasło (`kali`), potem dwa razy o nowe. Przy wpisywaniu nic się nie wyświetla, to normalne |
| `ip -br a` | `ip a` wypisuje karty sieciowe i ich adresy, `-br` (*brief*) skraca to do jednej linijki na kartę |
| `systemctl is-active ssh` | sprawdza, czy usługa SSH teraz działa: `active` albo `inactive` |
| `sysctl net.ipv4.ip_forward` | odczytuje ustawienie jądra Linuksa: `0` = nie przekazuj pakietów między kartami, `1` = przekazuj (jak router) |
| `sudo apt install -y ufw` | instaluje prosty firewall `ufw`; `-y` odpowiada „tak” na pytania instalatora |
| `sudo ufw enable` | włącza firewall: domyślnie blokuje ruch przychodzący, wychodzący przepuszcza |
| `sudo ufw status verbose` | pokazuje, czy firewall działa i jakie ma reguły |
| `nmap -Pn ADRES_KALI` | skan 1000 najpopularniejszych portów Kali z Raspberry; `-Pn` = nie sprawdzaj najpierw pingiem (opis w [docs/07](07-skan-wlasnego-pc.md#co-robi-każda-komenda)) |

---

## ❗ Jak ktoś z sieci domowej mógłby przejąć Kali z hasłem `kali`/`kali`

Samo domyślne hasło jeszcze nie otwiera drzwi. Kali domyślnie **nie uruchamia usług nasłuchujących z sieci**, także SSH ([polityka Kali](https://www.kali.org/docs/policy/kali-linux-network-service-policy/)). Problem zaczyna się, gdy włączysz SSH, np. żeby wygodnie łączyć się z Kali z Windowsa. Wtedy w ruch idzie taki łańcuch:

1. **Atakujący jest już w mojej sieci.** Najczęściej to nie człowiek, tylko zarażone urządzenie: kamera, telewizor, telefon z malware. Może to też być gość z hasłem do Wi-Fi.
2. **Rozpoznanie.** Skanuje sieć tak, jak ja w [misji z `nmap`](07-skan-wlasnego-pc.md). Widzi nowe urządzenie z adresem MAC `08:00:27…`, czyli maszynę VirtualBoxa. W labach to prawie zawsze Kali.
3. **Skan portów.** Na tej maszynie znajduje otwarty port 22, czyli SSH.
4. **Logowanie domyślnym hasłem.** `kali`/`kali` jest na każdej liście domyślnych haseł. Zautomatyzowane malware sprawdza takie listy w kilka sekund, bez udziału człowieka.
5. **Pełna władza.** Użytkownik `kali` może używać `sudo`, a `sudo` pyta o to samo hasło. Atakujący zostaje administratorem (root) całej maszyny.

Cały łańcuch nie wymaga żadnej luki w oprogramowaniu. Wystarczą dwa zaniedbania naraz: włączona usługa logowania i niezmienione hasło.

### Co mógłby zrobić po przejęciu Kali

Przejęte Kali jest groźniejsze niż zwykły przejęty komputer, bo ma gotowe narzędzia ataku i dostęp do dwóch sieci naraz.

| Cel | Jak | Dlaczego to boli |
|---|---|---|
| Cele w `labnet` | Kali ma kartę w sieci wewnętrznej | atakujący dostaje drogę do celowo dziurawych programów, do których z domu nie miał dostępu |
| Raspberry | jeśli na Kali leży mój klucz SSH do `honeypi` | logowanie na prawdziwy SSH (port 2222) i przejęcie obrońcy |
| Inne urządzenia w domu | Kali jest w sieci domowej przez most | skaner, łamacz haseł i exploity są już zainstalowane, nie trzeba niczego ściągać |
| Sama maszyna | uprawnienia root | stała furtka (backdoor), odczyt moich notatek i plików, udział w botnecie |
| Mój Windows | ten sam kabel i ta sama sieć | kolejne próby, choć po [hardeningu z docs/07](07-skan-wlasnego-pc.md) PC nie odpowiada na żadnym porcie |

**Lekcja:** maszyna w trybie mostkowanym jest pełnoprawnym urządzeniem w sieci domowej i trzeba ją zabezpieczyć tak samo jak każde inne.

### Jak się bronić

Każdy punkt przerywa łańcuch w innym miejscu. Pierwszy wystarczy, żeby krok 4 przestał działać.

- [x] Hasło zmienione zaraz po pierwszym uruchomieniu (komenda 1): min. 12 znaków, nieużywane nigdzie indziej
- [x] SSH na Kali wyłączone (komenda 3 → `inactive`)
- [ ] Jeśli SSH jest potrzebne: logowanie tylko kluczem, bez hasła, tak jak na Raspberry ([docs/02c](02c-ssh-hardening.md)) — nie jest potrzebne
- [x] Firewall `ufw` włączony (komenda 5)
- [x] Na Kali nie leży klucz SSH do `honeypi`, chyba że jest naprawdę potrzebny
- [ ] Karta mostkowana odłączona, gdy ćwiczę tylko na celach w `labnet` (Ustawienia VM → Sieć → Karta 2 → odznaczyć „Włącz kartę sieciową”) — nawyk na ćwiczenia
- [x] Snapshot „czysty Kali po aktualizacji”: punkt powrotu, gdyby coś poszło źle
- [x] Skan z Raspberry nie pokazuje otwartych portów (komenda 6)

✅ Zrobione 2026-10-10, z wynikami i zrzutami: [04e, część 1](04e-zabezpieczenie-kali-i-stabilnosc.md#część-1-zabezpieczenie-kali).

---

➡️ **Następnie:** [04 — Atakujący, 4b. Kali Linux](04-attacker-kali.md#4b-kali-linux)
