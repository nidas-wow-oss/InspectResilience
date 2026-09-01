*[Leer en español](README.es.md)*

# Inspect Stats Panel

An addon for **World of Warcraft 3.3.5a (WotLK)** that adds a stats panel to the inspect window: when you look at another player's gear, it shows their **resilience** and the rest of their combat stats, calculated from the equipment they are wearing.

**Version:** 2.5 · **Author:** Nidhaus

## Why it exists

In PvP, knowing the enemy's resilience before the fight changes whether you open on them or not. WoW 3.3.5a does not show that number when you inspect someone, so the addon adds it up from the target's gear and puts it in a panel next to the inspect window.

## What it does

- Shows the total **resilience** of the inspected player.
- Shows the rest of the **combat stats** derived from their equipment.
- Sits inside the standard inspect window — no extra frames to manage.
- Enabled by default (`## DefaultState: enabled`), no setup required.

## Installation

1. Close the game.
2. Copy the `InspectResilience` folder into `World of Warcraft\Interface\AddOns\`.
3. Start the game and enable the addon on the character selection screen.

## Commands

| Command | Action |
|---|---|
| `/ires` | Open the addon options |
| `/isp` | Short alias |
| `/inspectstats` | Long alias |

## Compatibility

Interface 30300 — WotLK 3.3.5a. Tested on Warmane.

## License

Free to use. If you redistribute it or build on it, keep the credit to the author.
