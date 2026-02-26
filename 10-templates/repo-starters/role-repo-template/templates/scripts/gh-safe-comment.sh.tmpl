#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/gh-safe-comment.sh --repo <owner/repo> (--pr <number> | --issue <number>) --body-file <path> [--allow-closed]

Examples:
  scripts/gh-safe-comment.sh --repo Josh-Phillips-LLC/Context-Engineering --pr 120 --body-file WIP/review.md
  scripts/gh-safe-comment.sh --repo Josh-Phillips-LLC/Context-Engineering --issue 17 --body-file WIP/update.md
USAGE
}

repo=""
pr_number=""
issue_number=""
body_file=""
allow_closed="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --pr)
      pr_number="${2:-}"
      shift 2
      ;;
    --issue)
      issue_number="${2:-}"
      shift 2
      ;;
    --body-file)
      body_file="${2:-}"
      shift 2
      ;;
    --allow-closed)
      allow_closed="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$repo" ] || [ -z "$body_file" ]; then
  echo "Missing required --repo or --body-file" >&2
  usage
  exit 1
fi

if [ -n "$pr_number" ] && [ -n "$issue_number" ]; then
  echo "Use exactly one of --pr or --issue" >&2
  exit 1
fi

if [ -z "$pr_number" ] && [ -z "$issue_number" ]; then
  echo "Provide --pr <number> or --issue <number>" >&2
  exit 1
fi

if [ ! -f "$body_file" ]; then
  echo "Body file not found: $body_file" >&2
  exit 1
fi

if [ -n "$pr_number" ]; then
  state="$(gh pr view "$pr_number" -R "$repo" --json state --jq '.state')"
  if [ "$allow_closed" != "true" ] && [ "$state" != "OPEN" ]; then
    echo "Refusing to comment: PR #$pr_number is $state (use --allow-closed to override)." >&2
    exit 1
  fi
  gh pr comment "$pr_number" -R "$repo" --body-file "$body_file"
  exit 0
fi

state="$(gh issue view "$issue_number" -R "$repo" --json state --jq '.state')"
if [ "$allow_closed" != "true" ] && [ "$state" != "OPEN" ]; then
  echo "Refusing to comment: issue #$issue_number is $state (use --allow-closed to override)." >&2
  exit 1
fi
gh issue comment "$issue_number" -R "$repo" --body-file "$body_file"
