# Etap 2 — Obrońca: podsumowanie

**Data:** 2026-10-09 · **Czas:** jedno popołudnie · **Szczegóły krok po kroku:** [03 — Obrońca](03-defender-raspberry.md)

Ten plik zbiera cały Etap 2 w jednym miejscu: co zrobiłem, po co, jakimi komendami, na jakie problemy trafiłem i jak sprawdzić, że wszystko działa. Pełne wyjaśnienia każdej komendy i zrzuty ekranu są w rozdziale 03.

---

## Cel etapu

Raspberry, zabezpieczone w Etapie 1, dostaje teraz zadanie obrońcy:

- **pułapka**: honeypot udający typowe usługi (SSH, stronę logowania, FTP). W domowej sieci nikt uczciwy nie ma po co się z nim łączyć, więc każde połączenie to alert, razem z loginem i hasłem, które ktoś próbował,
- **czujnik**: IDS Suricata, który ogląda cały ruch Raspberry i rozpoznaje znane ataki i skanery po regułach,
- **jedno miejsce do czytania alertów** z obu źródeł,
- wszystko **startuje samo** i **samo się aktualizuje**.

## Przed i po

| | Przed (po Etapie 1) | Po Etapie 2 |
|---|---|---|
| Port 22 | wolny | **honeypot SSH** (udaje Debiana) |
| Port 80 | zamknięty | **honeypot WWW**: panel logowania „DiskStation” |
| Port 21 | zamknięty | **honeypot FTP** |
| Port 2222 | moje SSH | bez zmian, moje SSH (tylko klucz) |
| Firewall `ufw` | tylko 2222 | 2222 + pułapki 21, 22, 80 |
| Analiza ruchu | brak | **Suricata 7.0.10**, 53 113 reguł ET Open |
| Reguły | — | aktualizowane codziennie ok. 4:30, bez restartu |
| „Atakujący z domu” | — | wykrywany (`EXTERNAL_NET: any`) |
| Logi | system na pendrivie | + `/var/log/opencanary/`, `/var/log/suricata/` (pendrive) |
| Podgląd alertów | — | `bash ~/check-logs.sh` |

## Jak to teraz wygląda

```
   PC / później Kali                         Raspberry Pi 4 "honeypi" (192.168.1.134)
 ┌──────────────────┐                ┌──────────────────────────────────────────────────┐
 │ przeglądarka     │── :80 ────────►│ ufw ─► OpenCanary (user: opencanary)             │
 │ ssh test@…       │── :22 ────────►│        ├─ :80  „DiskStation”  ─┐                 │
 │ ftp              │── :21 ────────►│        ├─ :22  udawany SSH    ─┼─► opencanary.log│
 │                  │                │        └─ :21  udawany FTP    ─┘                 │
 │ ssh honeypi      │── :2222 ──────►│ ufw ─► prawdziwe SSH (tylko klucz)               │
 └──────────────────┘                │                                                  │
                                     │ Suricata ── ogląda CAŁY ruch na eth0 ─► fast.log │
                                     │    ▲ reguły ET Open, odświeżane codziennie 4:30  │
                                     │                                                  │
                                     │ check-logs.sh ── czyta oba logi naraz            │
                                     │ /var/log ── na pendrivie                         │
                                     └──────────────────────────────────────────────────┘
```

---

## Kroki

### 1. Instalacja OpenCanary → [03, krok 1](03-defender-raspberry.md#krok-1-instalacja)

**Po co:** honeypot to program w Pythonie. Debian nie pozwala instalować bibliotek `pip` prosto do systemu, więc trafia do osobnego środowiska (*venv*) w `/opt/opencanary`, należącego do roota.

```bash
sudo apt install -y python3-dev python3-pip python3-venv libssl-dev libpcap-dev
sudo python3 -m venv /opt/opencanary
sudo /opt/opencanary/bin/pip install --upgrade pip
sudo /opt/opencanary/bin/pip install opencanary
/opt/opencanary/bin/pip show opencanary                              # 0.9.10
sudo env PATH=/opt/opencanary/bin:$PATH opencanaryd --copyconfig
ls -l /etc/opencanaryd/                                              # opencanary.conf, root
```

