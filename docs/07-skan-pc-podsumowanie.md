# Misja „skan własnego PC”: podsumowanie

**Data:** 9–10.10.2026 · **Gdzie:** PC z Windows 10, Raspberry `honeypi`, panel routera Orange · **Pełny opis:** [07 — z Raspberry atakuję własny PC](07-skan-wlasnego-pc.md)

Krótka wersja misji: po co, co znalazłem, co zmieniłem i czego mnie to nauczyło.

---

## Po co

Raspberry na chwilę zamienia się z obrońcy w atakującego i patrzy na mój PC tak, jak zobaczyłby go ktoś, kto dostał się do sieci domowej. Pytania:

1. Co mój PC **wystawia** do sieci domowej?
2. Co mój dom wystawia do **internetu** (router)?
3. Co z tego zamknąć, a co świadomie zostawić?

> ⚠️ Tylko własny sprzęt we własnej sieci (art. 267 kk).

## Przed i po

| | Przed | Po |
|---|---|---|
| Otwarte porty TCP widoczne z sieci domowej | **4** (135, 139, 445, 2179) | **0** z 65 535 |
| Porty UDP (100 najpopularniejszych) | nie sprawdzane | brak czystego `open` |
| Udostępnione foldery | `Users` (`C:\Users`, **Wszyscy: Full**) + systemowe | tylko systemowe |
| Pulpit zdalny (RDP) | wyłączony | wyłączony (potwierdzone) |
| Firewall Windows: wyjątki | m.in. **Node.js** wpuszczany w profilu Public | Node.js wyłączony |
| Łatki Windows 10 | brak (koniec wsparcia, PC niezapisany do ESU) | **ESU do 12.10.2027**, łatki z 10.10.2026 |
| Router: przekierowania z internetu | `minecraft` 25565 → PC | brak |
| Router: UPnP | włączone + martwy wpis | włączone (dla PS5), bez martwych wpisów |
| Router: DMZ | brak | brak |
| Router: WPS | włączony | wyłączony w sieciach domowych |
| Nieznane urządzenia w sieci | „localhost” pod `.16` | zidentyfikowany: telewizor Samsung |

## Dzień 1: 4 otwarte porty

```bat
:: na Raspberry
nmap -Pn ADRES_PC
```

![nmap przed zmianami: 4 otwarte porty](../screenshots/2026-10-09-pc-self-scan/03-nmap-przed.png)

Profil sieci był **Public**, a mimo to z sieci widać było udostępnianie plików (139, 445), RPC (135) i Hyper-V (2179). Winne były reguły firewalla, które otwierały te porty także w profilu Public.

![Reguły firewalla otwierające porty](../screenshots/2026-10-09-pc-self-scan/04-reguly-firewalla.png)

Po wyłączeniu udostępniania w profilu Public, NetBIOS i funkcji Hyper-V:

![nmap po zmianach: wszystko filtered](../screenshots/2026-10-09-pc-self-scan/05-nmap-po.png)

Wszystkie 1000 portów `filtered`, a skan trwał 201 s zamiast 4,6 s, bo firewall po cichu odrzuca każdą próbę.

## Dzień 2: wszystko, czego zwykły skan nie widzi

| Obszar | Znalezisko | Co zrobiłem |
|---|---|---|
| Udziały SMB | `Users` → `C:\Users`, **Wszyscy: Full** | `Remove-SmbShare -Name Users` (pliki zostają) |
| Windows Update | koniec wsparcia, brak łatek | zapis do ESU, łatki zainstalowane |
| Firewall | Node.js wpuszczany z sieci Public | reguły wyłączone |
| Router: NAT/PAT | martwe przekierowanie `minecraft` do PC | usunięte |
| Router: UPnP | martwy wpis po nieistniejącym urządzeniu | usunięty; UPnP zostaje dla PS5 |
| Router: Wi-Fi | WPS włączony | wyłączony; hasło zostaje (decyzja domowa) |
| Sieć | nieznany Samsung | telewizor |
| Skan | wszystkie porty TCP i 100 UDP | nic otwartego |

