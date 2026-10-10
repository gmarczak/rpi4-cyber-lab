# 07b — Podmisja: z Raspberry skanuję MacBooka

**Status:** ⏳ plan, jeszcze niewykonany. Wyniki, zrzuty i wpadki dopiszę po wykonaniu.
**Gdzie:** MacBook (Wi-Fi) i Raspberry `honeypi` (kabel), ta sama sieć domowa.

To siostra misji [07 — skan własnego PC](07-skan-wlasnego-pc.md). Tam Raspberry skanował Windowsa i znalazł 4 otwarte porty. Teraz to samo z MacBookiem, który też jest w sieci domowej i też coś może wystawiać: udostępnianie plików, ekranu, SSH albo AirPlay.

Pytania są te same:

1. **Na czym MacBook nasłuchuje** (widok od środka)?
2. **Co z tego widać z sieci** (widok z Raspberry, jak u atakującego)?
3. **Co zamknąć**, jeśli coś jest otwarte niepotrzebnie?

> ⚠️ Skanuję **tylko własny komputer we własnej sieci** (art. 267 kk).

---

## Komendy w skrócie

```bash
# --- na MacBooku, w Terminalu ---
# 1. adres MacBooka w sieci domowej (Wi-Fi to zwykle en0)
ipconfig getifaddr en0

# 2. na jakich portach MacBook nasłuchuje
sudo lsof -iTCP -sTCP:LISTEN -n -P

# 3. czy firewall macOS jest włączony
/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# 4. czy włączony jest „tryb niewidzialny” (brak odpowiedzi na ping i skany)
/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode
```

```bash
# --- na Raspberry (z MacBooka: ssh honeypi) ---
# 5. co widać na MacBooku z sieci domowej
nmap -Pn ADRES_MACA

# 6. po zmianach: skan kontrolny
nmap -Pn ADRES_MACA
```

`ADRES_MACA` to wynik komendy 1. W repo go nie podaję, tak jak adresów innych urządzeń w sieci domowej.

Kroki między 4 a 6 to klikanie w **Ustawieniach systemowych**, opisane niżej.

---

## Plan

### Część 1: widok od środka (komendy 1–4)

- **1.** Adres MacBooka. MacBook jest na Wi-Fi, więc ma inny adres niż PC. Jeśli w Ustawieniach Wi-Fi włączony jest **prywatny adres Wi-Fi**, MacBook co jakiś czas zmienia MAC, a router może dać mu wtedy nowy adres IP. To normalne.
- **2.** `lsof` pokazuje programy, które czekają na połączenia: nazwę programu, numer procesu i port. `-iTCP -sTCP:LISTEN` = tylko nasłuchujące porty TCP, `-n -P` = bez zamiany adresów i portów na nazwy (szybciej i czytelniej).
- **3–4.** Firewall macOS jest **domyślnie wyłączony**. Tryb niewidzialny (*stealth mode*) sprawia, że MacBook nie odpowiada na ping ani na próby połączenia z zamkniętymi portami, podobnie jak Windows po hardeningu (`filtered` w `nmap`).

Na co się nastawiam (do sprawdzenia, nie wiem tego z góry):

| Port | Co to zwykle jest na Macu | Gdzie się to wyłącza |
|---|---|---|
| 22 | Zdalne logowanie (SSH) | Ustawienia → Ogólne → Udostępnianie → Zdalne logowanie |
| 445 | Udostępnianie plików (SMB) | … → Udostępnianie → Udostępnianie plików |
| 5900 | Udostępnianie ekranu | … → Udostępnianie → Udostępnianie ekranu / Zarządzanie zdalne |
| 5000, 7000 | Odbiornik AirPlay | Ustawienia → Ogólne → AirDrop i Handoff → Odbiornik AirPlay |
| 3283 | Zarządzanie zdalne (Apple Remote Desktop) | … → Udostępnianie → Zarządzanie zdalne |

### Część 2: widok z Raspberry (komenda 5)

Ten sam skan co przy PC. Porównam go z wynikiem komendy 2: nie wszystko, na czym MacBook nasłuchuje, musi być widać z sieci. To sprawdzian, czy firewall coś faktycznie blokuje.

### Część 3: zamknięcie i skan kontrolny (komenda 6)

- wyłączyć w **Udostępnianiu** wszystko, czego nie używam,
- włączyć **firewall** (Ustawienia → Sieć → Zapora) i **tryb niewidzialny** (w opcjach zapory),
- skan kontrolny z Raspberry: cel to brak otwartych portów, tak jak na PC.

### Pytania do rozstrzygnięcia przy wykonaniu

- Czy używam AirPlay na MacBooku (np. wysyłanie obrazu z telefonu)? Jeśli tak, port AirPlay może zostać.
- Czy łączę się z MacBookiem zdalnie (SSH, udostępnianie ekranu)? Jeśli nie, wszystko w Udostępnianiu wyłączam.
- Wersja macOS: nazwy w Ustawieniach różnią się między wersjami.

---

➡️ Wróć do [ROADMAP](../ROADMAP.md) albo do misji-siostry [07 — skan własnego PC](07-skan-wlasnego-pc.md).
