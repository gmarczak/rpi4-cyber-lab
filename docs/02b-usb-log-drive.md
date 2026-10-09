# 02b — Pendrive na logi

Czas: ~10 min. Wszystko przez SSH.

Honeypot i Suricata zapisują dużo logów. Karta microSD ma ograniczoną liczbę zapisów i przy ciągłym logowaniu szybko się zużywa, a na niej jest cały system. Dlatego logi trafią na osobny pendrive: jak się zużyje, wymieniasz pendrive za kilkadziesiąt złotych, a system zostaje nietknięty.

Efekt: pendrive sformatowany na **ext4**, z etykietą `logs`, widoczny jako folder **`/mnt/logs`** i montowany sam po każdym restarcie.

> ⚠️ **Formatowanie kasuje wszystko na pendrivie.** Zanim zaczniesz, sprawdź w kroku 1, która nazwa to pendrive, a która karta z systemem. Pomyłka i sformatowanie karty oznacza nagrywanie systemu od nowa.

## Komendy w skrócie

```bash
lsblk                                                                         # 1
sudo wipefs -a /dev/sda                                                       # 2
sudo parted /dev/sda --script mklabel gpt mkpart logs ext4 0% 100%            # 3
sudo mkfs.ext4 -L logs /dev/sda1                                              # 4
sudo mkdir -p /mnt/logs                                                       # 5
echo 'LABEL=logs /mnt/logs ext4 defaults,noatime,nofail 0 2' | sudo tee -a /etc/fstab   # 6
sudo systemctl daemon-reload                                                  # 7
sudo mount -a                                                                 # 8
df -h /mnt/logs                                                               # 9
```

Numery odpowiadają oznaczeniom na zrzutach poniżej.

