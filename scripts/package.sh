#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOC="${ROOT}/AudioProfiles.toc"
DIST="${ROOT}/dist"
STAGING="${DIST}/AudioProfiles"

if [[ ! -f "${TOC}" ]]; then
  echo "Missing ${TOC}" >&2
  exit 1
fi

VERSION="$(grep -E '^## Version:' "${TOC}" | sed -E 's/^## Version:[[:space:]]*//')"
if [[ -z "${VERSION}" ]]; then
  echo "Could not read version from ${TOC}" >&2
  exit 1
fi

ZIP_NAME="AudioProfiles-${VERSION}.zip"
ZIP_PATH="${DIST}/${ZIP_NAME}"

rm -rf "${STAGING}"
mkdir -p "${STAGING}"

INCLUDE=(
  "Addon.lua"
  "AudioProfiles.toc"
  "Bindings.xml"
  "Const.lua"
  "Content.lua"
  "ContentIndex.lua"
  "Data.lua"
  "Main.lua"
  "Profiles.lua"
  "Sound.lua"
  "UI.lua"
)

for file in "${INCLUDE[@]}"; do
  cp "${ROOT}/${file}" "${STAGING}/${file}"
done

mkdir -p "${DIST}"
rm -f "${ZIP_PATH}"

(
  cd "${DIST}"
  zip -rq "${ZIP_NAME}" "AudioProfiles"
)

rm -rf "${STAGING}"

echo "Created ${ZIP_PATH}"
echo "Version: ${VERSION}"
echo "Upload this zip to CurseForge (Manual upload) or tag v${VERSION} for Git packager."
