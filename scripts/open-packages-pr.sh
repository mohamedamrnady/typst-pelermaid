#!/usr/bin/env bash
# Opens or updates a typst/packages PR from a staged package.
#
# Required environment:
#   TYPST_PACKAGES_TOKEN  classic PAT with public_repo scope (or equivalent)
# Optional environment:
#   PACKAGES_FORK_OWNER   defaults to the authenticated GitHub user
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

if [ "${DRY_RUN:-0}" = 1 ]; then
  printf 'would submit %s %s\n' "$name" "$version"
  printf 'from: %s\n' "$stage"
  printf 'to: %s:%s\n' "$fork" "$target"
  printf 'branch: %s\n' "$branch"
  printf 'pele: %s\n' "$pele_pin"
  printf 'pele.kbc1 sha256: %s\n' "$hash"
  exit 0
fi

export GH_TOKEN="$token"
gh auth setup-git
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
gh repo clone "$fork" "$tmp/fork" -- --filter=blob:none --quiet
repo="$tmp/fork"
cd "$repo"
git remote add upstream "https://github.com/$upstream.git"
git fetch --depth=1 upstream main

if git cat-file -e "upstream/main:$target" 2>/dev/null; then
  echo "already published upstream: $target"
  exit 0
fi

is_update=0
if git cat-file -e "upstream/main:packages/preview/$name" 2>/dev/null; then
  is_update=1
fi

pr_number="$(gh pr list --repo "$upstream" --head "$owner:$branch" --state all --json number,state --jq '.[0].number // empty')"
pr_state="$(gh pr list --repo "$upstream" --head "$owner:$branch" --state all --json number,state --jq '.[0].state // empty')"
if [ -n "$pr_number" ] && [ "$pr_state" != "OPEN" ]; then
  echo "error: PR #$pr_number for $branch is $pr_state; refusing to reopen or duplicate it" >&2
  exit 1
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

# Reuse the existing branch only when an open PR owns it. Always branch from
# current upstream main so unrelated history never appears in the PR.
git fetch origin "$branch" >/dev/null 2>&1 || true
if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
  git push --force-with-lease origin "$branch"
else
  git push origin "$branch"
fi

body="$tmp/pr-body.md"
if [ "$is_update" = 1 ]; then
  cat > "$body" <<EOF
I am submitting
- [ ] a new package
- [x] an update for a package

Description: Update Pelermaid to version \`$version\` using Pele \`$pele_pin\`.

Source: https://github.com/mohamedamrnady/typst-pelermaid

The submitted payload contains only package files. It was built from the pinned npm Pele
package and tested with the package checker before opening this PR.

- Package: \`$name:$version\`
- Pele: \`$pele_pin\`
- \`pele.kbc1\` SHA-256: \`$hash\`

Update the import to \`@preview/$name:$version\`.
EOF
else
  cat > "$body" <<EOF
I am submitting
- [x] a new package
- [ ] an update for a package

Description: Pelermaid renders Mermaid diagrams as SVG inside Typst using the
[Pele](https://github.com/obsidianmd/pele) renderer. It ships the Pele JavaScript
bundle as QuickJS bytecode and uses CtxJS for the JavaScript runtime.

I have read and followed the submission guidelines and, in particular, I
- [x] selected a name that isn't the most obvious or canonical name for what the package does
  - Explanation: \`pelermaid\` is a portmanteau of Mermaid and Pele, the specific renderer this package wraps. It is not the canonical \`mermaid\` name; Pele is credited in the README and third-party notices.
- [x] added a [\`typst.toml\`](https://github.com/typst/packages/blob/main/docs/manifest.md#package-metadata) file with all required keys
- [x] added a [\`README.md\`](https://github.com/typst/packages/blob/main/docs/documentation.md) with documentation for my package
- [x] have chosen [a license](https://github.com/typst/packages/blob/main/docs/licensing.md) and added a \`LICENSE\` file
- [x] tested my package locally on my system and it worked
- [x] [\`exclude\`d](https://github.com/typst/packages/blob/main/docs/tips.md#what-to-commit-what-to-exclude) PDFs or README images, if any, but not the LICENSE

Package metadata:
- Package: \`$name:$version\`
- Source: https://github.com/mohamedamrnady/typst-pelermaid
- Pele: \`$pele_pin\` (npm)
- CtxJS: \`0.5.0\`
- \`pele.kbc1\` SHA-256: \`$hash\`
- Staged package passed \`ghcr.io/typst/package-check:0.7.0\`.
EOF
fi

if [ -n "$pr_number" ]; then
  gh pr edit "$pr_number" --repo "$upstream" --title "$name:$version" --body-file "$body"
  echo "updated PR #$pr_number"
else
  gh pr create --repo "$upstream" --base main --head "$owner:$branch" \
    --title "$name:$version" --body-file "$body"
fi
