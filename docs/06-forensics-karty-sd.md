# 06 — Forensics na starych kartach microSD

Czas: ~2 godziny (większość to czekanie na kopiowanie i kasowanie). Wszystko na **MacBooku**, Raspberry nie jest potrzebne.

> 🚧 **Status: komendy gotowe, wyniki do uzupełnienia.** Sekcje „Wyniki” i „Wpadki” wypełniam dopiero po przejściu ćwiczenia na prawdziwych kartach, razem ze zrzutami. Nic tu nie jest wymyślone na zapas.

Mam dwie stare karty microSD po 16 GB: **SanDisk (klasa 10)** i kartę **bez marki (klasa 4)**. Nie nadają się na system dla obrońcy (do tego jest SanDisk Extreme 64 GB), ale świetnie nadają się do nauki **informatyki śledczej** (*forensics*): jak wygląda dysk „od środka”, co naprawdę znaczy „usunąłem plik” i czy da się go odzyskać.

Co po drodze zrobimy:

1. zrobimy **obraz karty**, czyli bit-w-bit kopię, i udowodnimy sumą kontrolną, że jest wierna,
2. odzyskamy z obrazu usunięte pliki dwiema metodami (**TestDisk** i **PhotoRec**) i zobaczymy, czym się różnią,
3. zrobimy **kontrolowany eksperyment** na plikach, które sami zapiszemy i usuniemy, żeby wiedzieć, ile powinno wrócić,
4. **bezpiecznie skasujemy** kartę i udowodnimy, że po kasowaniu nic już nie wraca,
5. sprawdzimy kartę bez marki testem autentyczności (**f3**), bo takie karty często kłamią co do pojemności.

## ⚠️ Zasady przed startem

- **Tylko własne karty.** Odzyskiwanie danych z cudzego nośnika bez zgody to ten sam rodzaj problemu co skanowanie cudzej sieci (art. 267 kk).
- **Repo jest publiczne, a stare karty mogą zawierać prywatne rzeczy** (zdjęcia, dokumenty, też Twoje albo kogoś z rodziny). Zasady:
  - obrazy kart (`*.img`) i odzyskane pliki trzymamy **poza repo**, w `~/forensics`,
  - na zrzutach nie pokazujemy **zawartości** odzyskanych plików ani ich nazw, tylko liczby i typy,
  - zrzuty przycinamy do okna terminala, jak w całym repo.
- **Większość komend poniżej kasuje albo czyta cały dysk.** Pomyłka w numerze dysku (`diskN`) oznacza utratę danych na MacBooku. Przed każdą komendą z `sudo` sprawdź numer dysku według kroku 1–2.
- Pracujemy na **obrazie**, nie na samej karcie, wszędzie tam, gdzie to możliwe. Obraz można psuć i powtarzać do woli, a karta zostaje taka, jaka była.

## Przygotowanie

```bash
brew install testdisk f3      # testdisk = TestDisk + PhotoRec, f3 = test pojemności
mkdir -p ~/forensics/obrazy ~/forensics/odzysk
```

Wszystko ląduje w `~/forensics`, **nie** w folderze repo.

`brew` to **Homebrew**, menedżer programów dla macOS. Jeśli Terminal odpowie `zsh: command not found: brew`, nie jest jeszcze zainstalowany (patrz wpadka poniżej).

## ❗ Wpadka: `command not found: brew`