```bash
# na Raspberry: pełny skan
sudo nmap -Pn -p- -T4 --max-retries 1 ADRES_PC        # 65535 filtered, 22 min
sudo nmap -Pn -sU --top-ports 100 -T4 ADRES_PC        # 100 open|filtered
```

## Bonus: obrońca widział atak

Skan szedł z Raspberry, więc Suricata na Raspberry go obserwowała. W `fast.log` pojawiło się kilkanaście alertów `ET SCAN …` i `GPL …`, np. za próby na porty baz danych (Oracle, PostgreSQL, MSSQL), VNC, SNMP i TFTP.

Wniosek: Suricata alarmuje tylko przy portach, dla których ma konkretne reguły. Na **sam fakt skanowania** nie ma reguły. To materiał na własną regułę w [Etapie 4](05-first-exercise.md).

## Najważniejsze wpadki

| Wpadka | Lekcja |
|---|---|
| Profil Public, a porty otwarte | profil sieci to nie wszystko; decydują konkretne reguły firewalla |
| Udział `Users` z prawem Wszyscy: Full | każdą warstwę zabezpieczeń sprawdzam osobno, nie tylko firewall |
| Martwe przekierowanie i wpis UPnP | ustawienia w routerze żyją dłużej niż programy, dla których powstały |
| Reguła Node.js w profilu Public | każde „Zezwól” kliknięte na szybko zostaje w systemie; przeglądam wyjątki |
| Kliknięty WPS zaczął parowanie | w panelu routera rozróżniam przełączniki od przycisków akcji |
| Prawdziwe hasło w logu honeypota | honeypot zapisuje wszystko, także moje pomyłki; do Raspberry łączę się na port 2222 |
| ESU „do 13.10.2026” z forum | daty i zasady sprawdzam na oficjalnej stronie, nie na forum |

## Świadome decyzje (zostaje, bo…)

| Co | Dlaczego zostaje |
|---|---|
| UPnP włączone | PS5 potrzebuje go do gier sieciowych i czatu |
| Hasło Wi-Fi i WPA2 | zmiana wymagałaby nowego hasła na wszystkich urządzeniach domowników |
| WPS w sieci IoT | router nie pozwala wyłączyć; sieć IoT jest wyłączona |
| Windows 10 zamiast 11 | i5-7600K nie spełnia wymagań Windows 11; ESU daje łatki do 12.10.2027 |

## Na później

- sieć **IoT** dla telewizora i pralki, żeby odciąć je od PC,
- nowy sprzęt przed **12.10.2027** (koniec ESU),
- dłuższe hasło do Wi-Fi przy najbliższej okazji,
- ta sama misja dla MacBooka: [07b](07b-skan-macbooka.md).

## Słowniczek

| Pojęcie | Znaczenie |
|---|---|
| port | „numer mieszkania” programu pod adresem IP komputera |
| TCP / UDP | dwa sposoby przesyłania: z nawiązaniem połączenia i potwierdzeniami / bez |
| `filtered` / `open\|filtered` | firewall milczy / przy UDP nie da się odróżnić otwartego portu od zablokowanego |
| profil sieci (Public / Private) | zestaw reguł firewalla Windows zależny od tego, jak ufamy sieci |
| udział SMB | folder udostępniony w sieci; `$` na końcu nazwy = ukryty, systemowy |
| NAT / przekierowanie portów | router chowa urządzenia przed internetem / wyjątek, który wpuszcza ruch do jednego z nich |
| UPnP | programy same dodają przekierowania w routerze |
| DMZ | całe urządzenie wystawione do internetu |
| WPS | łączenie z Wi-Fi bez hasła, przyciskiem albo PIN-em (PIN ma znaną słabość) |
| ESU | płatne lub bezpłatne (z kontem Microsoft) przedłużenie łatek Windows 10 |

➡️ Wróć do [ROADMAP](../ROADMAP.md) albo do pełnego rozdziału [07](07-skan-wlasnego-pc.md).
