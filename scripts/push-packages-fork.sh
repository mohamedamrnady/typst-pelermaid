#!/usr/bin/env bash
# Pushes a staged package to the user's typst/packages fork as a branch. It does not open
# the pull request; the printed compare URL can be used for that.
#
# Required environment:
#   TYPST_PACKAGES_TOKEN  token that can read and write contents on the fork. A fine-grained
#                         PAT with Contents: read/write on the fork is enough. Store it as a
#                         secret on the `release` environment in the source repository.
# Optional environment:
#   PACKAGES_FORK_OWNER   defaults to the authenticated GitHub user. The account must
#                         already have a fork named `packages`.
#   PACKAGES_UPSTREAM     defaults to typst/packages
#   DRY_RUN=1             validate and print the intended action, no network writes
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/.." && pwd)"
name="$(awk -F'"' '/^name[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
version="$(awk -F'"' '/^version[[:space:]]*=/ { print $2; exit }' "$root/typst.toml")"
stage="${1:-$root/dist/packages/preview/$name/$version}"
upstream="${PACKAGES_UPSTREAM:-typst/packages}"
target="packages/preview/$name/$version"

[ -d "$stage" ] || { echo "error: staged package not found at $stage" >&2; exit 1; }
[ -f "$stage/typst.toml" ] || { echo "error: staged package has no typst.toml" >&2; exit 1; }

token="${TYPST_PACKAGES_TOKEN:-${GH_TOKEN:-}}"
if [ -z "$token" ] && [ "${DRY_RUN:-0}" != 1 ]; then
  echo "error: TYPST_PACKAGES_TOKEN is not set" >&2
  exit 1
fi

if [ -n "${PACKAGES_FORK_OWNER:-}" ]; then
  owner="$PACKAGES_FORK_OWNER"
elif [ "${DRY_RUN:-0}" = 1 ]; then
  owner="mohamedamrnady"
else
  owner="$(GH_TOKEN="$token" gh api user --jq .login)"
fi
fork="$owner/packages"
branch="$name-v$version"
pele_pin="$(sed -n 's/.*"pele"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$root/js/package.json" | head -n 1)"
hash="$(sha256sum "$stage/pele.kbc1" | awk '{print $1}')"
compare_url="https://github.com/$upstream/compare/main...$owner:$branch?expand=1"

if [ "${DRY_RUN:-0}" = 1 ]; then
  printf 'would push %s %s\n' "$name" "$version"
  printf 'from: %s\n' "$stage"
  printf 'to: %s:%s\n' "$fork" "$target"
  printf 'branch: %s\n' "$branch"
  printf 'pele: %s\n' "$pele_pin"
  printf 'pele.kbc1 sha256: %s\n' "$hash"
  printf 'open the PR at: %s\n' "$compare_url"
  exit 0
fi

export GH_TOKEN="$token"
gh auth setup-git
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gh repo clone "$fork" "$tmp/fork" -- --filter=blob:none --no-tags --quiet
repo="$tmp/fork"
cd "$repo"
upstream_url="https://github.com/$upstream.git"
if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream "$upstream_url"
else
  git remote add upstream "$upstream_url"
fi
git fetch --depth=1 --filter=blob:none upstream main

if git cat-file -e "upstream/main:$target" 2>/dev/null; then
  echo "already published upstream: $target"
  exit 0
fi

git switch -c "$branch" upstream/main >/dev/null 2>&1 || git switch -C "$branch" upstream/main
mkdir -p "$(dirname "$target")"
rm -rf "$target"
cp -a "$stage" "$target"
git add -- "$target"
if git diff --cached --quiet; then
  echo "no staged changes to submit"
  exit 0
fi
git -c user.name="$owner" -c user.email="$owner@users.noreply.github.com" \
  commit -m "$name: $version"

# Always branch from current upstream main so unrelated history never appears in the PR.
git fetch origin "$branch" >/dev/null 2>&1 || true
if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  git push --force-with-lease origin "$branch"
else
  git push origin "$branch"
fi

printf 'pushed %s to %s\n' "$branch" "$fork"
printf 'open the PR at: %s\n' "$compare_url"