| | |
|---|---|
| **Co było widać** | `zsh: command not found: brew` po wpisaniu `brew install testdisk f3` |
| **Przyczyna** | Homebrew nie jest domyślnie w macOS. Trzeba go zainstalować jednorazowo |
| **Rozwiązanie** | instalator ze strony [brew.sh](https://brew.sh): `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`. Zapyta o hasło do Maca i może doinstalować narzędzia programistyczne Apple. Na końcu wypisze „Next steps”, czyli dwie linijki do wklejenia, które dodają `brew` do ścieżki. Bez nich `brew` dalej nie będzie znaleziony |
| **Lekcja** | komenda „nie znaleziona” zwykle znaczy „nie zainstalowana albo nie w `PATH`”, a nie „zepsuta”. Po instalacji otwórz nowe okno Terminala i sprawdź `brew --version` |

**Blokada zapisu.** Pełnowymiarowy adapter SD ma z boku mały suwak **LOCK**. Przesuń go w stronę oznaczenia LOCK, zanim włożysz kartę do MacBooka. To prosty, sprzętowy *write blocker*: system widzi kartę jako tylko do odczytu, więc nie może jej przypadkiem zmienić. Bez blokady macOS po włożeniu karty sam ją montuje i może dopisać ukryte pliki (`.Spotlight-V100`, `.fseventsd`), czyli zmienić „dowód”. Gdy adapter nie ma suwaka, od razu po włożeniu zrób krok 3 (`unmountDisk`).

![Karta SanDisk microSD 16 GB klasy 10 i jej adapter SD, z zaznaczonym suwakiem LOCK](../screenshots/2026-10-09-forensics/01-karta-sandisk-16gb.jpg)

Na zdjęciu suwak jest na lewej krawędzi adaptera (żółte kółko). To, czy blokada naprawdę działa, sprawdzisz w kroku 2: `diskutil info` pokaże `Read-Only Media: Yes`.

Obie karty wkładamy **po kolei**, nie jednocześnie. Dzięki temu numer dysku jest oczywisty.

---

# Część 1: obraz karty

## Komendy w skrócie

```bash
diskutil list                                                        # 1
diskutil info /dev/diskN                                             # 2
diskutil unmountDisk /dev/diskN                                      # 3
sudo dd if=/dev/rdiskN of=$HOME/forensics/obrazy/sandisk16.img bs=4m # 4
ls -l $HOME/forensics/obrazy/sandisk16.img                           # 4a  (rozmiar = Disk Size z kroku 2?)
shasum -a 256 $HOME/forensics/obrazy/sandisk16.img                   # 5
sudo shasum -a 256 /dev/rdiskN                                       # 6
```

`N` to numer dysku z kroku 1, np. `disk4`. **Nie wklejaj komend z literą `N`**, wstaw prawdziwy numer.

## Co robi każda komenda

### 1 · `diskutil list`: znajdź kartę

Pokazuje wszystkie dyski. Kartę rozpoznasz po **rozmiarze** (ok. 15,9 GB lub 16,0 GB) i po nazwie woluminu, jeśli ma ją nadaną. Dysk MacBooka ma setki GB (u mnie `disk0` 500 GB i `disk3` z woluminami APFS), więc się nie pomylisz. Uwaga: przy **wbudowanym** czytniku SD karta też jest opisana jako `internal, physical`, tak jak dysk systemowy, więc słowo `internal` niczego nie rozstrzyga. Liczy się rozmiar. Zapisz sobie nazwę dysku karty, np. `/dev/disk4`. Partycje (`disk4s1`) to część tego dysku, my pracujemy na **całym dysku** `disk4`.

Wersja `diskutil list external physical` jest krótsza, ale u mnie **nic nie wypisała** (patrz wpadka niżej), więc używamy pełnej listy.

Jeśli widzisz kilka dysków i nie jesteś pewien, **wyjmij kartę i uruchom komendę jeszcze raz**. Ten, który zniknął, to karta.

### 2 · `diskutil info /dev/diskN`: potwierdź

W wyniku sprawdź trzy pola:

| Pole | Czego oczekujesz |
|---|---|
| `Device Location` | `Internal` (wbudowany czytnik) albo `External` (czytnik USB) |
| `Disk Size` | ok. 16 GB |
| `Protocol` | `Secure Digital` (przez czytnik USB zobaczysz `USB`) |

Jeśli którekolwiek się nie zgadza, **stop**. Zobacz też `Read-Only Media`: przy włączonym suwaku LOCK powinno być `Yes`.

### 3 · `diskutil unmountDisk /dev/diskN`: odmontuj, ale nie wyjmuj

Odłącza system plików karty od Findera, a samo urządzenie zostaje dostępne. To ważne: do kopiowania cały dysk musi być **odmontowany**, inaczej system może w trakcie coś na nim zmieniać.

### 4 · `sudo dd if=/dev/rdiskN of=... bs=4m`: kopia bit-w-bit

- `dd`: kopiuje dane bajt po bajcie, bez „rozumienia”, co jest w środku.
- `if=` (*input file*): skąd czytamy, czyli **karta**.
- `of=` (*output file*): dokąd zapisujemy, czyli **plik obrazu**.
- `/dev/rdiskN`: surowa (*raw*) wersja urządzenia. Z literą `r` kopiowanie jest dużo szybsze niż z `/dev/diskN`, bo omija bufor systemu.
- `bs=4m`: kopiuj porcjami po 4 MB. Na macOS piszemy **małe `m`** (na Linuksie byłoby `4M`).

> ⚠️ **Nie zamieniaj `if` z `of`.** Odwrócona komenda zapisuje plik na kartę, a nie kartę do pliku.

`dd` nic nie pokazuje, dopóki nie skończy. Żeby sprawdzić postęp, naciśnij w oknie terminala **Ctrl+T**: macOS wypisze, ile bajtów już przekopiował. Parametr `status=progress` z Linuksa na macOS nie działa. 16 GB kopiuje się od kilku do kilkunastu minut, na karcie klasy 4 dłużej.

Na końcu `dd` wypisuje liczbę skopiowanych bajtów. Powinna być równa rozmiarowi karty. **Sprawdź to** (krok 4a niżej), bo `dd` potrafi skończyć z błędem i zostawić plik za krótki.

### 4a · `ls -l plik.img`: czy obraz ma pełny rozmiar

`ls -l` pokazuje rozmiar pliku w bajtach (piąta kolumna). Musi być **identyczny** z `Disk Size` z kroku 2 (u mnie 16021192704). Jeśli jest mniejszy, `dd` nie doczytał końca karty, patrz wpadka niżej. Dokończenie ogona małym blokiem:

```bash
sudo dd if=/dev/rdiskN of=$HOME/forensics/obrazy/sandisk16.img bs=512 skip=LICZBA seek=LICZBA conv=notrunc
```

`LICZBA` to rozmiar dotychczasowego pliku podzielony przez 512 (liczba sektorów, które już mamy). `skip` pomija tyle sektorów na wejściu, `seek` zaczyna zapis w pliku od tego samego miejsca, a `conv=notrunc` oznacza „nie obcinaj pliku, tylko dopisz”.

### 5 · `shasum -a 256 plik.img`: odcisk obrazu

`shasum -a 256` liczy **sumę kontrolną SHA-256**: ciąg 64 znaków, który jest „odciskiem palca” danych. Zmiana jednego bita w pliku daje zupełnie inny odcisk. Zapisz go.

### 6 · `sudo shasum -a 256 /dev/rdiskN`: odcisk samej karty

To samo, ale z całej karty. **Oba odciski muszą być identyczne.** To dowód, że obraz jest wierną kopią i że żaden bajt się nie zmienił po drodze. W prawdziwym śledztwie bez takiego dowodu kopia nie ma wartości. Ta komenda czyta całą kartę jeszcze raz, więc potrwa tyle co kopiowanie.

Po wszystkim: `diskutil eject /dev/diskN` i wyjmij kartę.

## ❗ Wpadka: `diskutil list external physical` nic nie pokazało

| | |
|---|---|
| **Co było widać** | pusty wynik (dwa razy), mimo że w Finderze karta była widoczna z plikami `.mp3` |
| **Przyczyna** | karta we **wbudowanym czytniku SD** MacBooka jest dla macOS dyskiem `internal, physical`, tak samo jak dysk systemowy. Filtr `external` ją więc odrzucił. Przez czytnik USB byłaby `external` |
| **Rozwiązanie** | pełne `diskutil list` i rozpoznanie karty po rozmiarze |
| **Lekcja** | filtr w komendzie to założenie. Gdy wynik jest pusty, usuń filtr i zobacz całość, zanim uznasz, że karta „nie działa”. Przy wbudowanym czytniku słowo `internal` nie odróżnia karty od dysku MacBooka, odróżnia ją **rozmiar** |

## Wyniki

## ❗ Wpadka: `dd` przerwał na ostatnim bloku (`Operation timed out`)

| | |
|---|---|
| **Co było widać** | `dd: /dev/rdisk4: Operation timed out`, a potem `16018046976 bytes transferred` zamiast 16021192704. Obraz był krótszy o **3 145 728 bajtów (3 MiB)** |
| **Przyczyna** | karta ma 3819,75 bloków po 4 MiB. `dd` przeczytał 3819 pełnych, a na ostatnim, niepełnym czytnik wbudowanego slotu się zawiesił. Odczyt małym blokiem w tym samym miejscu **przeszedł bez błędu**, więc to nie uszkodzone sektory, tylko odczyt „przez koniec urządzenia” dużym blokiem |
| **Rozwiązanie** | doczytanie samego ogona: `sudo dd if=/dev/rdisk4 of=...sandisk16.img bs=512 skip=31285248 seek=31285248 conv=notrunc` (6144 sektory, 3 MiB, 5,5 s). Potem `ls -l` pokazał dokładnie **16021192704** bajtów |
| **Lekcja** | zakończenie komendy bez błędu w terminalu to nie dowód. Zawsze porównaj rozmiar obrazu z rozmiarem karty (krok 4a) i dopiero potem licz sumy kontrolne. Tym razem rozmiar karty dzieli się dokładnie przez 3 MiB (5093 bloki), więc przy `bs=3m` ostatni blok byłby pełny |

## Wyniki

Karta SanDisk: `/dev/disk4`, 16,0 GB (16 021 192 704 bajtów = 31 291 392 sektorów po 512 B), tablica partycji MBR (`FDisk_partition_scheme`), jedna partycja FAT32 `NO NAME` (`disk4s1`, 16,0 GB). Na karcie są pliki `.mp3`. Blokada zapisu działała: `Media Read-Only: Yes`.

Kopiowanie `dd bs=4m`: 3819 bloków w 2273 s (ok. 38 minut), średnio 7,0 MB/s (na początku ok. 10,7 MB/s, potem wolniej). Ogon 3 MiB doczytany osobno (patrz wpadka). Rozmiar końcowego obrazu: 16 021 192 704 bajtów, zgodny z kartą.

*(do uzupełnienia: obie sumy SHA-256 i informacja, czy się zgadzają)*

---

# Część 2: co jest na karcie? Dwie metody odzysku

Karta mogła być wcześniej w telefonie, aparacie albo czytniku. „Usunięcie” pliku zwykle **nie kasuje danych**: system tylko zapisuje, że to miejsce jest znów wolne. Dopóki nic go nie nadpisze, plik leży na karcie nietknięty. Dwa narzędzia podchodzą do tego na dwa różne sposoby.

| | **TestDisk** (*undelete*) | **PhotoRec** (*carving*) |
|---|---|---|
| Jak działa | czyta spis plików systemu (FAT, NTFS, ext…) i znajduje wpisy oznaczone jako usunięte | ignoruje spis, przeszukuje surowe dane i rozpoznaje pliki po „sygnaturze” na początku (np. JPEG zaczyna się od `FF D8 FF`) |
| Nazwy plików i foldery | **zachowuje** | **gubi**, pliki dostają numery typu `f123456.jpg` |
| Pliki bez znanej sygnatury | odzyska, jeśli wpis w spisie jeszcze jest | **nie rozpozna** |
| Gdy spis plików jest uszkodzony lub karta sformatowana | zwykle bezradny | nadal działa |

## Komendy w skrócie

```bash
testdisk $HOME/forensics/obrazy/sandisk16.img                                       # 7
photorec /log /d $HOME/forensics/odzysk/sandisk16/ $HOME/forensics/obrazy/sandisk16.img   # 8
find $HOME/forensics/odzysk/sandisk16 -path '*/recup_dir.*' -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn   # 9
```

Obie komendy działają na **obrazie**, więc nie potrzebują `sudo` i nie mogą uszkodzić karty.

## Co robi każda komenda

### 7 · `testdisk obraz.img`: usunięte pliki ze spisu

TestDisk ma menu tekstowe, obsługiwane strzałkami i Enterem:

1. `[ Proceed ]`: wybierz obraz.
2. Typ tablicy partycji: zwykle podpowiada sam (`Intel/PC` dla kart z MBR). Zatwierdź Enterem.
3. `[ Advanced ]`: wybierz partycję, potem `[ Undelete ]`.
4. Lista plików: **na czerwono** są usunięte. Podpowiedź klawiszy jest na dole ekranu (zaznaczanie, kopiowanie do wybranego folderu). Kopiuj do `~/forensics/odzysk/sandisk16-testdisk/`.

Jeśli TestDisk nie widzi żadnej partycji albo spis jest pusty, to też wynik: karta mogła być sformatowana, a wtedy zostaje PhotoRec.

### 8 · `photorec /log /d folder/ obraz.img`: wyciąganie po sygnaturach

- `/log`: zapisz przebieg do pliku `photorec.log` (przyda się do wniosków).
- `/d folder/`: gdzie zapisać odzyskane pliki. PhotoRec tworzy w nim podfoldery `recup_dir.1`, `recup_dir.2`…
- Ostatni argument to obraz.

Dalej menu tekstowe:

1. `[ Proceed ]`, potem wybór partycji (albo całego dysku).
2. `[ File Opt ]` (opcjonalnie): ogranicz typy plików, np. tylko `jpg`, `png`, `pdf`. Domyślnie szuka wszystkiego.
3. `[ Search ]`, potem typ systemu plików: **`Other`** dla FAT/exFAT/NTFS (karty z telefonów i aparatów), `ext2/ext3` dla Linuksa.
4. **`Free`** albo **`Whole`**: `Free` szuka tylko w miejscu oznaczonym jako wolne, czyli wśród usuniętych plików. `Whole` przeszukuje wszystko, także pliki, które nadal są na karcie. Na pierwszy raz wybierz `Free`.
5. Wskaż folder docelowy i potwierdź klawiszem `C`.

Zapisz wynik wyświetlany na końcu: ile plików odzyskano.

### 9 · liczenie wyników bez oglądania zawartości

```bash
find folder -path '*/recup_dir.*' -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn
```

`find` wypisuje wszystkie odzyskane pliki (tylko te z folderów `recup_dir.*`, bez `photorec.log`), `sed` zostawia z każdej nazwy samo rozszerzenie, a `sort | uniq -c | sort -rn` liczy je i układa od najliczniejszego. Wynik wygląda np. tak: `142 jpg`, `9 mp4`. Dzięki temu do dokumentacji trafiają **liczby i typy**, a nie same pliki. Jeśli na karcie są cudze lub prywatne zdjęcia, nie ma potrzeby ich oglądać, żeby ćwiczenie miało sens.

## Wyniki

*(do uzupełnienia: czy karta była sformatowana, ile plików znalazł TestDisk, ile PhotoRec, jakie typy; które metody zadziałały na której karcie)*

---

# Część 3: kontrolowany eksperyment

Na cudzych danych nie wiemy, ile **powinno** wrócić. Dlatego robimy własny test: zapisujemy znane pliki, usuwamy je i sprawdzamy, ile odzyskamy. Ta część **kasuje kartę**, więc robimy ją dopiero po częściach 1–2 (obraz oryginału już leży w `~/forensics/obrazy`).

Używamy karty **SanDisk 16 GB**. Suwak LOCK ustaw teraz w pozycji odblokowanej.

## Komendy w skrócie

```bash
diskutil eraseDisk FAT32 TEST MBRFormat /dev/diskN                         # 10
cp ~/Pictures/zdjecie1.jpg ~/Pictures/zdjecie2.jpg ~/Documents/plik.pdf /Volumes/TEST/   # 11
head -c 2m /dev/urandom > /Volumes/TEST/losowy.bin                         # 12
shasum -a 256 /Volumes/TEST/* | tee $HOME/forensics/oryginaly.sha256       # 13
rm /Volumes/TEST/*                                                         # 14
diskutil unmountDisk /dev/diskN                                            # 15
sudo dd if=/dev/rdiskN of=$HOME/forensics/obrazy/sandisk16-po-usunieciu.img bs=4m   # 16
```

Potem powtórz kroki 7–9 na nowym obrazie, a na końcu porównaj odciski (krok 17).

## Co robi każda komenda

### 10 · `diskutil eraseDisk FAT32 TEST MBRFormat /dev/diskN`: czysta karta

Formatuje kartę jako **FAT32** (system plików typowy dla kart w aparatach) z tablicą partycji MBR i nazwą `TEST`. **Kasuje wszystko**, dlatego numer dysku sprawdź jeszcze raz (kroki 1–2).

### 11–12 · pliki testowe

- Skopiuj **dwa zdjęcia i jeden PDF**, które nie są prywatne (np. z internetu albo zrzut ekranu). Te typy PhotoRec zna po sygnaturach. Na karcie FAT32 macOS może dopisać własne pliki `._*` i ukryte foldery systemowe. To normalne ślady systemu, nie błąd.
- `head -c 2m /dev/urandom > ...` tworzy plik z **2 MB losowych bajtów**. Losowe dane nie mają żadnej sygnatury, więc PhotoRec go nie rozpozna. To celowy „test kontrolny”.

### 13 · `shasum -a 256 ... | tee plik`: odciski oryginałów

Liczy SHA-256 każdego pliku testowego i zapisuje listę do `oryginaly.sha256`. Po odzyskaniu porównamy te odciski z odciskami plików, które wrócą. `tee` wypisuje wynik na ekran i jednocześnie zapisuje do pliku.

### 14 · `rm /Volumes/TEST/*`: usunięcie

Usuwamy w terminalu, nie w Finderze. Finder tylko przenosi pliki do ukrytego folderu `.Trashes`, czyli nie jest to prawdziwe usunięcie. `rm` kasuje wpisy ze spisu plików, ale **nie rusza samych danych**. Dokładnie tak „usuwa” telefon czy aparat.

### 15–16 · odmontuj i zrób obraz

Jak w części 1 (kroki 3–4), tylko z nową nazwą obrazu.

### 17 · porównanie odcisków

Po odzysku z obrazu `sandisk16-po-usunieciu.img` (kroki 7–9, foldery `.../po-usunieciu-testdisk` i `.../po-usunieciu-photorec`):

```bash
awk '{print $1}' $HOME/forensics/oryginaly.sha256 | sort > $HOME/forensics/odciski-oryginalow.txt
find $HOME/forensics/odzysk/po-usunieciu-photorec -path '*/recup_dir.*' -type f -exec shasum -a 256 {} + | awk '{print $1}' | sort > $HOME/forensics/odciski-odzyskanych.txt
comm -12 $HOME/forensics/odciski-oryginalow.txt $HOME/forensics/odciski-odzyskanych.txt | wc -l
```

- Pierwsza komenda wyciąga z listy z kroku 13 same odciski (pierwsza kolumna) i sortuje je.
- Druga liczy odciski wszystkich odzyskanych plików. Nazwy PhotoRec zmienia, więc porównujemy odciski, nie nazwy.
- `comm -12` pokazuje odciski występujące w **obu** listach, a `wc -l` je liczy. Każda wspólna linijka to plik odzyskany **identycznie** co do bajta.

To samo zrób dla wyniku TestDisk (folder `po-usunieciu-testdisk`, bez filtra `recup_dir.*`, bo TestDisk zachowuje nazwy i foldery).

**Czego się spodziewam (do potwierdzenia na karcie):** TestDisk odzyska wszystkie cztery pliki razem z nazwami, bo spis plików jeszcze pamięta wpisy. PhotoRec odzyska zdjęcia i PDF bez nazw, ale `losowy.bin` nie odzyska wcale, bo nie ma sygnatury. Pliki, które PhotoRec uzna za uszkodzone, mogą mieć inny odcisk, jeśli były pofragmentowane.

## Wyniki

*(do uzupełnienia: tabela „plik → TestDisk → PhotoRec”, ile odcisków się zgodziło)*

---

# Część 4: bezpieczne kasowanie i dowód

Skoro wiemy, że „usunięcie” i nawet szybkie formatowanie niczego nie niszczą, sprawdzamy, co faktycznie zabezpiecza dane: **nadpisanie całej karty**.

## Komendy w skrócie

```bash
diskutil unmountDisk /dev/diskN                                            # 18
sudo dd if=/dev/zero of=/dev/rdiskN bs=4m                                  # 19
sudo dd if=/dev/rdiskN of=$HOME/forensics/obrazy/sandisk16-po-zerach.img bs=4m   # 20
hexdump -C $HOME/forensics/obrazy/sandisk16-po-zerach.img | head -5        # 21
cmp $HOME/forensics/obrazy/sandisk16-po-zerach.img /dev/zero               # 22
photorec /log /d $HOME/forensics/odzysk/po-zerach/ $HOME/forensics/obrazy/sandisk16-po-zerach.img   # 23
```

## Co robi każda komenda

### 18–19 · `dd if=/dev/zero of=/dev/rdiskN`: wypełnij zerami

`/dev/zero` to „źródło” nieskończonej liczby bajtów zerowych. Tym razem kierunek jest odwrotny niż w części 1: **czytamy** zera, **zapisujemy** na kartę. Jedna pełna runda nadpisuje każdy sektor, więc dawnych danych nie ma już skąd odczytać.

> ⚠️ **To jedyna komenda w tym rozdziale, która zapisuje na dysk bez pytania.** Błędny numer `diskN` skasuje inny dysk. Przed Enterem sprawdź ostatni raz: `diskutil info /dev/diskN` (karta, 16 GB, `Secure Digital`).

Czas: karta klasy 10 ok. 15–30 minut, karta klasy 4 nawet godzinę lub dłużej. Ctrl+T pokazuje postęp. Na końcu `dd` może zgłosić `end of device` albo `No space left on device`: to **normalne**, bo kończy się miejsce na karcie, czyli cała została nadpisana.

Alternatywa: `diskutil secureErase 0 /dev/diskN` (poziom 0 = jedno przejście zerami). Na nośnikach flash bywa niedostępna, dlatego tu używamy `dd`.

### 20 · obraz po kasowaniu

Jak wcześniej: robimy nowy obraz karty.

### 21 · `hexdump -C ... | head -5`: zobacz na własne oczy

Pokazuje początek obrazu w zapisie szesnastkowym. Po wyzerowaniu powinny być same `00`, a powtarzające się linijki `hexdump` zastępuje gwiazdką `*`.

### 22 · `cmp obraz /dev/zero`: dowód matematyczny

Porównuje obraz bajt po bajcie z nieskończonym strumieniem zer. Komunikat o **końcu pliku** (`EOF on ...`) znaczy, że cały obraz do ostatniego bajta jest zerami. Komunikat `differ` znaczy, że gdzieś jest coś innego niż zero.

### 23 · PhotoRec na wyzerowanym obrazie

Ten sam test co w części 2. Oczekiwany wynik: **0 odzyskanych plików**. To jest „po” do zestawienia z „przed”.

## ⚠️ Uczciwe zastrzeżenie: pamięć flash to nie dysk

Karta microSD ma kontroler, który rozkłada zapisy po komórkach (*wear leveling*) i trzyma rezerwowe bloki. Nadpisanie „całej karty” nadpisuje wszystko, co **widzi system**, ale nie gwarantuje, że wyczyszczone zostały też ukryte rezerwy. Do ćwiczeń i zwykłego pozbycia się karty to wystarczy. Przy naprawdę wrażliwych danych jedyne pewne metody to szyfrowanie **od początku** (wtedy po kasowaniu zostaje bezużyteczny szyfrogram) albo fizyczne zniszczenie karty.

## Wyniki

*(do uzupełnienia: czas kasowania, wynik `hexdump` i `cmp`, wynik PhotoRec po zerach)*

---

# Część 5: test autentyczności karty bez marki (f3)

Tanie, nieoznaczone karty często mają napisane 16 GB, a naprawdę mają np. 2 GB. Kontroler „przyjmuje” zapisy ponad prawdziwą pojemność i je gubi. Test **F3** zapisuje na kartę znane dane aż do końca, a potem odczytuje i sprawdza, czy wszystko wróciło.

Na macOS działają tylko `f3write` i `f3read`. Szybszy `f3probe` jest wyłącznie na Linuksa, więc robimy dłuższą, ale równie wiarygodną metodę.

## Komendy w skrócie

```bash
diskutil eraseDisk FAT32 TEST MBRFormat /dev/diskN   # 24
f3write /Volumes/TEST                                # 25
f3read /Volumes/TEST                                 # 26
```

## Co robi każda komenda

### 24 · format

Jak w kroku 10. Kasuje kartę, więc rób to po wykonaniu części 1–2 i na karcie **bez marki** (wymień `diskN`).

### 25 · `f3write /Volumes/TEST`: zapisz dane testowe

Wypełnia wolne miejsce plikami po 1 GB o znanej zawartości. Dla 16 GB to kilkanaście plików, a zapis na karcie klasy 4 trwa długo.

### 26 · `f3read /Volumes/TEST`: sprawdź

Czyta pliki i porównuje z tym, co zapisano. Na końcu wypisuje podsumowanie:

| Pole | Dobra karta | Fałszywa pojemność |
|---|---|---|
| `Data OK` | prawie cała pojemność | tylko prawdziwa pojemność |
| `Data LOST` | `0.00 Byte` | duża liczba |
| `Corrupted`, `Slightly changed` | `0` | `0` lub niewiele |

Dużo `Data LOST` oznacza, że karta kłamie. Wtedy jej realna pojemność to wartość `Data OK`.

Po teście karta jest pełna plików F3. Możesz je skasować komendą z kroku 10.

## Wyniki

*(do uzupełnienia: wynik f3read dla karty bez marki; opcjonalnie też dla SanDisk jako punkt odniesienia)*

---

## Co z tego mamy

- Dowód, że **usunięcie pliku i szybkie formatowanie nie niszczą danych**, a nadpisanie całej karty tak.
- Umiejętność zrobienia i zweryfikowanego **obrazu dysku**, czyli podstawę każdej analizy śledczej.
- Różnicę między odzyskiwaniem **ze spisu plików** (TestDisk) i **po sygnaturach** (PhotoRec).
- Praktyczną wiedzę do labu: gdy wycofujesz kartę z Raspberry albo sprzedajesz stary telefon, wiesz, jak ją **naprawdę** wyczyścić.

## Słowniczek

| Pojęcie | Znaczenie |
|---|---|
| Forensics | informatyka śledcza: zabezpieczanie i analiza danych tak, żeby dało się obronić wynik |
| Obraz dysku | plik będący dokładną kopią bit-w-bit całego nośnika |
| Suma kontrolna (SHA-256) | „odcisk palca” danych, służy do dowodu, że kopia jest wierna |
| Write blocker | sprzęt lub ustawienie, które pozwala tylko czytać nośnik, żeby go nie zmienić |
| Carving | wycinanie plików z surowych danych po sygnaturach, bez korzystania ze spisu plików |
| Sygnatura (*magic bytes*) | charakterystyczne bajty na początku pliku, np. JPEG zaczyna się od `FF D8 FF` |
| Wear leveling | rozkładanie zapisów po komórkach flash przez kontroler, żeby się równo zużywały |

➡️ Następnie: wróć do [Etapu 3: Kali i cele ataku](04-attacker-kali.md)
