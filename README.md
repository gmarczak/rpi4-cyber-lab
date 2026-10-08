# Raspberry Pi 4 Home Cyber Lab 🛡️⚔️

A home cybersecurity lab built on a Raspberry Pi 4, documenting the full build from unboxing to a working **blue team (defense) / red team (attack)** setup.

🇵🇱 **Polski:** [README.pl.md](README.pl.md) · detailed step notes in [`docs/`](docs/) are in Polish.

> ⚠️ **Ethics & legal:** Everything here runs on **my own hardware and my own network**, or on platforms that explicitly allow it. Attack targets live in an isolated virtual network, never exposed to the internet. Scanning or attacking systems you don't own is illegal (in Poland: art. 267 of the Penal Code). This repo is for learning defensive and offensive security on equipment I control.

## What this is

Two roles across two machines:

- **Raspberry Pi 4 = the defender (blue team).** Runs 24/7, acts as a honeypot (OpenCanary) and monitors network traffic (Suricata, ntopng). It logs anyone probing it.
- **A laptop/PC = the attacker (red team).** Runs Kali Linux in VirtualBox plus deliberately vulnerable targets (DVWA, OWASP Juice Shop) in an isolated network.

The learning loop: **run an attack → check whether the defender caught it in the logs → tune the rules.**

![Network topology](diagrams/network-topology.svg)

## Hardware

| Part | Model | Price (PLN) |
|------|-------|-------------|
| Board | Raspberry Pi 4 Model B, 4GB | 479.90 |
| PSU | Official USB-C 5.1V/3A | 37.90 |
| Case | Official Pi 4B case (graphite) | 23.90 |
| Heatsinks | Pi 4B heatsink set (×4) | 4.90 |
| Card (system) | SanDisk Extreme microSD 64GB A2 | 139.00 |
| USB drive (logs) | SanDisk Ultra Fit 64GB USB 3.1 | 79.90 |

Full details: [`docs/01-hardware.md`](docs/01-hardware.md).

## Build documentation

1. [Hardware & shopping list](docs/01-hardware.md)
2. [OS setup — flashing & first boot](docs/02-os-setup.md)
3. [The defender — honeypot & monitoring on the Pi](docs/03-defender-raspberry.md)
4. [The attacker — Kali & targets on the PC](docs/04-attacker-kali.md)
5. [First exercise — attack & detection loop](docs/05-first-exercise.md)
6. [Network topology explained](docs/network-topology.md)

📓 **Build journal:** [`build-log/build-log.md`](build-log/build-log.md) — dated notes on what was done and what went wrong.

⚙️ **Config & scripts:** [`config/`](config/) — example OpenCanary config, Suricata notes, helper scripts (no secrets, no real IPs).

## Status

🚧 Build in progress — parts arrived 2026-10-08. Follow the [build log](build-log/build-log.md).

## License

[MIT](LICENSE) — do what you like, no warranty.
