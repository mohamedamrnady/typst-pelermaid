#!/usr/bin/env bash
# Validates the release version and the user-facing package metadata.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
name="$(awk -F'"' '/^name[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"

[ -n "$name" ] || { echo "error: package name missing" >&2; exit 1; }
[ -n "$version" ] || { echo "error: package version missing" >&2; exit 1; }

if [[ -n "${GITHUB_REF_NAME:-}" && "${GITHUB_REF_NAME}" == v* ]]; then
  [ "${GITHUB_REF_NAME#v}" = "$version" ] || {
    echo "error: tag ${GITHUB_REF_NAME} does not match typst.toml version $version" >&2
    exit 1
  }
fi
if [[ -n "${RELEASE_VERSION:-}" ]]; then
  [ "$RELEASE_VERSION" = "$version" ] || {
    echo "error: requested version $RELEASE_VERSION does not match typst.toml version $version" >&2
    exit 1
  }
fi

grep -Fq "@preview/$name:$version" "$root/README.md" || {
  echo "error: README does not import @preview/$name:$version" >&2
  exit 1
}
if compgen -G "$root/examples/*.typ" >/dev/null; then
  for file in "$root"/examples/*.typ; do
    grep -Fq "@preview/$name:$version" "$file" || {
      echo "error: $file does not import @preview/$name:$version" >&2
      exit 1
    }
  done
fi

grep -Fq "## $version" "$root/CHANGELOG.md" || {
  echo "error: CHANGELOG.md has no section for $version" >&2
  exit 1
}

[ -s "$root/pele.kbc1" ] || { echo "error: pele.kbc1 is missing or empty" >&2; exit 1; }
[ -s "$root/THIRD_PARTY_NOTICES.md" ] || { echo "error: THIRD_PARTY_NOTICES.md is missing" >&2; exit 1; }
[ -f "$root/LICENSE" ] || { echo "error: LICENSE is missing" >&2; exit 1; }
for file in LICENSES/PELE-MIT.txt LICENSES/LUCIDE-ISC.txt LICENSES/CTXJS-MIT.txt; do
  [ -s "$root/$file" ] || { echo "error: $file is missing" >&2; exit 1; }
done

pele_pin="$(sed -n 's/.*"pele"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$root/js/package.json" | head -n 1)"
[ -n "$pele_pin" ] || { echo "error: pele dependency is not pinned in js/package.json" >&2; exit 1; }
case "$pele_pin" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "error: pele dependency must be an exact version, got '$pele_pin'" >&2; exit 1 ;;
esac

if grep -RIn --exclude=pele.kbc1 --exclude-dir=.git '@local/' "$root/typst.toml" "$root/lib.typ" "$root/README.md"; then
  echo "error: published package files still contain @local imports" >&2
  exit 1
fi

printf 'release metadata OK: %s %s (Pele %s)\n' "$name" "$version" "$pele_pin"
