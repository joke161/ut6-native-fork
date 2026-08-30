# PAYDAY 2 - UT6 Native Fork

A community fork of [Ultimate Trainer 6](https://github.com/pierre-josselin/payday-2-ultimate-trainer-6) by Pierre Josselin.

This fork replaces the original web-browser UI (Vue.js app + local Node.js server) with a **native in-game Lua menu**, built directly on top of the SuperBLT/Diesel GUI API. No browser, no Node.js, no second window — the whole trainer runs and is controlled from inside the game.

This is not affiliated with the original author. All credit for the original mod, its feature set, and its contributors goes to them — see [CREDITS.md](CREDITS.md). This fork only documents and ships the changes described below.

## What changed vs. the original

### Native menu instead of a web app

- The entire Vue.js/Bootstrap web application and its local HTTP server have been removed. There is nothing to install, run, or keep open outside the game.
- A native menu (`classes/UTMenu.lua`) is built directly with Diesel GUI primitives: sidebar with tabs/sub-tabs, toggle switches, sliders, number inputs, action button grids, popovers, and a right-click keybind editor (bind a key/mouse button to any toggle or slider, with a global hotkey list).
- Custom UI textures (rounded corners, iOS-style toggle switches, a settings gear icon) are shipped as real `.texture` (DDS) assets and composited with a 9-slice technique, since Diesel doesn't support flat texture stretching for rounded rects.
- Menu opens with `Insert` / closes with `Delete` by default (see `UTMenu.lua` for the exact keys), fully independent of any browser or external process.

### Prerequisites are simpler now

Only [SuperBLT](https://superblt.znix.xyz) is required. **Node.js is no longer needed.**

### Stability fixes

- Fixed the trainer menu mis-positioning/clipping when opened mid-heist (it now re-centers itself against the live workspace size every time it's opened, instead of caching a position computed once at the very first open).
- Fixed a crash in Carry Stacker when it was toggled outside of active gameplay.
- Added a proper gameplay-state guard (`isInHeist()`) to ~20 Gunplay/Survivability/Stats setters (God Mode, No Fall Damage, Infinite Stamina, Instant Interaction, Instant Weapon Swap/Reload, No Weapon Recoil/Spread, Shoot Through Walls, Unlimited Ammo, No Slow Motion, and all Stat Editor multipliers) that could previously be triggered — and in a couple of cases crash — outside of an active heist. They now safely no-op and simply save the setting, then apply it for real once you're actually playing (matching how X-Ray already behaved).
- Fixed `Damage Multiplier` not applying: it was checking the attacker unit against the wrong player-reference call and calling through to the original function via an unreliable path.

### Stat Editor — reworked and expanded

The four original multiplier sliders (Speed, Fire Rate, Damage, Throw Distance) used to represent an absolute value with a strange floor (e.g. Fire Rate started at "2"). They've been reworked to a consistent "normal = 1.0, can't go below it, the slider only adds on top" model, split across two sub-tabs (**Stats** / **Stats II**) so everything fits on screen:

**Stats**
- Speed Multiplier, Fire Rate Multiplier, Damage Multiplier *(now bullet damage only)*
- **New:** Melee Damage Multiplier *(split out from Damage Multiplier so they can be tuned independently)*
- Throw Distance Multiplier
- **New:** Dodge Chance Bonus — shows your real, live dodge chance (movement-state aware: standing/running/crouching/zipline all read correctly) plus however much your bonus is adding, refreshed automatically while the menu is open

**Stats II**
- **New:** Max Health Multiplier, Max Armor Multiplier
- **New:** Reload Speed Multiplier — hooked two ways: shell-by-shell weapons (shotguns) via their native speed-multiplier getter, magazine weapons via compressing the reload completion timer after the vanilla reload starts
- **New:** Ammo Pickup Multiplier
- **New:** Interaction Speed % (100–500%) — replaces the old raw multiplier slider with a percentage; anything faster than 500% is available separately via the existing Instant Interaction toggle, which the two now share one conflict-free hook for
- **New:** Detection Range Multiplier — verified against a real community mod's technique (scales `PlayerBase`'s detection range multiplier rather than guessing at the suspicion-meter math)

All Stat Editor sliders now:
- Actually persist across restarts (several previously weren't being saved at all) and re-apply automatically when you next spawn in.
- Support click-to-type (click the value to type an exact number) alongside the usual drag.
- Reset to default on right-click, via the same keybind-menu popover used for binding a hotkey.

### What was investigated and *not* shipped

In the interest of not shipping guesses dressed up as features:
- **Armor Regen Delay** and **Crit Chance / Crit Damage bonuses** were researched but no safe, verified hook could be confirmed against any real reference implementation, so they were left out rather than included half-working.
- **Detection Risk (hard override to an exact %)** was attempted three different ways and never reliably affected real detection outcomes — only the live *read* of your current detection value survived, which is now folded into how Detection Range Multiplier reports state.

## Installation

1. Install [SuperBLT](https://superblt.znix.xyz).
2. Drop the `payday-2-ultimate-trainer-6-mod` folder and `mod.txt` from this repository into your PAYDAY 2 `mods` folder.
3. Launch the game. Open the trainer with `Insert` (in-heist or in the main menu).

## License

GPLv3, same as the original project — see [LICENSE](LICENSE). Per section 5(a) of the GPL, this file itself is the required notice that this is a modified version, dated by this repository's commit history.
