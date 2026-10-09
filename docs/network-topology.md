# Topologia sieci / Network topology

![Diagram](../diagrams/network-topology.svg)

## 🇵🇱 Po polsku

Lab ma dwie role na dwóch maszynach. Kluczowy jest podział sieci.

**Raspberry Pi (obrońca)** siedzi w domowej sieci LAN, podłączony kablem do routera. Działa 24/7 jako honeypot i monitoruje ruch kierowany **do siebie**.

**Komputer (atakujący)** ma w VirtualBoxie dwie sieci:

- **Sieć wewnętrzna (Internal Network):** Kali + cele (DVWA, Juice Shop). Zamknięta, bez internetu. Tu ćwiczysz ataki na aplikacje webowe.
- **Mostkowana (Bridged):** Kali dostaje drugą kartę, przez którą widzi Raspberry w sieci domowej.

### Dlaczego dwie karty w Kali

Bez karty Bridged Kali nie widziałby Raspberry — Internal Network istnieje tylko wewnątrz VirtualBoxa, a Pi jest w sieci domowej. Skan honeypota by nie dotarł. Bez Internal Network cele ataku byłyby wystawione na zewnątrz. Dwie karty rozwiązują oba problemy:

- Karta 1 (Internal) → atak na cele, odcięte od świata
- Karta 2 (Bridged) → Kali widzi Pi, skan honeypota dociera do logów

Tryby sieci w VirtualBoxie od podstaw (wirtualna karta, mostkowana, wewnętrzna, host-only, NAT) i ryzyko domyślnego hasła Kali w trybie mostkowanym: [04b — Sieci w VirtualBoxie](04b-sieci-virtualbox.md).

### Co wykrywa obrońca

Suricata i honeypot na Pi widzą tylko ruch **do/z samego Pi**. Skan `nmap` na Raspberry (przez Bridged) → trafia do logów. Atak na DVWA dzieje się wewnątrz komputera i **przez Pi nie przechodzi** → obrońca go nie widzi. To celowe: obrona i atak webowy to dwa osobne ćwiczenia.

## 🇬🇧 In English

Two roles, two machines. The network split is the key.

**Raspberry Pi (defender)** sits on the home LAN, wired to the router. Runs 24/7 as a honeypot and monitors traffic aimed **at itself**.

**PC (attacker)** runs two networks in VirtualBox:

- **Internal Network:** Kali + targets (DVWA, Juice Shop). Closed, no internet. Web-app attacks happen here.
- **Bridged:** Kali gets a second NIC so it can see the Raspberry Pi on the home LAN.

**Why two NICs on Kali:** without Bridged, Kali can't reach the Pi (Internal Network only exists inside VirtualBox); without Internal Network, the targets would be exposed. Two NICs solve both — NIC 1 (Internal) attacks the isolated targets, NIC 2 (Bridged) lets Kali reach the Pi so honeypot scans land in the logs. VirtualBox network modes from scratch, and why a bridged Kali with the default password is a risk: [04b (PL)](04b-sieci-virtualbox.md).

**What the defender sees:** Suricata and the honeypot only see traffic to/from the Pi itself. An `nmap` scan of the Pi (over Bridged) shows up in the logs; a DVWA attack stays inside the PC and never crosses the Pi — by design. Defense and web attack are two separate exercises.
