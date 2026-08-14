# Audio Profiles

Save WoW volume levels and switch between named audio profiles. Optionally auto-switch by content type (world, dungeons, raids).

**Supported clients:** World of Warcraft Retail (Interface `120007`, `120005`).

## Installation

1. Download the latest release zip from [CurseForge](https://www.curseforge.com/wow/addons/audio-profiles) (or extract a local build from `dist/`).
2. Install into your WoW `Interface/AddOns` folder so the path is `Interface/AddOns/AudioProfiles/`.
3. Enable **Audio Profiles** on the character select AddOns screen.
4. Type `/ap` in game to open the configuration window.

## Usage

### Configuration window

Open with `/audioprofiles`, `/ap`, or the **Toggle configuration window** keybinding.

- Create, rename, duplicate, and delete profiles.
- Adjust Master, Music, Effects, Ambience, and Dialog sliders; toggle DSP effects.
- **Copy from game** captures your current WoW volume settings into the selected profile.
- **Apply** writes the selected profile to WoW.

### Options

| Option | Description |
| --- | --- |
| Re-apply last profile after login | Restores the last manually applied profile when you log in. |
| Show draggable quick-switch bar | Floating bar with buttons for each profile. |
| Auto-switch by content | Applies content-linked profiles when you enter matching zones. |

### Content links

Assign a profile to each content category:

- World
- Dungeon (season) — any dungeon in the current Mythic+ rotation, whatever expansion it came from
- Dungeon (current expansion) / Dungeon (legacy)
- Raid (current expansion) / Raid (legacy)

The season pool is read live from the game, so it follows the Mythic+ rotation on its own and needs no update when the season changes. A legacy dungeon that is in the current pool matches **both** its season and legacy category; the season binding wins if you set one, otherwise it falls through to legacy.

Categories resolve most specific first: `raid_current`, `raid_legacy`, `dungeon_season`, `dungeon_current`, `dungeon_legacy`, `world`.

When **Auto-switch by content** is enabled, entering a matching instance or the open world switches profiles automatically. Manual profile changes suppress auto-switch until you leave the zone.

### Slash commands

| Command | Action |
| --- | --- |
| `/ap` or `/ap toggle` | Open/close config |
| `/ap list` | List profiles |
| `/ap <index>` | Apply profile by number |
| `/ap apply <name>` | Apply profile by name (partial match) |
| `/ap next` / `/ap prev` | Cycle profiles |
| `/ap context` | Print current content detection (debug) |
| `/ap links` | Print content bindings |
| `/ap link <tag> <profile>` | Set a content binding from chat |
| `/ap season` | Print the current Mythic+ pool the season tag matches against (debug) |

Content tags: `world`, `dungeon_season`, `dungeon_current`, `dungeon_legacy`, `raid_current`, `raid_legacy`.

### Keybindings

Under **Game Menu → Options → Keybindings → AddOns → Audio Profiles**:

- Toggle configuration window
- Apply next profile
- Apply previous profile

## Tests

```bash
./scripts/test.sh
```

Syntax-checks every file, then runs `tests/content_spec.lua` — an offline suite that stubs
the WoW API and loads the real `Const.lua` / `ContentIndex.lua` / `Content.lua` to assert how
content is tagged. Needs a Lua 5.1 interpreter; no game client. Tests are not included in the
release zip.

## Cutting a release

Run `/release` in Claude Code (`.claude/skills/release/`). It reads every change since the
last tag, derives the version bump from what actually changed, writes the changelog entry,
bumps `## Version` in the `.toc`, runs the tests, then commits, tags `vX.Y.Z`, and pushes.
Pass a tier to override the classification (`/release minor`). Pushing the tag is what
triggers the CurseForge git packager.

## Building a release zip

```bash
./scripts/package.sh
```

Output: `dist/AudioProfiles-<version>.zip`, where `<version>` is read from `## Version` in the
`.toc` (folder layout ready for CurseForge upload).

## CurseForge project setup

1. Create a new WoW addon project on CurseForge.
2. Upload `dist/AudioProfiles-<version>.zip`, or connect a Git repository and point the packager at `.pkgmeta`.
3. After the project is created, add your Curse project ID to `AudioProfiles.toc`:

   ```
   ## X-Curse-Project-ID: <your-id>
   ```

4. Paste this README (or a shortened variant) into the project description and attach `CHANGELOG.md` notes to the 1.0.0 file release.

## License

All rights reserved unless a separate license file is added by the author.
