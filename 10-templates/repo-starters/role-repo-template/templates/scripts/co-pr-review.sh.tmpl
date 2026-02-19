#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/co-pr-review.sh [--repo <owner/repo>] [--pr <number>|<number>] \
    (--approve|--request-changes|--comment) [--body <text>|--body-file <path>] \
    [--expected-login <login>]

Examples:
  scripts/co-pr-review.sh --repo Josh-Phillips-LLC/Context-Engineering --pr 176 --request-changes --body-file WIP/review.md
  scripts/co-pr-review.sh --pr 176 --approve --body "All governance checks pass."
  scripts/co-pr-review.sh 176 --comment --body-file WIP/note.md

Notes:
  - Runs all GitHub CLI calls with GH_TOKEN/GITHUB_TOKEN unset.
  - Submits a PR review event via `gh pr review` (never `gh pr comment`).
USAGE
}

repo=""
pr_number=""
mode=""
body=""
body_file=""
expected_login="a-complianceofficer[bot]"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --pr)
      pr_number="${2:-}"
      shift 2
      ;;
    --approve)
      if [[ -n "$mode" ]]; then
        echo "Error: choose exactly one mode: --approve, --request-changes, or --comment" >&2
        exit 1
      fi
      mode="approve"
      shift
      ;;
    --request-changes)
      if [[ -n "$mode" ]]; then
        echo "Error: choose exactly one mode: --approve, --request-changes, or --comment" >&2
        exit 1
      fi
      mode="request-changes"
      shift
      ;;
    --comment)
      if [[ -n "$mode" ]]; then
        echo "Error: choose exactly one mode: --approve, --request-changes, or --comment" >&2
        exit 1
      fi
      mode="comment"
      shift
      ;;
    --body)
      body="${2:-}"
      shift 2
      ;;
    --body-file)
      body_file="${2:-}"
      shift 2
      ;;
    --expected-login)
      expected_login="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "$pr_number" && "$1" =~ ^[0-9]+$ ]]; then
        pr_number="$1"
        shift
      else
        echo "Unknown argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$pr_number" ]]; then
  echo "Error: PR number is required (use --pr <number> or positional number)." >&2
  exit 1
fi

if [[ -z "$mode" ]]; then
  echo "Error: exactly one review mode is required: --approve, --request-changes, or --comment" >&2
  exit 1
fi

if [[ -n "$body" && -n "$body_file" ]]; then
  echo "Error: use either --body or --body-file, not both." >&2
  exit 1
fi

if [[ -n "$body_file" && ! -f "$body_file" ]]; then
  echo "Error: body file not found: $body_file" >&2
  exit 1
fi

gh_safe() {
  env -u GH_TOKEN -u GITHUB_TOKEN gh "$@"
}

gh_args=()
if [[ -n "$repo" ]]; then
  gh_args+=( -R "$repo" )
fi

viewer_login="$(gh_safe api graphql -f query='query { viewer { login } }' --jq '.data.viewer.login')"
expected_login_base="${expected_login%[bot]}"
expected_login_base="${expected_login_base% }"

if [[ "$viewer_login" != "$expected_login" && "$viewer_login" != "$expected_login_base" ]]; then
  echo "Error: identity mismatch. Expected '$expected_login' (or '$expected_login_base'), got '$viewer_login'." >&2
  exit 1
fi

pre_reviews_json="$(gh_safe pr view "$pr_number" "${gh_args[@]}" --json reviews)"
pre_count="$(printf '%s' "$pre_reviews_json" | jq '.reviews | length')"

review_args=(pr review "$pr_number" "${gh_args[@]}")
expected_state=""
case "$mode" in
  approve)
    review_args+=(--approve)
    expected_state="APPROVED"
    ;;
  request-changes)
    review_args+=(--request-changes)
    expected_state="CHANGES_REQUESTED"
    ;;
  comment)
    expected_state="COMMENTED"
    ;;
esac

if [[ -n "$body_file" ]]; then
  review_args+=(--body-file "$body_file")
elif [[ -n "$body" ]]; then
  review_args+=(--body "$body")
fi

gh_safe "${review_args[@]}" >/dev/null

post_reviews_json="$(gh_safe pr view "$pr_number" "${gh_args[@]}" --json reviews)"

new_review_json="$(
  printf '%s' "$post_reviews_json" \
  | jq -c --argjson pre "$pre_count" '.reviews[$pre:] | sort_by(.submittedAt) | last // empty'
)"

if [[ -z "$new_review_json" ]]; then
  echo "Error: verification failed. No new review detected after submission." >&2
  exit 1
fi

new_author="$(printf '%s' "$new_review_json" | jq -r '.author.login')"
new_state="$(printf '%s' "$new_review_json" | jq -r '.state')"
new_submitted_at="$(printf '%s' "$new_review_json" | jq -r '.submittedAt')"

if [[ "$new_author" != "$expected_login" && "$new_author" != "$expected_login_base" ]]; then
  echo "Error: verification failed. Expected review author '$expected_login' (or '$expected_login_base'), got '$new_author'." >&2
  exit 1
fi

if [[ "$new_state" != "$expected_state" ]]; then
  echo "Error: verification failed. Expected review state '$expected_state', got '$new_state'." >&2
  exit 1
fi

echo "Review submitted successfully."
echo "  PR: $pr_number"
if [[ -n "$repo" ]]; then
  echo "  Repo: $repo"
fi
echo "  Reviewer: $new_author"
echo "  State: $new_state"
echo "  Submitted: $new_submitted_at"
