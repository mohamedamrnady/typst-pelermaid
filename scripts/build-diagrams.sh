#!/usr/bin/env bash
# Builds the diagram gallery PDF attached to GitHub releases.
#
#   ./scripts/build-diagrams.sh            # writes artifacts/corpus.pdf
#   ./scripts/build-diagrams.sh /tmp/pdfs
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
out="${1:-$root/artifacts}"

command -v typst >/dev/null 2>&1 || { echo "error: typst is not on PATH" >&2; exit 1; }

mkdir -p "$out"
typst compile --root "$root" "$root/tests/corpus.typ" "$out/corpus.pdf"
echo "wrote $out/corpus.pdf"