### 2. Pułapki, użytkownik i firewall → [03, krok 2](03-defender-raspberry.md#krok-2-konfiguracja-pułapek-i-firewall)

**Po co:** honeypot potrzebuje roota tylko do zajęcia portów poniżej 1024, potem przełącza się na konto, które nic nie może. Pułapki muszą być otwarte w firewallu, inaczej nic nie złapią.

```bash
sudo useradd --system --no-create-home --shell /usr/sbin/nologin opencanary
sudo install -d -o opencanary -g opencanary -m 750 /var/log/opencanary
sudo /opt/opencanary/bin/python3 - <<'EOF'
import json
p = '/etc/opencanaryd/opencanary.conf'
c = json.load(open(p))
c.update({
    "device.node_id": "honeypi",
    "ssh.enabled": True,  "ssh.port": 22,  "ssh.version": "SSH-2.0-OpenSSH_9.2p1 Debian-2+deb12u3",
    "http.enabled": True, "http.port": 80, "http.banner": "Apache/2.4.62 (Debian)", "http.skin": "nasLogin",
    "ftp.enabled": True,  "ftp.port": 21,  "ftp.banner": "FTP server ready",
})
c["logger"]["kwargs"]["handlers"]["file"]["filename"] = "/var/log/opencanary/opencanary.log"
json.dump(c, open(p, "w"), indent=4)
print("OK: zapisano", p)
EOF
sudo ufw allow 21/tcp comment 'honeypot FTP'
sudo ufw allow 22/tcp comment 'honeypot SSH'
sudo ufw allow 80/tcp comment 'honeypot HTTP'
```

### 3. Pierwsze alerty honeypota → [03, krok 3](03-defender-raspberry.md#krok-3-pierwszy-test-i-pierwsze-alerty)

**Po co:** sprawdzić całą drogę: atak z PC → pułapka → wpis w logu.

```bash
# okno 1 (Raspberry): honeypot na podglądzie, Ctrl+C kończy
sudo env PATH=/opt/opencanary/bin:$PATH opencanaryd --dev --uid=opencanary --gid=opencanary
# okno 2 (Raspberry)
sudo ss -tlnp | grep -E ':(21|22|80) '
sudo tail -f /var/log/opencanary/opencanary.log
```

Na PC: `http://192.168.1.134` → logowanie `admin` / `admin132`; `ssh test@192.168.1.134` → hasło `haslo123`. Oba trafiły do logu jako `logtype 3001` i `4002`, z adresem PC, programem klienta, loginem i hasłem.

### 4. Honeypot jako usługa → [03, krok 4](03-defender-raspberry.md#krok-4-honeypot-jako-usługa)

**Po co:** honeypot ma działać zawsze, startować sam i wstawać po awarii.

```bash
sudo cp config/systemd/opencanary.service /etc/systemd/system/      # albo blok tee z rozdziału 03
sudo systemctl daemon-reload
sudo systemctl enable --now opencanary
sudo reboot
systemctl is-active opencanary                                       # active
```

