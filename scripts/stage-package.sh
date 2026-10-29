#!/usr/bin/env bash
# Stages exactly the files that are submitted to typst/packages.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
stage_root="${STAGE_ROOT:-$root/dist}"

name="$(awk -F'"' '/^name[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
[ -n "$name" ] || { echo "error: package name missing from typst.toml" >&2; exit 1; }
[ -n "$version" ] || { echo "error: package version missing from typst.toml" >&2; exit 1; }

stage="$stage_root/packages/preview/$name/$version"
rm -rf "$stage_root"
mkdir -p "$stage"

files=(
  typst.toml
  lib.typ
  pele.kbc1
  README.md
  LICENSE
  THIRD_PARTY_NOTICES.md
  CHANGELOG.md
  sample.typ
  LICENSES/PELE-MIT.txt
  LICENSES/LUCIDE-ISC.txt
  LICENSES/CTXJS-MIT.txt
)
examples=(
  examples/basic.typ
  examples/options.typ
)

for file in "${files[@]}"; do
  [ -f "$root/$file" ] || { echo "error: missing package file: $file" >&2; exit 1; }
  if [[ "$file" == LICENSES/* ]]; then
    mkdir -p "$stage/LICENSES"
    cp "$root/$file" "$stage/LICENSES/"
  else
    cp "$root/$file" "$stage/"
  fi
done
mkdir -p "$stage/examples"
for file in "${examples[@]}"; do
  [ -f "$root/$file" ] || { echo "error: missing example: $file" >&2; exit 1; }
  cp "$root/$file" "$stage/examples/"
done

# The submission must not contain build tooling, test files, dotfiles, or a
# nested package/submodule. Fail loudly if the staging layout ever changes.
if find "$stage" -mindepth 1 -name '.*' -print -quit | grep -q .; then
  echo "error: staged package contains a dotfile" >&2
  exit 1
fi
for forbidden in js node_modules vendor .github scripts tests; do
  [ ! -e "$stage/$forbidden" ] || { echo "error: staged package contains $forbidden" >&2; exit 1; }
done

printf 'staged package: %s\n' "$stage"
sha256sum "$stage/pele.kbc1"
