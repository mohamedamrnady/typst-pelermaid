#!/usr/bin/env bash
# Runs the official Typst package checker against a staged package.
#
# The checker resolves @preview dependencies from a local clone of
# typst/packages, so this script supplies a sparse clone containing CtxJS.
# Network-only lints are disabled by default because the source repository may
# still be private while fixing the first release; typst/packages CI performs
# the public repository check after submission.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
stage_root="${STAGE_ROOT:-$root/dist}"
cache="${TYPST_PACKAGES_CACHE:-$root/.cache/typst-packages}"

name="$(awk -F'"' '/^name[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
stage="$stage_root/packages/preview/$name/$version"

[ -d "$stage" ] || { echo "error: staged package missing; run scripts/stage-package.sh first" >&2; exit 1; }

if [ ! -d "$cache/.git" ]; then
  rm -rf "$cache"
  git clone --depth 1 --filter=blob:none --sparse https://github.com/typst/packages.git "$cache"
  git -C "$cache" sparse-checkout set packages/preview/ctxjs
fi

rm -rf "$cache/packages/preview/$name/$version"
mkdir -p "$cache/packages/preview/$name"
cp -a "$stage" "$cache/packages/preview/$name/$version"

image="${PACKAGE_CHECK_IMAGE:-ghcr.io/typst/package-check:0.7.0}"
args=()
if [ "${PACKAGE_CHECK_ONLINE:-0}" != 1 ]; then
  args+=(--offline)
fi
docker run --rm -w /data/packages -v "$cache:/data" "$image" check "${args[@]}" "@preview/$name:$version"
