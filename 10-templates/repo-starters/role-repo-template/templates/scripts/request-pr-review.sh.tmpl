#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/request-pr-review.sh --repo <owner/repo> --pr <number> --reviewer <login>

Example:
  scripts/request-pr-review.sh --repo Josh-Phillips-LLC/Context-Engineering --pr 120 --reviewer joshphillipssr
USAGE
}

repo=""
pr_number=""
reviewer=""

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
    --reviewer)
      reviewer="${2:-}"
      shift 2
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

if [ -z "$repo" ] || [ -z "$pr_number" ] || [ -z "$reviewer" ]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

if [ "$reviewer" = "Josh-Phillips-LLC" ]; then
  echo "Invalid reviewer login: organization handle is not a valid reviewer." >&2
  exit 1
fi

if ! gh api "repos/${repo}/collaborators/${reviewer}" >/dev/null 2>&1; then
  echo "Reviewer '$reviewer' is not a collaborator on $repo." >&2
  echo "Sample valid collaborators:" >&2
  gh api "repos/${repo}/collaborators?per_page=100" --jq '.[].login' | sed -n '1,20p' >&2 || true
  exit 1
fi

gh pr edit "$pr_number" -R "$repo" --add-reviewer "$reviewer"
echo "Requested review from '$reviewer' on PR #$pr_number in $repo"
