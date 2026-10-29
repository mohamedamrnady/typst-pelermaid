#!/usr/bin/env bash
# Runs the theme assertions and checks that an oversize `series` palette is rejected.
#
#   ./tests/theme.sh            # output goes to dist/theme/
#   ./tests/theme.sh /tmp/theme
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
out="${1:-$root/dist/theme}"

command -v typst >/dev/null 2>&1 || { echo "error: typst is not on PATH" >&2; exit 1; }

mkdir -p "$out"

typst compile --root "$root" "$root/tests/theme.typ" "$out/theme.pdf"

if typst compile --root "$root" "$root/tests/theme-invalid.typ" "$out/invalid.pdf" \
  >"$out/invalid.log" 2>&1; then
  echo "error: a nine-colour series palette compiled; it should panic" >&2
  exit 1
fi

if ! grep -q "at most 8 colors" "$out/invalid.log"; then
  echo "error: oversize series failed for the wrong reason:" >&2
  cat "$out/invalid.log" >&2
  exit 1
fi

rm -f "$out/invalid.log"
echo "theme checks passed"
