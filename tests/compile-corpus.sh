#!/usr/bin/env bash
# Compiles every corpus diagram in isolation, so a broken family is easy to spot.
# The corpus PDFs attached to releases are built by scripts/build-diagrams.sh.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
out="${1:-$root/dist/corpus-pdfs}"

command -v typst >/dev/null 2>&1 || { echo "error: typst is not on PATH" >&2; exit 1; }

mkdir -p "$out"
status=0
while IFS= read -r file; do
  rel="/${file#"$root"/}"
  name="$(basename "$file" .mmd)"
  case "$rel" in
    */real-world/*) name="real-world-$name" ;;
  esac
  if ! typst compile --root "$root" --input "file=$rel" "$root/tests/corpus-one.typ" "$out/$name.pdf"; then
    echo "FAILED: $rel" >&2
    status=1
  fi
done < <(find "$root/tests/corpus" -name '*.mmd' | sort)

if [ "$status" -ne 0 ]; then
  echo "one or more corpus diagrams failed to compile" >&2
  exit "$status"
fi
echo "compiled $(find "$out" -name '*.pdf' | wc -l) corpus diagrams into $out"
