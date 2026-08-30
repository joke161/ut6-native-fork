# Change Log

## [6.3.3-native-fork] - 2026-08-30

Fork of the original project. See [README.md](README.md) for the full list of
changes. Summary:

### Changed

- Replaced the web-browser UI (Vue.js app + local Node.js server) with a
  native in-game Lua menu. Node.js is no longer a prerequisite.
- Reworked Stat Editor multiplier sliders (Speed/Fire Rate/Damage/Throw
  Distance) to a consistent "1.0 = normal, can't go below it" model, split
  across two sub-tabs.
- Interaction Speed slider now shows a percentage (100-500%) instead of a raw
  multiplier, and shares one hook with the existing Instant Interaction
  toggle instead of conflicting with it.
- Damage Multiplier no longer also affects melee damage; that's now its own
  independent slider.

### Added

- Melee Damage Multiplier, Dodge Chance Bonus (with live real-value display),
  Max Health Multiplier, Max Armor Multiplier, Reload Speed Multiplier, Ammo
  Pickup Multiplier, Detection Range Multiplier.
- Click-to-type and right-click-to-reset-to-default on Stat Editor sliders.
- Persistence for Stat Editor sliders that previously weren't being saved at
  all.

### Fixed

- Trainer menu mis-positioning/clipping when opened mid-heist.
- Crash in Carry Stacker when toggled outside active gameplay.
- Damage Multiplier not applying at all.
- Missing gameplay-state guards on ~20 Gunplay/Survivability/Stats setters
  that could be triggered (in some cases crash) outside an active heist.

## [6.3.3] - 2023-09-28

### Added

- Discord button

## [6.3.2] - 2023-09-18

### Added

- Turkish locale

## [6.3.1] - 2023-09-17

### Fixed

- Potential bug due to the code editor

## [6.3.0] - 2023-09-13

### Added

- Addons
- Mouse buttons support (keybinds)
- Custom keys support (keybinds)
- Polish locale

### Fixed

- Issues with http-server
- Bug with spawn tab after heist restart or leave
- Crash when spawning a unit after the original has disappeared (build)

## [6.2.0] - 2023-08-12

### Added

- Custom keybinds
- Sync between app instances
- Japanese locale
- Test script

## [6.1.0] - 2023-07-29

### Added

- Hide mod list
- Hide Ultimate Trainer from menu
- Carry multiple bags
- Suspend point of no return timer
- No civilian kill penalty
- Remove team AI
- Spawn explosions
- Teleport to players
- Korean locale
- Portuguese (Brasil) locale

### Fixed

- Search fields don't work/crash the app
- Vapor theme background bugged

## [6.0.0-beta] - 2023-07-23

Initial release
