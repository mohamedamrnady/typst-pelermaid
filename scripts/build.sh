#!/usr/bin/env bash
# Rebuilds js/dist/pele.mjs and pele.kbc1 from the pinned Pele npm package.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
cache="$root/.cache/ctxjs"
builder="${CTXJS_BUILDER:-$cache/target/release/ctxjs_module_bytecode_builder}"
ctxjs_repo="${CTXJS_REPO:-https://github.com/lublak/typst-ctxjs-package.git}"
ctxjs_commit="${CTXJS_COMMIT:-c4c270035bac9a825564ca1257735c704ec8988a}"

(
  cd "$root/js"
  bun install --frozen-lockfile
  bun run build
)

if [ ! -x "$builder" ]; then
  # A cargo config on this machine may point `build.rustc-wrapper` at a compiler
  # cache that is not installed (for example kache). Cargo fails before invoking
  # rustc in that case, so drop the wrapper only when its binary is missing. An
  # explicitly configured, working wrapper is preserved. Cargo reads config from
  # `$CARGO_HOME` and from every `.cargo` directory between the working directory
  # and the filesystem root; ancestor configs matter because this checkout can
  # live under a Windows user profile that carries one.
  wrapper=""
  dir="$cache"
  while [ -n "$dir" ]; do
    for config in "$dir/.cargo/config.toml" "$dir/.cargo/config"; do
      if [ -f "$config" ]; then
        found="$(sed -n 's/^[[:space:]]*rustc-wrapper[[:space:]]*=[[:space:]]*"\(.*\)"/\1/p' "$config" | head -n 1)"
        if [ -n "$found" ]; then wrapper="$found"; fi
      fi
    done
    [ "$dir" = "/" ] && break
    dir="$(dirname "$dir")"
  done
  for config in "${CARGO_HOME:-$HOME/.cargo}/config.toml" "${CARGO_HOME:-$HOME/.cargo}/config"; do
    if [ -f "$config" ]; then
      found="$(sed -n 's/^[[:space:]]*rustc-wrapper[[:space:]]*=[[:space:]]*"\(.*\)"/\1/p' "$config" | head -n 1)"
      if [ -n "$found" ]; then wrapper="$found"; fi
    fi
  done
  if [ -n "$wrapper" ] && ! command -v "$wrapper" >/dev/null 2>&1; then
    echo "warning: rustc-wrapper '$wrapper' is not installed; building without it" >&2
    export CARGO_BUILD_RUSTC_WRAPPER=
  fi

  if [ ! -f "$cache/Cargo.toml" ]; then
    mkdir -p "$cache"
    git clone --filter=blob:none --no-checkout "$ctxjs_repo" "$cache"
  fi
  (
    cd "$cache"
    git fetch --depth 1 origin "$ctxjs_commit"
    git checkout --detach FETCH_HEAD
    # The pinned CtxJS revision does not ship a lock file, so `--locked` can
    # only be used once one has been generated.
    if [ -f Cargo.lock ]; then locked=--locked; else locked=; fi
    cargo build --release $locked --bin ctxjs_module_bytecode_builder
  )
fi

"$builder" pele "$root/js/dist/pele.mjs" "$root/pele.kbc1"
echo "wrote $root/pele.kbc1"
