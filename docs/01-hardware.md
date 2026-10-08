# 01 — Sprzęt i lista zakupów

## Raspberry (obrońca)

| Część | Model | Indeks | Cena (zł) | Po co |
|-------|-------|--------|-----------|-------|
| Płytka | Raspberry Pi 4 Model B, 4GB | RPI-14647 | 479,90 | 4 GB RAM pod honeypot + monitoring, zapas na przyszłość |
| Zasilacz | Oryginalny USB-C 5,1V/3A | RPI-14348 | 37,90 | Stabilne napięcie — tani zasilacz = restarty i padnięte karty |
| Obudowa | Oficjalna Pi 4B grafitowa | RPI-14659 | 23,90 | Ochrona |
| Radiatory | Zestaw do Pi 4B (×4) | DNG-18746 | 4,90 | Chłodzenie pasywne, wentylator niepotrzebny |
| Karta | SanDisk Extreme microSD 64GB A2 | KAP-08540 | 139,00 | **System** |
| Pendrive | SanDisk Ultra Fit 64GB USB 3.1 | BAL-10584 | 79,90 | **Logi** (monitoring dużo zapisuje — oszczędza kartę) |

**Razem: ok. 765 zł, darmowa wysyłka.**

## Komputer (atakujący)

Nie kupowany — wykorzystuję własny. Wymagania:

- **min. 8 GB RAM** (Kali w VM potrzebuje 2–4 GB, cele kolejne 1–2 GB),
- **~40 GB wolnego miejsca** na maszyny wirtualne,
- procesor z obsługą wirtualizacji (VT-x / AMD-V, zwykle włączone domyślnie),
- system: Windows / macOS / Linux — VirtualBox działa na każdym.

## Czego NIE trzeba

- **Czytnik kart** — MacBook ma wejście SD, karta ma adapter SD w zestawie. (Czytnik USB przyda się tylko jako zapas albo do nagrywania z PC bez wejścia SD.)
- **Zewnętrzna karta Wi-Fi z trybem monitor** — dopiero przy audycie własnego Wi-Fi, nie na start.
- **Wersja 8 GB / gotowe zestawy za 800+ zł** — zbędne.

## Uwagi

- Karta na **system**, pendrive/SSD na **logi** — rozdzielenie przedłuża żywotność karty.
- Kabel LAN: wystarczy dowolny Cat 5e/6, nawet stary. Podłączenie Pi kablem jest stabilniejsze niż Wi-Fi.
