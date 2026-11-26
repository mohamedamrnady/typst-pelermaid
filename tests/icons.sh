#!/usr/bin/env bash
# Runs the icon assertions and checks that a malformed `icons` dictionary is rejected.
#
#   ./tests/icons.sh            # output goes to dist/icons/
#   ./tests/icons.sh /tmp/icons
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
out="${1:-$root/dist/icons}"

command -v typst >/dev/null 2>&1 || { echo "error: typst is not on PATH" >&2; exit 1; }

mkdir -p "$out"

typst compile --root "$root" "$root/tests/icons.typ" "$out/icons.pdf"
typst compile --root "$root" "$root/tests/icons-demo.typ" "$out/icons-demo.pdf"

# `icons` must be a dictionary, not a string.
printf '%s\n' \
  '#import "/lib.typ": mermaid-svg' \
  '#mermaid-svg("flowchart LR\n    a@{ icon: \"fa:user\", form: \"square\" }", icons: "nope")' \
  >"$out/invalid-type.typ"
if typst compile --root "$root" "$out/invalid-type.typ" "$out/invalid-type.pdf" \
  >"$out/invalid-type.log" 2>&1; then
  echo "error: a string icons option compiled; it should panic" >&2
  exit 1
fi
if ! grep -q "icons must be a dictionary" "$out/invalid-type.log"; then
  echo "error: invalid icons type failed for the wrong reason:" >&2
  cat "$out/invalid-type.log" >&2
  exit 1
fi

# Each icon value must be SVG markup as a string.
printf '%s\n' \
  '#import "/lib.typ": mermaid-svg' \
  '#mermaid-svg("flowchart LR\n    a@{ icon: \"fa:user\", form: \"square\" }", icons: ("fa:user": 3))' \
  >"$out/invalid-value.typ"
if typst compile --root "$root" "$out/invalid-value.typ" "$out/invalid-value.pdf" \
  >"$out/invalid-value.log" 2>&1; then
  echo "error: a non-string icon value compiled; it should panic" >&2
  exit 1
fi
if ! grep -q "must be a string of SVG markup" "$out/invalid-value.log"; then
  echo "error: invalid icon value failed for the wrong reason:" >&2
  cat "$out/invalid-value.log" >&2
  exit 1
fi

rm -f "$out"/invalid-*.log
echo "icon checks passed"
