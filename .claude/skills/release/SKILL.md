---
name: release
description: Cut and publish a release of this addon - classify the changes since the last tag into a version bump, write the changelog entry, bump the .toc version, test, commit, tag, and push.
disable-model-invocation: true
---

Pushing the tag is the release: the CurseForge git packager builds from
`vX.Y.Z`, so a wrong version number or a changelog that misdescribes the
release is public the moment the tag lands, and the build cannot be
recalled. Every step before the push is reversible. The push is not.

## Scope

A release covers everything since the last tag, committed or not.
`git describe --tags --abbrev=0` names the baseline;
`git log <baseline>..HEAD` and `git status --porcelain` together are the
change set. Uncommitted work in the tree belongs to the release and gets
folded into the release commit.

## Repo facts

- The version lives in exactly one place: `## Version:` in
  `AudioProfiles.toc`. `scripts/package.sh` reads it from there.
- Releases land straight on `master`. No branch, no PR.
- Tags are annotated and named `vX.Y.Z`.
- `CHANGELOG.md` follows Keep a Changelog: newest section on top,
  `## [X.Y.Z] - YYYY-MM-DD`, `### Added` / `### Changed` / `### Fixed` /
  `### Removed`, and a `[X.Y.Z]: #` link reference at the bottom of the
  file.
- The changelog is shown to players on CurseForge. It only carries
  changes a player can see or feel in the game.
- `dist/` is gitignored and no zip is committed. `scripts/package.sh`
  exists only for a manual CurseForge upload when the git packager is
  not being used.
- Anything that must not ship to players belongs in the `.pkgmeta`
  ignore list. The packager ships every tracked path that is not listed.

## Version tier

Classify every change in the change set. The highest tier present wins.
An argument overrides the classification (`/release minor`).

- **major** — saved data or muscle memory breaks: a SavedVariables
  migration that discards or reinterprets existing settings, or a
  removed or renamed slash command, keybinding, or option.
- **minor** — the addon does something it could not do before: a new
  content category, command, option, profile capability, or UI surface.
- **patch** — everything else: bug fixes, performance, refactors, docs,
  tests, packaging, `## Interface` bumps.

Classify from the diff, not the commit subjects. A commit called a fix
that also adds a slash command is a minor.

## The ritual

1. **Preflight.** On `master`, and level with `origin/master` after a
   `git fetch` — a release cut on stale history pushes a merge or a
   rejection instead of a release.
2. **Read the change set.** `git log --stat <baseline>..HEAD` and the
   working tree diff. Every change is accounted for before moving on:
   each one either lands in the changelog or is consciously left out as
   invisible to players. Both the tier and the changelog come from this
   reading, so it is the step that carries the release.
3. **Pick the version** from the tier, applied to the current `.toc`
   version.
4. **Write the changelog.** Promote an existing `## [Unreleased]`
   heading to `## [X.Y.Z] - <today>` (`date +%F`) and fold in whatever
   the diff shows it is missing; with no Unreleased section, write the
   entry from the diff. Add the `[X.Y.Z]: #` link reference.

   The audience is a player skimming the CurseForge changelog tab:
   - One short sentence per `-` entry. Behaviour only — what changed for
     the player, not how, not why, no file names, no API names, no
     root-cause stories. The mechanism belongs in the commit body.
   - Internal work never appears: dev tooling, Claude skills, tests, CI,
     packaging, refactors, `## Interface` bumps, docs. It still counts
     for the version tier; it just is not changelog material.
5. **Bump `## Version:`** in `AudioProfiles.toc`, then
   `git grep -n "<old version>"` to catch stray references in the README
   or elsewhere.
6. **Test.** `./scripts/test.sh` — syntax check plus the offline suite.
   Green before anything is committed.
7. **Confirm.** Show the user the version, the one-line reason for that
   tier, and the changelog entry. One approval, and it covers the rest
   of the ritual. This is the last reversible moment.
8. **Commit.** Subject `Release X.Y.Z`, or `Release X.Y.Z: <summary>`
   when one line can name the change. The body is wrapped prose
   explaining why the change was needed.
9. **Tag.** `git tag -a vX.Y.Z` with a message summarizing the release.
10. **Push.** `git push origin master`, then `git push origin vX.Y.Z`.
    The tag push is what triggers the CurseForge build.

## When a step fails

- **Tests red**: stop before the commit, diagnose the root cause, fix
  forward, and restart from step 2 — the fix is part of the release.
- **Version already tagged**: the baseline was misread. Re-derive it and
  start over.
- **Push rejected**: origin has commits this release was not built on.
  Pull, re-run the tests, re-push.

## Guardrails

- A pushed tag stays where it is. CurseForge has already built it, so a
  mistake is corrected by cutting the next patch release.
- The tag goes out only after the tests are green and the changelog
  matches the diff.
- Publishing is the last step and it publishes exactly what was
  approved in step 7. Anything discovered after that approval is a new
  release, not an amendment to this one.
