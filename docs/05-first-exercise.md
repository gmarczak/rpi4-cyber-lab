# 05 — Pierwsze ćwiczenie: pętla atak-wykrycie

Sedno labu: robisz coś jako atakujący, potem sprawdzasz, co zobaczył obrońca.

## Ćwiczenie obrony: skan Raspberry

1. **Atak (Kali, przez kartę Bridged):** przeskanuj Raspberry, żeby zobaczyć otwarte usługi:
   ```bash
   nmap -sV ADRES_RASPBERRY
   ```
   To pierwszy ruch każdego napastnika — rozpoznanie, co jest do zaatakowania.

2. **Obrona (Raspberry):** zajrzyj w logi honeypota i Suricaty:
   ```bash
   sudo tail -f /var/log/opencanary/opencanary.log
   sudo tail -f /var/log/suricata/fast.log
   ```
   Albo oba naraz skryptem `check-logs.sh` z [03, część 3](03-defender-raspberry.md#część-3-podgląd-alertów--check-logssh). Log honeypota leży w `/var/log/opencanary/`, czyli na pendrivie ([03, krok 2](03-defender-raspberry.md#krok-2-konfiguracja-pułapek-i-firewall)), a nie w domyślnym `/var/tmp/`.
   Powinieneś zobaczyć zapis swojego skanu.

3. **Wniosek:** porównaj, co zrobiłeś, z tym, co urządzenie wykryło. Sedno nauki to nie „czy się udało", tylko „czy zostawiłem ślad i czy obrona go złapała".

## Ćwiczenie ataku: aplikacje webowe (osobno)

Na DVWA/Juice Shop (przez kartę Sieć wewnętrzna) ćwiczysz podatności webowe: wejdź na niski poziom zabezpieczeń DVWA i przejdź przez kolejne kategorie (każda ma podpowiedź i podgląd kodu). Po każdej próbie zobacz w Wiresharku, jak wyglądał ruch.

## ⚠️ Co wykrywa obrońca, a co nie

- Suricata i honeypot łapią atak **skierowany na samo Raspberry** (skan nmap przez Bridged).
- Atak na DVWA/Juice Shop dzieje się **wewnątrz komputera** (Sieć wewnętrzna) i **nie przechodzi przez Raspberry** — obrońca go nie zobaczy, i to jest normalne.
- Dlatego to **dwa osobne ćwiczenia**: obrona = skanujesz Pi i czytasz logi; atak webowy = osobno na celach.

## Dalej

- Dopisuj/włączaj reguły w Suricacie i sprawdzaj, czy teraz wykrywa to, co wcześniej przeszło.
- Rozwijaj honeypot o kolejne usługi-pułapki.
- Ścieżka nauki: [TryHackMe](https://tryhackme.com/) → własny lab → [Hack The Box](https://www.hackthebox.com/).
