# Changelog

All notable changes to Audio Profiles are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-08-14

### Fixed

- Switching profiles froze the game for seconds at a time, worst in instances with a lot of
  ambient sound. Every apply wrote all six sound CVars unconditionally, and writing
  `Sound_EnableDSPEffects` makes the client rebuild its DSP chain — a stall that scales with
  the number of live sound emitters. CVars are now only written when the value actually
  changes, so switching between profiles that share a setting costs nothing. Dragging a volume
  slider was triggering the same rebuild on every frame of the drag and is fixed by the same
  change.

## [1.1.0] - 2026-08-14

### Added

- **Dungeon (season)** content category, matching any dungeon in the current Mythic+ rotation
  regardless of which expansion it originally shipped in. The pool is read live from the game,
  so it tracks the rotation on its own and needs no update when a new season starts.
- `/ap season` prints the pool the season category currently matches against.
- Offline test suite (`./scripts/test.sh`) that loads the real content files against a stubbed
  WoW API. Not included in the release package.

### Fixed

- Current-expansion dungeons and raids were classified as legacy. The Encounter Journal
  appends a "Current Season" tier that re-lists instances already present in their real
  expansion tier, and the index let that appended entry overwrite the real one. The first
  tier an instance appears in now wins.

### Changed

- Content categories resolve most specific first, with the season category ranked above the
  current/legacy dungeon split. A legacy dungeon in the current pool now uses your season
  profile if one is bound, and still falls through to the legacy binding if not.
- Category labels name the current expansion dynamically instead of hardcoding it.
- The current expansion's journal tier is found by name rather than from a hardcoded
  tier-to-expansion table, so an inserted journal tier can no longer shift the mapping.
  The table is gone, along with the yearly edit it required.
- Interface bumped to 12.1 (`120100`).

Existing content bindings are unaffected — no saved-variables changes.

## [1.0.0] - 2026-05-29

First public release.

### Added

- Save and switch between named audio profiles (Master, Music, Effects, Ambience, Dialog, DSP).
- Configuration window with profile list, volume sliders, and copy-from-game action.
- Draggable quick-switch bar for one-click profile changes.
- Re-apply last profile on login option.
- Content-linked auto-switch: bind profiles to world, current/legacy dungeons, and current/legacy raids.
- Keybindings: toggle config, next profile, previous profile.
- Slash commands: `/audioprofiles` and `/ap` (aliases for toggle, list, apply, next/prev, content debug).
- SavedVariables migration for content-binding settings.

[1.1.1]: #
[1.1.0]: #
[1.0.0]: #
