#!/usr/bin/env bash
# Installs this package for the Windows build of Typst when running under WSL.
#
# Typst reads local packages from %APPDATA%\typst\packages and caches downloaded packages in
# %LOCALAPPDATA%\typst\packages. Some editor integrations only scan the cache path, so install
# into both; the data directory still takes precedence in Typst itself.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
name="$(awk -F'"' '/^name[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"

if ! command -v powershell.exe >/dev/null 2>&1; then
  echo "error: powershell.exe not found; run this script from WSL with Windows interop enabled" >&2
  exit 1
fi

windows_dir() {
  local folder="$1"
  local path
  path="$(powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('$folder')" | tr -d '\r')"
  if [ -z "$path" ]; then
    echo "error: could not determine the Windows $folder directory" >&2
    exit 1
  fi
  wslpath -u "$path"
}

install_into() {
  local base="$1"
  local dest="$base/typst/packages/local/$name/$version"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp "$root/typst.toml" "$root/lib.typ" "$root/pele.kbc1" "$root/LICENSE" "$root/THIRD_PARTY_NOTICES.md" "$dest/"
  mkdir -p "$dest/LICENSES"
  cp "$root"/LICENSES/*.txt "$dest/LICENSES/"
  echo "installed $dest"
}

install_into "$(windows_dir ApplicationData)"
install_into "$(windows_dir LocalApplicationData)"
