#!/usr/bin/env bash
# Syntax-check every addon file, then run the offline test suite.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LUA=""
for c in lua5.1 luajit lua; do
  if command -v "$c" >/dev/null 2>&1; then LUA="$c"; break; fi
done
if [[ -z "$LUA" ]]; then
  echo "error: need a Lua 5.1 interpreter (lua5.1, luajit, or lua)" >&2
  exit 1
fi

if command -v luac5.1 >/dev/null 2>&1; then
  for f in *.lua; do luac5.1 -p "$f"; done
  echo "syntax: ok ($(ls -1 *.lua | wc -l) files)"
else
  echo "syntax: skipped (luac5.1 not installed)"
fi

exec "$LUA" tests/content_spec.lua
