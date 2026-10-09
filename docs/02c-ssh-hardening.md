# 02c — Zabezpieczenie SSH

SSH to jedyne „drzwi” do Raspberry, więc zabezpieczamy je jako pierwsze. Kolejność ma znaczenie: każdy krok sprawdzamy, zanim zrobimy następny, żeby nie zablokować sobie dostępu.

1. **Logowanie kluczem** zamiast hasła ✅
2. Wyłączenie logowania hasłem
3. Prawdziwy SSH na innym porcie (port 22 zostaje dla honeypota)
4. Firewall

---

## Część 1: logowanie kluczem SSH

### Jak to działa

Klucz SSH to para plików na komputerze, z którego się logujesz:

| Plik | Co to jest | Gdzie trafia |
|---|---|---|
| `id_ed25519` | **klucz prywatny**, jak klucz do drzwi | zostaje **tylko** na PC, nikomu go nie dajesz |
| `id_ed25519.pub` | **klucz publiczny**, jak zamek pasujący do klucza | kopiujesz na Raspberry, może go zobaczyć każdy |

Przy logowaniu Raspberry sprawdza, czy masz klucz prywatny pasujący do zapisanego zamka. Hasło w ogóle nie leci przez sieć, a klucza nie da się zgadnąć tak jak hasła.

### Komendy (na PC, w wierszu poleceń Windows)

```bat
:: 1. wygeneruj parę kluczy
ssh-keygen -t ed25519

:: 2. wyślij klucz publiczny na Raspberry (jedna linijka)
type %USERPROFILE%\.ssh\id_ed25519.pub | ssh grzesiek@honeypi.local "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

:: 3. sprawdź logowanie
ssh grzesiek@honeypi.local
```

![Klucz SSH](../screenshots/2026-10-09-assembly/28-ssh-key.png)

### 1 · `ssh-keygen -t ed25519`: wygeneruj klucz

- `ssh-keygen`: program do tworzenia kluczy, wbudowany w Windows 10/11.
- `-t ed25519`: typ klucza. **Ed25519** jest nowoczesny, krótki i bezpieczny; starsze RSA też działa, ale potrzebuje dużo dłuższego klucza.
- Pyta, gdzie zapisać (Enter = domyślnie `C:\Users\<Ty>\.ssh\id_ed25519`) i o **passphrase**, czyli hasło chroniące sam plik klucza.

**U mnie:** klucz już istniał (`already exists`, `Overwrite (y/n)?`). Nie potwierdziłem nadpisania, więc stary klucz został i to on poszedł na Raspberry. Dobrze, bo nadpisanie unieważniłoby ten klucz wszędzie, gdzie był wcześniej używany (np. na GitHubie).

> ⚠️ Na pytanie `Overwrite (y/n)?` odpowiadaj `y` tylko wtedy, gdy na pewno nigdzie nie używasz starego klucza.

### 2 · `type ... | ssh ... "..."`: wyślij klucz publiczny

Windows nie ma `ssh-copy-id`, więc robimy to ręcznie, w jednej linii:

- `type %USERPROFILE%\.ssh\id_ed25519.pub`: wypisuje zawartość klucza **publicznego** (`.pub`, nigdy prywatnego!).
- `|`: przekazuje ten tekst do następnej komendy.
- `ssh grzesiek@honeypi.local "..."`: loguje się na Raspberry (ostatni raz hasłem) i wykonuje tam komendy w cudzysłowie:
  - `mkdir -p ~/.ssh`: tworzy ukryty folder `.ssh` w katalogu domowym,
  - `chmod 700 ~/.ssh`: tylko Ty możesz do niego wejść,
  - `cat >> ~/.ssh/authorized_keys`: **dopisuje** klucz do listy dozwolonych kluczy (`>>` dopisuje, `>` by nadpisał),
  - `chmod 600 ~/.ssh/authorized_keys`: tylko Ty możesz czytać i zmieniać ten plik.

Uprawnienia są ważne: jeśli `authorized_keys` byłby dostępny dla innych, serwer SSH z ostrożności zignoruje klucz.

### 3 · `ssh grzesiek@honeypi.local`: test

Logowanie przeszło **bez pytania o hasło do Raspberry**, więc klucz działa. Gdyby klucz miał passphrase, pytałoby o nią (o hasło do klucza, nie do Raspberry).

### Passphrase do klucza (opcjonalnie)

Mój klucz nie ma passphrase. Wygodnie, ale jeśli ktoś skopiuje plik `id_ed25519` z mojego PC, zaloguje się bez przeszkód. Hasło do klucza można dodać później, bez generowania nowego:

```bat
ssh-keygen -p -f %USERPROFILE%\.ssh\id_ed25519
```

Uwaga: jeśli ten sam klucz służy np. do GitHuba, tam też zacznie pytać o passphrase.

➡️ Dalej: część 2, wyłączenie logowania hasłem (wkrótce).