![Formatowanie pendrive'a, część 1](../screenshots/2026-10-09-assembly/23-usb-format-1.png)

![Formatowanie pendrive'a, część 2](../screenshots/2026-10-09-assembly/24-usb-format-2.png)

## Co robi każda komenda

### 1 · `lsblk`: znajdź pendrive

Pokazuje wszystkie dyski i partycje. Rozpoznajesz je po rozmiarze i nazwie:

| Nazwa | Rozmiar | Co to jest |
|---|---|---|
| `mmcblk0` | 59,5 GB | **karta microSD z systemem**, tej nie ruszamy |
| `mmcblk0p1` | 512 MB | partycja startowa (`/boot/firmware`) |
| `mmcblk0p2` | 59 GB | system (`/`) |
| `sda` | 57,3 GB | **pendrive**, to go formatujemy |
| `sda1` | 57,3 GB | fabryczna partycja na pendrivie |
| `zram0`, `loop0` | 2 GB | pamięć wirtualna w RAM, nie dyski fizyczne |

Kolumna `RM` = `1` oznacza nośnik wyjmowany, czyli kolejną wskazówkę, że `sda` to pendrive.

### 2 · `sudo wipefs -a /dev/sda`: wyczyść stare oznaczenia

- `sudo`: uruchom jako administrator. Za pierwszym razem pyta o hasło.
- `wipefs`: usuwa „podpisy” systemów plików i tablicy partycji, czyli informacje, jak pendrive był sformatowany fabrycznie (u nas był to stary typ tablicy, `dos`).
- `-a`: usuń wszystkie znalezione podpisy.
- `/dev/sda`: cały pendrive, nie tylko jedna partycja.

Wynik `Success` znaczy, że system przeczytał pendrive na nowo i widzi go jako pusty.

### 3 · `sudo parted ... mklabel gpt mkpart logs ext4 0% 100%`: załóż partycję

- `parted /dev/sda`: program do dzielenia dysku na partycje.
- `--script`: nie zadawaj pytań, wykonaj od razu.
- `mklabel gpt`: nowa, pusta tablica partycji typu **GPT** (nowoczesny standard).
- `mkpart logs ext4 0% 100%`: jedna partycja o nazwie `logs`, od początku do końca dysku. Po tej komendzie pojawia się `/dev/sda1`.

Komenda nic nie wypisuje, gdy wszystko jest w porządku.

### 4 · `sudo mkfs.ext4 -L logs /dev/sda1`: sformatuj

- `mkfs.ext4`: tworzy system plików **ext4**, standardowy na Linuksie. Jest odporny na nagłe wyłączenie prądu dzięki dziennikowi (*journal*). Windows go nie odczyta, ale ten pendrive i tak zostaje w Raspberry.
- `-L logs`: etykieta (nazwa) systemu plików. Dzięki niej w kroku 6 odwołujemy się do pendrive'a po nazwie, a nie po `/dev/sda1`, które po podłączeniu innego dysku USB mogłoby się zmienić.
- `/dev/sda1`: partycja z kroku 3.

Linijki kończące się na `done` oznaczają sukces. *Superblock backups* to zapasowe kopie informacji o systemie plików, przydatne przy naprawie.

### 5 · `sudo mkdir -p /mnt/logs`: przygotuj folder

Tworzy pusty folder `/mnt/logs`. Na Linuksie dysk nie dostaje litery jak `D:`, tylko „wpina się” w wybrany folder (*punkt montowania*). Po zamontowaniu wszystko, co zapiszesz w `/mnt/logs`, ląduje na pendrivie.

- `-p`: nie zgłaszaj błędu, jeśli folder już istnieje.

### 6 · `echo '...' | sudo tee -a /etc/fstab`: montuj przy starcie

`/etc/fstab` to lista dysków, które system montuje sam przy uruchomieniu. Dopisujemy do niej jedną linijkę:

```
LABEL=logs  /mnt/logs  ext4  defaults,noatime,nofail  0  2
```

| Pole | Znaczenie |
|---|---|
| `LABEL=logs` | który dysk: ten z etykietą `logs` z kroku 4 |
| `/mnt/logs` | gdzie go wpiąć: folder z kroku 5 |
| `ext4` | jaki system plików |
| `defaults` | standardowe ustawienia |
| `noatime` | nie zapisuj czasu każdego odczytu pliku, czyli mniej zbędnych zapisów i dłuższe życie pendrive'a |
| `nofail` | **ważne:** jeśli pendrive zniknie, Raspberry i tak się uruchomi, zamiast stanąć w trybie awaryjnym |
| `0` | nie uwzględniaj w starym narzędziu do kopii zapasowych (`dump`) |
| `2` | sprawdzaj dysk przy starcie, po partycji systemowej |

Dlaczego `echo ... | sudo tee -a`, a nie zwykłe `>>`? Plik `/etc/fstab` może zmieniać tylko administrator. `echo` wypisuje tekst, `|` przekazuje go dalej, a `sudo tee -a` dopisuje go do pliku z uprawnieniami administratora (`-a` = dopisz na końcu, nie nadpisuj).

### 7 · `sudo systemctl daemon-reload`: odśwież ustawienia

System trzyma listę dysków z `fstab` w pamięci. Ta komenda każe mu przeczytać ją ponownie, żeby zauważył nową linijkę.

### 8 · `sudo mount -a`: zamontuj teraz

Montuje wszystko z `/etc/fstab`, co nie jest jeszcze zamontowane. Nie trzeba restartować Raspberry. Brak komunikatu = sukces. Jeśli w `fstab` byłby błąd, zobaczysz go tutaj, a nie dopiero przy następnym starcie, więc to dobry test.

### 9 · `df -h /mnt/logs`: sprawdź

Pokazuje zajęte i wolne miejsce. `-h` = w czytelnych jednostkach (GB zamiast bajtów).

```
Filesystem  Size  Used  Avail  Use%  Mounted on
/dev/sda1    57G  2.1M    54G    1%  /mnt/logs
```

Pendrive jest zamontowany w `/mnt/logs` i ma 54 GB wolnego. Brakujące ~3 GB to miejsce zarezerwowane przez ext4 dla administratora i na dane samego systemu plików.

## ❗ Wpadka: komenda rozdzielona przy wklejaniu

Na drugim zrzucie (czerwona ramka) komenda z kroku 6 wkleiła się w **dwóch kawałkach**:

1. `echo '...' | sudo tee -a`: bez nazwy pliku `tee` tylko wypisał tekst na ekran i **niczego nie zapisał**.
2. `/etc/fstab`: powłoka potraktowała to jako polecenie do uruchomienia i odpowiedziała `Permission denied`.

Poprawiona komenda (zielona ramka) zadziałała, a linijka trafiła do pliku tylko raz.

**Lekcja:** długie komendy wklejaj w całości i przed Enterem sprawdź, czy są w jednej linii. Po każdej zmianie w `/etc/fstab` warto zajrzeć do pliku:

```bash
cat /etc/fstab
```

Wpis `LABEL=logs ...` powinien być **dokładnie jeden**. Gdyby był podwójny, usuń zbędny w edytorze: `sudo nano /etc/fstab`.

![Sprawdzenie /etc/fstab](../screenshots/2026-10-09-assembly/25-fstab-check.png)

U mnie jest dobrze: dwie pierwsze linijki z `PARTUUID` to partycje karty SD (dodane przez Imagera), ostatnia to pendrive. Wpis `logs` występuje raz.

## Test po restarcie (opcjonalnie)

```bash
sudo reboot
# po ponownym zalogowaniu:
df -h /mnt/logs
```

Jeśli pendrive znowu jest w `/mnt/logs`, montowanie przy starcie działa.

➡️ Następnie: przekierowanie logów na pendrive (Etap 1 w [ROADMAP](../ROADMAP.md)), potem [03 — Obrońca](03-defender-raspberry.md)
