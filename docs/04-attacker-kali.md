# 04 — Atakujący: Kali i cele na komputerze

Kali i cele ataku stoją w maszynach wirtualnych na komputerze. Wszystko odseparowane od reszty systemu; maszyny można w każdej chwili skasować i postawić od nowa.

> 🛠️ Jak to wyglądało u mnie krok po kroku, ze zrzutami i wpadkami: [04c — Instalacja Kali i maszyny z celami](04c-instalacja-kali-i-celow.md). Docker, DVWA i Juice Shop na `cele`: [04d](04d-docker-dvwa-juice-shop.md). Zabezpieczenie Kali i stabilność labu: [04e](04e-zabezpieczenie-kali-i-stabilnosc.md). Cały etap w jednym pliku: 📋 [podsumowanie Etapu 3](etap-3-podsumowanie.md).

## 4a. VirtualBox + sieć

1. Pobierz i zainstaluj [VirtualBox](https://www.virtualbox.org/) (darmowy).
2. **Kali dostaje DWIE karty sieciowe** (Ustawienia maszyny → Sieć → Karta 1 i Karta 2):
   - **Karta 1 — Sieć wewnętrzna (Internal Network):** nią atakujesz cele (DVWA, Juice Shop). Cele mają tylko tę kartę, więc są odcięte od internetu.
   - **Karta 2 — Mostkowana (Bridged):** nią Kali widzi Raspberry w sieci domowej, więc skan honeypota realnie do niego dotrze.
3. Cele ataku (DVWA, Juice Shop) zostaw **tylko** na Sieci wewnętrznej — nigdy nie dawaj im Bridged ani internetu.

> Dlaczego dwie karty: bez Bridged Kali nie zobaczy Pi (jest w innej sieci), więc ćwiczenie wykrywania by nie działało. Szczegóły: [network-topology.md](network-topology.md).

> 📘 Pierwszy raz z sieciami w VirtualBoxie? Czym jest wirtualna karta, czym różnią się tryby mostkowany, wewnętrzny, host-only i NAT: [04b — Sieci w VirtualBoxie](04b-sieci-virtualbox.md).

## 4b. Kali Linux

1. Pobierz gotowy obraz: [Kali dla VirtualBox](https://www.kali.org/get-kali/#kali-virtual-machines) (wersja *Virtual Machines*).
2. Zaimportuj do VirtualBox i uruchom. Domyślny login `kali`/`kali` — **zmień hasło** od razu (`passwd`). Przez kartę mostkowaną Kali jest widoczny dla całej sieci domowej. Jak ktoś mógłby go przejąć z domyślnym hasłem i jak się bronić: [04b, sekcja ❗](04b-sieci-virtualbox.md#-jak-ktoś-z-sieci-domowej-mógłby-przejąć-kali-z-hasłem-kalikali).
3. Zaktualizuj:

```bash
sudo apt update && sudo apt full-upgrade -y
```

Narzędzia na start: **nmap** (co jest w sieci), **Wireshark** (podgląd ruchu), **Burp Suite** (analiza aplikacji WWW).

## 4c. Cele — DVWA i OWASP Juice Shop

Cele stoją na **osobnej maszynie** `cele` (Ubuntu Server), która ma tylko kartę w sieci wewnętrznej `labnet`. Docker jest z oficjalnego repozytorium, DVWA z pliku `compose.yml` autora ([github.com/digininja/DVWA](https://github.com/digininja/DVWA)), Juice Shop z obrazu `bkimminich/juice-shop`.

| Aplikacja | Adres z Kali | Logowanie |
|---|---|---|
| DVWA | `http://10.10.10.10:4280` | najpierw `setup.php` → *Create / Reset Database*, potem `admin` / `password` |
| OWASP Juice Shop | `http://10.10.10.10:3000` | bez logowania; panel wyzwań w menu |

Instalacja krok po kroku, ze zrzutami i wpadkami: [04d](04d-docker-dvwa-juice-shop.md).

> ℹ️ Wcześniejsza wersja tego rozdziału proponowała `apt install docker.io` i stary obraz `vulnerables/web-dvwa` na porcie 80. Nie używam ich: obraz od lat nie jest aktualizowany, a autor DVWA wspiera Dockera z oficjalnego repozytorium i własny `compose.yml`.

➡️ Następnie: [05 — Pierwsze ćwiczenie](05-first-exercise.md)