Plik usługi: [`config/systemd/opencanary.service`](../config/systemd/opencanary.service). Najważniejsze: `Environment=PATH=/opt/opencanary/bin:…` (ten sam problem co przy `--copyconfig`) i `RequiresMountsFor=/var/log/opencanary` (start dopiero po zamontowaniu pendrive'a).

### 5. Suricata: instalacja i reguły → [03, część 2, krok 1](03-defender-raspberry.md#krok-1-instalacja-reguły-i-test-konfiguracji)

**Po co:** honeypot widzi tylko to, co ktoś zrobi z pułapkami. Suricata ogląda cały ruch i rozpoznaje znane wzorce ataków.

```bash
sudo apt install -y suricata
suricata -V                                                          # 7.0.10
sudo grep -nE '^\s*- interface:|default-rule-path|HOME_NET:' /etc/suricata/suricata.yaml
sudo suricata-update                                                 # 69 064 reguł, 53 108 włączonych
sudo suricata -T -c /etc/suricata/suricata.yaml
```

Domyślna konfiguracja Debiana pasowała: karta `eth0`, ścieżka reguł zgodna z `suricata-update`, `HOME_NET` obejmuje sieć domową.

### 6. Suricata: „atakujący z domu” i uruchomienie → [03, część 2, krok 2](03-defender-raspberry.md#krok-2-atakujący-z-domu-uruchomienie-i-pierwszy-alert)

**Po co:** reguły wypatrują ruchu z `EXTERNAL_NET`, a domyślnie to „wszystko poza siecią domową”. W labie atakujący jest w sieci domowej, więc bez zmiany byłby niewidzialny.

```bash
sudo sed -i 's/^\(\s*\)EXTERNAL_NET: "!\$HOME_NET"/\1EXTERNAL_NET: "any"/' /etc/suricata/suricata.yaml
sudo suricata -T -c /etc/suricata/suricata.yaml
sudo systemctl enable suricata
sudo systemctl restart suricata
sudo tail -n 5 /var/log/suricata/suricata.log                        # Engine started
```

Test z PC (zapytanie z „podpisem” skanera Nmap):

```bat
curl -A "Mozilla/5.0 (compatible; Nmap Scripting Engine; https://nmap.org/book/nse.html)" http://192.168.1.134/
```

Wynik w `/var/log/suricata/fast.log`: `ET SCAN Nmap Scripting Engine User-Agent Detected` i `ET SCAN Possible Nmap User-Agent Observed`, priorytet 1.

### 7. Codzienna aktualizacja reguł → [03, część 2, krok 3](03-defender-raspberry.md#krok-3-codzienna-aktualizacja-reguł)

**Po co:** nowe zagrożenia pojawiają się codziennie. Reguły pobrane raz szybko się starzeją.

```bash
# pliki z config/systemd/ do /etc/systemd/system/ (albo bloki tee z rozdziału 03)
sudo systemctl daemon-reload
sudo systemctl enable --now suricata-rules-update.timer
sudo systemctl start suricata-rules-update.service                   # test na żądanie
systemctl status suricata-rules-update.service --no-pager            # status=0/SUCCESS
```

Usługa pobiera reguły (`suricata-update -q`) i wczytuje je bez restartu (`suricatasc -c reload-rules`). Harmonogram: codziennie 4:30 plus losowe do 30 minut, z nadrabianiem po wyłączeniu.

### 8. Podgląd alertów → [03, część 3](03-defender-raspberry.md#część-3-podgląd-alertów--check-logssh)

**Po co:** dwa źródła w dwóch formatach, a chcę jedną komendą zobaczyć, co się działo.

```bash
curl -fsSL https://raw.githubusercontent.com/gmarczak/rpi4-cyber-lab/master/config/scripts/check-logs.sh -o ~/check-logs.sh
bash ~/check-logs.sh
```

Wersja 2 pokazuje jedno zdarzenie w linijce (czas, źródło, port, rodzaj, login i hasło) i pomija komunikaty startowe honeypota.

---

## Problemy po drodze i czego mnie nauczyły

| # | Problem | Co było widać | Przyczyna | Rozwiązanie | Lekcja |
|---|---|---|---|---|---|
| 1 | `--copyconfig` „udany”, a pliku brak | `ModuleNotFoundError: No module named 'opencanary'`, `cp: missing destination`, a na końcu `config file is ready`; `ls` → `total 0` | `opencanaryd` to skrypt wołający `python3` z `PATH`; `sudo` podmienia `PATH`, więc uruchomił się systemowy Python bez OpenCanary. Skrypt nie sprawdza, czy kopiowanie się udało | `sudo env PATH=/opt/opencanary/bin:$PATH opencanaryd --copyconfig`; w usłudze `Environment=PATH=…` | komunikat „gotowe” to nie dowód, zawsze sprawdź wynik |
| 2 | Cztery komendy `ufw` wklejone naraz | pomieszany tekst `2/tcp comment…`, `statussudo ufw…`; w `ufw status` tylko 2222 i 21 | wykonała się pierwsza komenda, a `ufw` wczytał resztę wklejonego tekstu jako swoje wejście | `allow 22` i `allow 80` wpisane osobno, kontrola `ufw status` | jedna komenda = jedno wklejenie (moja wpadka: dałem cztery komendy w jednym bloku) |
| 3 | `ssh honeypi.local` zablokowane | `WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!` | PC pamiętał klucz prawdziwego SSH z portu 22; teraz odpowiada tam honeypot z innym kluczem | **nic**: wpis w `known_hosts` zostaje, testy honeypota po adresie IP, do Raspberry `ssh honeypi` (2222) | to właśnie ochrona przed podszyciem się pod serwer (*man-in-the-middle*) |
| 4 | Suricata ślepa na atakującego z domu | (zapobiegnięte) | domyślnie `EXTERNAL_NET: "!$HOME_NET"`, a mój PC jest w `HOME_NET`; reguły skanów patrzą na ruch z `EXTERNAL_NET` | `EXTERNAL_NET: "any"` | konfigurację IDS trzeba dopasować do tego, skąd w labie przychodzi „atak” |
| 5 | Test `testmynids.org` nic nie dał | `curl -s` nic nie wypisał, `fast.log` pusty | strona przestała istnieć (`Could not resolve host`), a `-s` ukrył błąd; nie było ruchu, więc nie było czego wykryć | diagnoza `curl -i` i `getent hosts`; test zastępczy z PC (nagłówek Nmap) | najpierw sprawdź, czy ruch w ogóle był, potem czy IDS go wykrył; `-s` przy diagnozie przeszkadza |
| 6 | Pomieszany tekst przy wklejaniu bloków `<<'EOF'` | fragmenty `target`, `R>`, `xecSta>`, `nt=true` między linijkami | terminal Windows tak wyświetla długie wklejenia | nic, pliki zapisały się poprawnie (potwierdził `systemctl status`) | po wklejeniu długiego bloku sprawdź wynik, a nie wygląd wklejenia |
| 7 | Nieczytelny `check-logs.sh` | ekran surowego JSON-u, głównie komunikaty startowe honeypota | wersja 1 wypisywała ostatnie linijki logu bez filtrowania | wersja 2: filtr `logtype 1001`, jedno zdarzenie w linijce | narzędzie do podglądu ma pokazywać to, co ważne, a nie wszystko |
| 8 | Literówka w haśle przy `sudo` | `Sorry, try again.` | — | wpisane ponownie | nic groźnego; `sudo` daje trzy próby |

---

## Wszystkie zmienione pliki

**Na Raspberry:**

| Plik / folder | Co w nim jest |
|---|---|
| `/opt/opencanary/` | środowisko Pythona z OpenCanary 0.9.10 (właściciel root) |
| `/etc/opencanaryd/opencanary.conf` | konfiguracja honeypota: pułapki 21, 22, 80, nazwa `honeypi`, ścieżka logu |
| `/var/log/opencanary/opencanary.log` | alerty honeypota (JSON, jedna linijka na zdarzenie) |
| `/etc/systemd/system/opencanary.service` | usługa honeypota |
| użytkownik `opencanary` | konto systemowe bez logowania, na którym działa honeypot |
| `/etc/suricata/suricata.yaml` | jedna zmiana: `EXTERNAL_NET: "any"` (linia 24) |
| `/var/lib/suricata/rules/suricata.rules` | reguły ET Open (aktualizowane codziennie) |
| `/var/log/suricata/` | `fast.log` (alerty), `eve.json` (wszystko), `stats.log`, `suricata.log` |
| `/etc/systemd/system/suricata-rules-update.service`, `.timer` | codzienna aktualizacja reguł |
| reguły `ufw` | + `21/tcp`, `22/tcp`, `80/tcp` (IPv4 i IPv6) |
| `~/check-logs.sh` | podgląd alertów |

**W repo:** [`config/systemd/`](../config/systemd/) (trzy pliki usług), [`config/opencanary/opencanary.conf.example`](../config/opencanary/opencanary.conf.example), [`config/scripts/check-logs.sh`](../config/scripts/check-logs.sh), [`config/scripts/setup-defender.sh`](../config/scripts/setup-defender.sh).

**Na PC i w routerze:** bez zmian.

---

## Kontrola stanu: czy wszystko dalej działa

Na Raspberry (`ssh honeypi`):

```bash
systemctl is-active opencanary suricata suricata-rules-update.timer
sudo ss -tlnp | grep -E ':(21|22|80|2222) '
sudo ufw status | grep -E '^(21|22|80|2222)/tcp '
sudo grep -n '^\s*EXTERNAL_NET:' /etc/suricata/suricata.yaml
systemctl list-timers suricata-rules-update.timer --no-pager
bash ~/check-logs.sh 5
```

Na PC, test całej drogi (honeypot i Suricata naraz):

```bat
curl -A "Mozilla/5.0 (compatible; Nmap Scripting Engine; https://nmap.org/book/nse.html)" http://192.168.1.134/
```

Potem jeszcze raz `bash ~/check-logs.sh 5` na Raspberry.

| Komenda | Ma pokazać |
|---|---|
| `systemctl is-active …` | trzy razy `active` |
| `ss -tlnp …` | `:21`, `:22`, `:80` → `twistd`; `:2222` → `sshd` |
| `ufw status …` | `2222/tcp`, `21/tcp`, `22/tcp`, `80/tcp` → `ALLOW` |
| `grep EXTERNAL_NET` | `EXTERNAL_NET: "any"` |
| `list-timers` | najbliższe uruchomienie jutro między 4:30 a 5:00 |
| `check-logs.sh` po teście z PC | honeypot: nowe `HTTP wejscie na strone`; Suricata: nowe `ET SCAN … Nmap …`, `P1` |

---

## Słowniczek

| Pojęcie | Znaczenie |
|---|---|
| **honeypot** | pułapka: udawana usługa, z którą nikt uczciwy nie ma po co się łączyć; każde połączenie to alert |
| **OpenCanary** | darmowy honeypot firmy Thinkst, udaje m.in. SSH, WWW, FTP |
| **IDS** (*Intrusion Detection System*) | system wykrywania włamań: analizuje ruch i ostrzega, ale go nie blokuje |
| **Suricata** | darmowy IDS; porównuje ruch z regułami |
| **reguła / sygnatura** | opis wzorca ataku; ma numer **SID** (np. `2009358`) i wersję |
| **ET Open** | darmowy zestaw reguł Emerging Threats |
| **`HOME_NET` / `EXTERNAL_NET`** | w Suricacie: „nasza sieć” i „skąd przychodzą ataki” |
| **`fast.log` / `eve.json`** | krótki dziennik alertów / pełny dziennik wszystkiego w JSON |
| **venv** | osobne środowisko Pythona z własnymi bibliotekami |
| **`PATH`** | lista folderów, w których system szuka programów; `sudo` ją podmienia |
| **`logtype`** | w OpenCanary: rodzaj zdarzenia (3001 = logowanie WWW, 4002 = logowanie SSH, 1001 = start) |
| **User-Agent** | nagłówek, którym program przedstawia się serwerowi WWW; skanery często zdradzają się właśnie nim |
| **systemd timer** | harmonogram systemd, odpowiednik `cron`; uruchamia usługę o zadanej porze |
| **`Type=oneshot`** | usługa, która wykonuje zadanie i się kończy |
| **heredoc** (`<<'EOF' … EOF`) | sposób przekazania wielu linijek tekstu do komendy |
| **man-in-the-middle** | atak, w którym ktoś podszywa się pod serwer między klientem a serwerem |

---

## Co dalej

**Etap 3: atakujący.** VirtualBox na PC, Kali Linux w maszynie wirtualnej z dwiema kartami sieciowymi, a cele DVWA i Juice Shop w odizolowanej sieci wewnętrznej. Plan w [ROADMAP](../ROADMAP.md), instrukcja w [04 — Atakujący](04-attacker-kali.md). W Etapie 4 prawdziwy skan `nmap` z Kali sprawdzi obrońcę z tego etapu.
