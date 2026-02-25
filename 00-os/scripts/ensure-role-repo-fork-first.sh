#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ensure-role-repo-fork-first.sh [--allow-origin-owner-mismatch] [--expected-owner <owner>] [--repo <path>]

Options:
  --allow-origin-owner-mismatch   Allow origin owner to differ from expected owner
  --expected-owner <owner>        Expected GitHub owner for origin (default: Josh-Phillips-LLC)
  --repo <path>                   Target repository path (default: current directory)
  -h, --help                      Show this help

Behavior:
  - Applies repo-local fork-first settings for the active branch:
      remote.pushDefault=origin
      branch.<current>.pushRemote=origin
      remote.origin.gh-resolved=base
  - Fails preflight when origin owner does not match expected owner unless override is set.
  - Preserves upstream fetch but disables upstream push URL when upstream points to joshphillipssr/*.
EOF
}

EXPECTED_OWNER="Josh-Phillips-LLC"
ALLOW_OWNER_MISMATCH="false"
TARGET_REPO="."

while [ "$#" -gt 0 ]; do
  case "$1" in
    --allow-origin-owner-mismatch)
      ALLOW_OWNER_MISMATCH="true"
      shift
      ;;
    --expected-owner)
      if [ "$#" -lt 2 ]; then
        echo "❌ --expected-owner requires a value" >&2
        usage >&2
        exit 1
      fi
      EXPECTED_OWNER="$2"
      shift 2
      ;;
    --repo)
      if [ "$#" -lt 2 ]; then
        echo "❌ --repo requires a path" >&2
        usage >&2
        exit 1
      fi
      TARGET_REPO="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "❌ Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if ! command -v git >/dev/null 2>&1; then
  echo "❌ git is required but not found" >&2
  exit 1
fi

if [ ! -d "$TARGET_REPO" ]; then
  echo "❌ Repository path not found: $TARGET_REPO" >&2
  exit 1
fi

cd "$TARGET_REPO"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "❌ Not a git repository: $(pwd)" >&2
  exit 1
fi

current_branch="$(git branch --show-current)"
if [ -z "$current_branch" ]; then
  echo "❌ Detached HEAD is not supported for branch pushRemote preflight" >&2
  exit 1
fi

origin_url="$(git remote get-url origin 2>/dev/null || true)"
if [ -z "$origin_url" ]; then
  echo "❌ Remote 'origin' is required" >&2
  exit 1
fi

origin_owner=""
if printf '%s' "$origin_url" | grep -Eq '^https://github\.com/'; then
  origin_owner="$(printf '%s' "$origin_url" | sed -E 's#^https://github\.com/([^/]+)/.*$#\1#')"
elif printf '%s' "$origin_url" | grep -Eq '^git@github\.com:'; then
  origin_owner="$(printf '%s' "$origin_url" | sed -E 's#^git@github\.com:([^/]+)/.*$#\1#')"
fi

if [ -z "$origin_owner" ]; then
  echo "❌ Could not parse origin owner from URL: $origin_url" >&2
  exit 1
fi

echo "=== Fork-First Preflight (Role Repo) ==="
echo "Repository: $(pwd)"
echo "Current branch: $current_branch"
echo "Origin URL: $origin_url"
echo "Origin owner: $origin_owner"
echo "Expected owner: $EXPECTED_OWNER"

if [ "$origin_owner" != "$EXPECTED_OWNER" ] && [ "$ALLOW_OWNER_MISMATCH" != "true" ]; then
  echo "❌ Origin owner mismatch: expected '$EXPECTED_OWNER' but found '$origin_owner'" >&2
  echo "   Override with --allow-origin-owner-mismatch when explicitly intended." >&2
  exit 1
fi

git config --local remote.pushDefault origin
git config --local "branch.${current_branch}.pushRemote" origin
git config --local remote.origin.gh-resolved base

upstream_url="$(git remote get-url upstream 2>/dev/null || true)"
if [ -n "$upstream_url" ] && printf '%s' "$upstream_url" | grep -Eq 'github\.com[:/]joshphillipssr/'; then
  git remote set-url --push upstream DISABLED
  echo "Set upstream push URL to DISABLED (fetch URL preserved)."
fi

echo ""
echo "Applied repo-local settings:"
echo "  remote.pushDefault=$(git config --local --get remote.pushDefault)"
echo "  branch.${current_branch}.pushRemote=$(git config --local --get "branch.${current_branch}.pushRemote")"
echo "  remote.origin.gh-resolved=$(git config --local --get remote.origin.gh-resolved)"

if git remote get-url --push upstream >/dev/null 2>&1; then
  echo "  upstream.pushURL=$(git remote get-url --push upstream)"
else
  echo "  upstream.pushURL=(not set)"
fi

echo "✅ Fork-first preflight passed"
