#!/usr/bin/env bash
# Builds the diagram gallery PDFs that are attached to GitHub releases:
#
#   corpus.pdf       runtime corpus, rendered through CtxJS
#   prerendered.pdf  corpus rendered by Pele's JavaScript bundle ahead of time
#   compare.pdf      both side by side, with a byte-equality summary
#
# The pre-rendered SVGs are build artifacts and are not committed. Use the output
# directory argument to choose where the PDFs go:
#
#   ./scripts/build-diagrams.sh            # artifacts/
#   ./scripts/build-diagrams.sh /tmp/pdfs
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
out="${1:-$root/artifacts}"

command -v bun >/dev/null 2>&1 || { echo "error: bun is not on PATH" >&2; exit 1; }
command -v typst >/dev/null 2>&1 || { echo "error: typst is not on PATH" >&2; exit 1; }
[ -f "$root/js/dist/pele.mjs" ] || {
  echo "error: js/dist/pele.mjs is missing; run ./scripts/build.sh first" >&2
  exit 1
}

mkdir -p "$out"

# Regenerate tests/prerendered/ from the current Pele bundle.
bun "$root/tests/prerender.mjs"

typst compile --root "$root" "$root/tests/prerendered.typ" "$out/prerendered.pdf"

# Fail the build rather than publish a comparison that documents a mismatch.
differing="$(typst eval \
  --root "$root" \
  'query(<comparison>).first().value.differing' \
  --in "$root/tests/compare.typ" \
  --format json)"
if [ "$differing" != "[]" ]; then
  echo "error: runtime and pre-rendered SVGs differ: $differing" >&2
  exit 1
fi

typst compile --root "$root" "$root/tests/compare.typ" "$out/compare.pdf"
typst compile --root "$root" "$root/tests/corpus.typ" "$out/corpus.pdf"

echo "wrote corpus.pdf, prerendered.pdf, and compare.pdf to $out"
