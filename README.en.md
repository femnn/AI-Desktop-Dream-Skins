# AI Desktop Dream Skins

English · [中文](README.md)

A complete desktop-theme workflow for Codex, Tencent WorkBuddy, and TRAE Work. This repository contains platform-specific Skills, CSS, packaged base themes, event-driven relaunch recovery, and real UI screenshots—not just wallpapers.

## Included base themes

| Platform | Base theme | Included | Relaunch recovery |
| --- | --- | --- | --- |
| Codex | ASTRO BOT · Starship | Full UI, independent decorations, four expressions, DualSense pet | Codex session guard |
| WorkBuddy | Switch 2 · Adventure All-Stars 1.2.1 | Measured hero, cartridge, Joy-Con, home and conversation CSS | Event-driven, hot recovery first |
| TRAE Work / TRAE SOLO | Xbox Series X\|S · Power Lab | X/S artwork, black-green UI, home and chat coverage, readable editor | Event-driven, hot recovery first |

### Codex · ASTRO BOT

![Codex ASTRO BOT home](screenshots/codex/home.png)

![Codex ASTRO BOT project view](screenshots/codex/project.png)

![Codex DualSense pet actions and expressions](screenshots/codex/pet.png)

### WorkBuddy · Switch 2

![WorkBuddy Switch 2 home](screenshots/workbuddy/home.png)

![WorkBuddy Switch 2 project view](screenshots/workbuddy/project.png)

### TRAE · Xbox Series X|S

![TRAE Xbox home](screenshots/trae/home.png)

![TRAE Xbox project view](screenshots/trae/project.png)

## Install the Skills

Run on macOS:

```bash
./scripts/install-skills-macos.sh
```

Existing Skills are backed up under `~/.codex/skill-backups/` before the five bundled components are installed. Installation does not force-close running apps. See the [English startup guide](docs/STARTUP-GUIDE.en.md) for activation and recovery commands.

## Every-launch notes

1. Open the app normally from Dock or Finder and wait; do not click the icon repeatedly.
2. If WorkBuddy or TRAE starts without its debugging endpoint, the guard may perform exactly one recovery restart.
3. Finish artwork, CSS, and packaging before any restart. Reserve restart testing for final acceptance.
4. Run `./scripts/check-installation-macos.sh` before reinstalling when a theme is missing.
5. Run the platform `persist` command whenever the active package path changes.
6. Save unsent input before a manually authorized recovery restart.

## Repository layout

```text
skills/       Platform Skills, router, and pet pipeline
themes/       Three installable base themes
screenshots/  Home, conversation, and readability evidence
docs/         Bilingual startup and recovery guides
scripts/      Installer and read-only diagnostics
```

## Compatibility principles

- Each platform keeps its own dimensions, DOM contract, port, manifest, and package format.
- A complete theme covers both the landing page and real project conversations.
- Decorative layers must be pointer-inert, and text contrast must be checked at live size.
- The persistence guard reacts to launch events; it does not poll and never reopens an app after the user quits.

## Notice

This is an unofficial, fan-made local theming toolkit. Product names and marks including Codex, ASTRO BOT, PlayStation, Nintendo Switch, Xbox, TRAE, and WorkBuddy belong to their respective owners. Original theme artwork in this repository does not imply endorsement or official authorization. Users are responsible for applicable terms and redistribution rights.
