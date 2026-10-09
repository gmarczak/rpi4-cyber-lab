# Zasady pracy w tym repo

Repo dokumentuje budowę domowego labu cyberbezpieczeństwa na Raspberry Pi 4 (`honeypi`). Właściciel uczy się od zera, więc dokumentacja ma tłumaczyć, a nie tylko wypisywać komendy. Język dokumentacji: polski (README i ROADMAP dwujęzyczne PL/EN).

## Podsumowanie na koniec każdego etapu

Po zamknięciu etapu z [ROADMAP.md](ROADMAP.md) powstaje **jeden plik** `docs/etap-N-podsumowanie.md` z całym etapem. Wzór: [docs/etap-1-podsumowanie.md](docs/etap-1-podsumowanie.md). Etap 0 (sprzęt i montaż) nie ma podsumowania.

Plik zawiera, w tej kolejności:

1. **Cel etapu**: po co ten etap, w kilku punktach.
2. **Przed i po**: tabela stanu przed etapem i po nim.
3. **Jak to teraz wygląda**: prosty schemat (ASCII) tego, co działa po etapie.
4. **Kroki**: każdy z krótkim „Po co”, kompletnymi komendami w bloku kodu i linkiem do szczegółowego rozdziału.
5. **Problemy po drodze**: tabela: problem, co było widać, przyczyna, rozwiązanie, lekcja. Każda wpadka z tego etapu, także drobna.
6. **Wszystkie zmienione pliki**: na Raspberry, na PC, w routerze.
7. **Kontrola stanu**: jeden zestaw komend sprawdzających cały etap i tabela oczekiwanych wyników.
8. **Słowniczek**: nowe pojęcia z tego etapu.
9. **Co dalej**: następny etap.

Po napisaniu: link w ROADMAP (przy nagłówku etapu), w obu README (sekcja „Podsumowania etapów”) i wpis w `build-log/build-log.md`.

Ostatnim zadaniem każdego etapu w ROADMAP jest „Podsumowanie etapu”.

## Rozdziały szczegółowe (`docs/0X-*.md`)

- Na górze „Komendy w skrócie” z numerami (`# 1`, `# 2`…), które zgadzają się z oznaczeniami na zrzutach.
- Potem „Co robi każda komenda”: każda komenda i każda jej opcja wyjaśniona prostym językiem.
- Wpadki opisane w osobnej sekcji z ❗, z przyczyną i lekcją.
- Na końcu link „➡️ Następnie”.

## Zrzuty ekranu (`screenshots/`)

Repo jest **publiczne**. Przed dodaniem obrazka:

- przytnij do samego okna terminala/aplikacji, **bez tła pulpitu** i bez paska przeglądarki,
- zamaż: adresy IPv6 (`fe80::…` w „Last login”), adresy IP komputerów z sieci domowej, **wszystkie adresy MAC**, nazwy innych urządzeń w sieci, hasła i tokeny. Adres `honeypi` (`192.168.1.134`) może zostać,
- oznacz komendy kolorowymi ramkami z numerami w lewym marginesie, zgodnie z numeracją w dokumencie; wpadki na czerwono lub żółto z „!”,
- zdjęcia z telefonu: bez metadanych EXIF, płytka zawsze w tej samej orientacji (GPIO u góry, porty po prawej),
- numeracja plików ciągła w folderze, opis każdego zakresu w `screenshots/README.md`.

## Git

- Zmiany przez gałąź i pull request, potem merge do `master`.
- Każdy ukończony krok: odhaczony w ROADMAP i krótki wpis w `build-log/build-log.md` (PL/EN).
