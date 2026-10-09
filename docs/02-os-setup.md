# 02 — Instalacja systemu i pierwszy start

Czas: ~30 min. Czytnik/wejście SD potrzebny tylko tutaj — potem wszystko przez SSH.

## 1. Złożenie Raspberry

1. Naklej radiatory na procesor i kości pamięci.
2. Włóż płytkę do obudowy.

## 2. Nagranie systemu na kartę

1. Pobierz **Raspberry Pi Imager**: <https://www.raspberrypi.com/software/>
2. Wybierz: *Raspberry Pi 4* → *Raspberry Pi OS Lite (64-bit)* → swoja karta.
3. Kliknij **Edytuj ustawienia** (ikona koła zębatego) i ustaw:
   - nazwa hosta: `honeypi`
   - nazwa użytkownika i hasło — **zapisz je!**
   - strefa czasowa: `Europe/Warsaw`
   - zakładka *Usługi* → włącz **SSH** (logowanie hasłem)
4. Zapisz na kartę.

> 💡 Wersja **Lite** jest bez pulpitu — lżejsza, idealna do serwera działającego przez SSH.

## 3. Pierwsze uruchomienie

1. Włóż kartę do Raspberry.
2. Podłącz kabel LAN do routera.
3. Na końcu podłącz zasilanie. Poczekaj ~2 min.

## 4. Stały adres IP

W panelu routera znajdź urządzenie `honeypi`, zanotuj jego adres (np. `192.168.1.50`) i ustaw dla niego **rezerwację DHCP** (stały adres). Bez tego adres może się zmienić.

## 5. Połączenie przez SSH

Na komputerze (Terminal na macOS/Linux, PowerShell na Windows):

```bash
# honeypi = nazwa hosta, NIE login — podaj swojego użytkownika
ssh TWOJ_UZYTKOWNIK@honeypi.local
# albo po adresie IP:
ssh TWOJ_UZYTKOWNIK@192.168.1.50
```

Przy pierwszym połączeniu potwierdź `yes` i podaj hasło.

## 6. Aktualizacja

```bash
sudo apt update && sudo apt full-upgrade -y
```

Po tym kroku karta i wejście SD nie są już potrzebne — dalej pracujesz zdalnie.

➡️ Następnie: [02b — Pendrive na logi](02b-usb-log-drive.md)
