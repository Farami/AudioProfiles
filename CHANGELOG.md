# Changelog

All notable changes to Audio Profiles are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-08-14

### Added

- Right-click a quick-switch bar button to open the settings window with that profile selected.

### Fixed

- Switching profiles inside delves no longer stutters the game.

## [1.1.1] - 2026-08-14

### Fixed

- Switching profiles no longer freezes the game for seconds in sound-heavy areas.
- Dragging a volume slider no longer stutters.

## [1.1.0] - 2026-08-14

### Added

- **Dungeon (season)** content category that follows the current Mythic+ rotation automatically.
- `/ap season` prints the dungeons the season category currently matches.

### Fixed

- Current-expansion dungeons and raids are no longer misclassified as legacy content.

### Changed

- The season category now outranks the current/legacy dungeon categories when both match.
- Category labels name the current expansion instead of a hardcoded one.

## [1.0.0] - 2026-05-29

First public release.

### Added

- Save and switch between named audio profiles (Master, Music, Effects, Ambience, Dialog, DSP).
- Configuration window with profile list, volume sliders, and copy-from-game action.
- Draggable quick-switch bar for one-click profile changes.
- Re-apply last profile on login option.
- Content-linked auto-switch: bind profiles to world, dungeons, and raids.
- Keybindings: toggle config, next profile, previous profile.
- Slash commands: `/audioprofiles` and `/ap`.

[1.2.0]: #
[1.1.1]: #
[1.1.0]: #
[1.0.0]: #
