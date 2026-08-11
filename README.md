# Anime Squadron Free HUB

**Language:** **English** | [Tiếng Việt](./README.vi.md)

[![Price](https://img.shields.io/badge/price-free-22c55e)](#free--open-source)
[![Source](https://img.shields.io/badge/source-open-3b82f6)](#free--open-source)
[![Language](https://img.shields.io/badge/language-Luau-00a2ff)](https://luau.org/)
[![License](https://img.shields.io/badge/license-MIT-f59e0b)](./LICENSE)

**Anime Squadron Free HUB** is a free and open-source Luau automation script with built-in English and Vietnamese interfaces. It combines lobby farming, match utilities, progression tools, party automation, and local session tracking in one configurable UI.

The project has no key system, no paywall, and no user fee.

> This is a community project and is not affiliated with or endorsed by Roblox or the developers of Anime Squadron. Use third-party software at your own risk and follow the platform's terms of service.

## Features

- Master Auto Farm with configurable task priorities.
- Auto Join Map by world, mode, difficulty, and act.
- Automatic Gear farming with persistent target queues and quantity tracking.
- Automatic Unit farming with drop-map detection.
- Trait Map farming with priority and difficulty settings.
- Daily and regular Challenge Sniper with target reward selection.
- Auto Quest, daily rewards, free bundle, battlepass, milestones, and discovery index claims.
- Auto Evo and persistent multi-item Craft queue.
- Auto Stat Reroll with unit selection and stat locking.
- Automatic Merchant, Raid Shop, Event Shop, and Perk upgrades.
- In-match Auto Play, replay, replay-at-wave, speed, ultimate, and leave failsafes.
- Challenge Sniper time synchronization for `XX:00` and `XX:30` rotations.
- Host/member Party Mode for multi-account farming and synchronized leaving.
- Daily session statistics for matches and collected resources.
- Auto reconnect and stuck-server hop failsafes.
- Automatic code redemption with Update Log scanning.
- Persistent Fluent configuration and interface settings.
- English and Vietnamese language selection.
- Optional standalone local-only fake Trait Reroll and Summon visual tool.
- Anti-AFK support.

## Installation

Run the following loader in a compatible Luau environment after joining the game:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Truyem/Anime-Squadron/refs/heads/main/astt.lua"))()
```

The first launch displays a language selector. The selected language is stored in `as_free/Language.txt` and can also be changed from Settings. Restart the script after changing it.

## Requirements

- A Luau execution environment with `loadstring` and `game:HttpGet` support.
- File APIs such as `readfile`, `writefile`, `isfile`, `isfolder`, and `makefolder` for settings and queues.
- An internet connection for Fluent UI, SaveManager, InterfaceManager, and script resources.

Compatibility depends on the execution environment. Missing APIs may prevent individual features from working even if the interface loads successfully.

## Basic Usage

1. Run the loader in the lobby at least once so map and inventory data can be cached.
2. Select English or Vietnamese on the first launch.
3. Configure maps, farming targets, queues, and task priorities.
4. Enable the required feature toggles, then enable `MASTER AUTO FARM`.
5. Verify Party Mode usernames before leaving the script unattended.
6. Press `LeftControl` to minimize or restore the interface.

Settings and runtime data are stored under `as_free/as_<UserId>` in the executor workspace.

## Repository Files

- [`astt.lua`](./astt.lua): main bilingual automation hub.
- [`Fake.lua`](./Fake.lua): optional local-only Trait Reroll and Summon visual simulator.
- [`README.vi.md`](./README.vi.md): Vietnamese documentation.
- [`LICENSE`](./LICENSE): MIT License.

`Fake.lua` changes only local visuals and does not perform a real Trait reroll or Summon. The main script does not load it automatically.

## Network & Privacy

The main script does not send inventory, units, balances, usernames, or session statistics to a webhook or other external receiver. Session statistics remain in the local executor workspace.

The main script makes network requests only to:

- Load Fluent UI, SaveManager, and InterfaceManager from their official GitHub sources.
- Read Roblox's public server list when the stuck-server hop failsafe runs.

Party username resolution uses Roblox's built-in `Players:GetUserIdFromNameAsync()` API. The optional `Fake.lua` file is independent and is never executed by the main script.

## Free & Open Source

The source is publicly available for the community to inspect, improve, and contribute to at no cost.

- Do not pay anyone to obtain this script.
- Do not trust reuploads that require a key or payment.
- Download the latest version directly from the official GitHub repository.
- Keep the copyright and license notices when sharing or forking the project.

This project is released under the [MIT License](./LICENSE).

If the project helps you, please consider leaving it a star:

https://github.com/Truyem/Anime-Squadron

## Contributing

Bug reports and pull requests are welcome.

1. Fork the repository.
2. Create a branch for your change.
3. Keep changes focused and do not add obfuscated code.
4. Check the Luau syntax before opening a pull request.
5. Describe the changed behavior and how you verified it.

When reporting a bug, include the mode/map, reproduction steps, relevant console logs, and execution environment. Never publish webhook URLs, account tokens, or personal data.

## Credits

- **Truyem789**: creator and maintainer.
- [Fluent](https://github.com/dawid-scripts/Fluent): UI library, SaveManager, and InterfaceManager.
- The Anime Squadron community for testing and feedback.

## Disclaimer

This software is provided as-is and may stop working after a game update. The author is not responsible for data loss, account disruption, or other consequences resulting from its use.
