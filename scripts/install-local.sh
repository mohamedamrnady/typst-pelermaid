#!/usr/bin/env bash
# Installs this package into Typst's local package namespace so documents can use:
#   #import "@local/pelermaid:<version>": mermaid
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
name="$(awk -F'"' '/^name[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
dest="${XDG_DATA_HOME:-$HOME/.local/share}/typst/packages/local/$name/$version"

rm -rf "$dest"
mkdir -p "$dest"
cp "$root/typst.toml" "$root/lib.typ" "$root/pele.kbc1" "$root/LICENSE" "$root/THIRD_PARTY_NOTICES.md" "$dest/"
mkdir -p "$dest/LICENSES"
cp "$root"/LICENSES/*.txt "$dest/LICENSES/"
echo "installed $dest"
