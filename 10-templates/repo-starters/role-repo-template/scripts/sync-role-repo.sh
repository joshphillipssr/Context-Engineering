#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  sync-role-repo.sh \
    --role-slug <role-slug> \
    --owner <github-owner> \
    [--repo-name <repo-name>] \
    [--role-name <role-name>] \
    [--base-branch <base-branch>] \
    [--source-ref <source-ref>] \
    [--work-dir <work-dir>] \
    [--sync-branch <sync-branch>] \
    [--pr-title <pr-title>] \
    [--auto-merge] \
    [--preflight-only] \
    [--skip-preflight] \
    [--no-pr] \
    [--dry-run]

Required:
  --role-slug     Role slug (for example: implementation-specialist)
  --owner         GitHub owner (organization or user)

Optional:
  --repo-name     Defaults to: context-engineering-role-<role-slug>
  --role-name     Optional display name override
  --base-branch   Defaults to: main
  --source-ref    Defaults to current git short SHA in source repo
  --work-dir      Temporary workspace root
  --sync-branch   Defaults to: sync/role-repo/<role-slug>
  --pr-title      Defaults to role sync title
  --auto-merge    Best-effort request GitHub auto-merge on the sync PR
  --preflight-only Run publishability preflight and exit without syncing
  --skip-preflight Skip publishability preflight checks
  --no-pr         Sync branch only, do not create/update PR
  --dry-run       Do everything except git push / PR write

Notes:
  - Requires gh + git + python3
  - Requires authenticated gh session with write access to target role repo
  - Managed files synced into target role repo root:
    - AGENTS.md
    - README.md
    - .github/copilot-instructions.md
    - .github/pull_request_template.md
    - .github/workflows/governance-pr-gates.yml
    - .vscode/settings.json
    - scripts/bootstrap-governance-labels.sh
    - scripts/gh-safe-comment.sh
    - scripts/request-pr-review.sh
    - scripts/validate-pr-metadata.py
    - handbook/README.md
    - handbook/sops/README.md
    - handbook/sops/general-process-improvement-loop.md
    - handbook/runbooks/README.md
    - handbook/runbooks/general-governance-label-bootstrap.md
    - handbook/runbooks/general-github-commenting.md
    - handbook/runbooks/general-reviewer-request-preflight.md
    - handbook/templates/README.md
    - handbook/templates/general-efficiency-opportunity.md
    - handbook/references/README.md
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDER_SCRIPT="${SCRIPT_DIR}/render-role-repo-template.sh"

ROLE_SLUG=""
ROLE_NAME=""
OWNER=""
REPO_NAME=""
BASE_BRANCH="main"
SOURCE_REF=""
WORK_DIR=""
SYNC_BRANCH=""
PR_TITLE=""
CREATE_PR="true"
DRY_RUN="false"
AUTO_MERGE="false"
PREFLIGHT_ONLY="false"
SKIP_PREFLIGHT="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --role-slug)
      ROLE_SLUG="$2"
      shift 2
      ;;
    --role-name)
      ROLE_NAME="$2"
      shift 2
      ;;
    --owner)
      OWNER="$2"
      shift 2
      ;;
    --repo-name)
      REPO_NAME="$2"
      shift 2
      ;;
    --base-branch)
      BASE_BRANCH="$2"
      shift 2
      ;;
    --source-ref)
      SOURCE_REF="$2"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="$2"
      shift 2
      ;;
    --sync-branch)
      SYNC_BRANCH="$2"
      shift 2
      ;;
    --pr-title)
      PR_TITLE="$2"
      shift 2
      ;;
    --auto-merge)
      AUTO_MERGE="true"
      shift
      ;;
    --preflight-only)
      PREFLIGHT_ONLY="true"
      shift
      ;;
    --skip-preflight)
      SKIP_PREFLIGHT="true"
      shift
      ;;
    --no-pr)
      CREATE_PR="false"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
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

if [ -z "$ROLE_SLUG" ] || [ -z "$OWNER" ]; then
  echo "Missing required args: --role-slug and --owner" >&2
  usage
  exit 1
fi

if [ ! -x "$RENDER_SCRIPT" ]; then
  echo "Renderer script not found or not executable: $RENDER_SCRIPT" >&2
  exit 1
fi

for cmd in gh git python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

managed_files=(
  "AGENTS.md"
  "README.md"
  ".github/copilot-instructions.md"
  ".github/pull_request_template.md"
  ".github/workflows/governance-pr-gates.yml"
  ".vscode/settings.json"
  "scripts/bootstrap-governance-labels.sh"
  "scripts/gh-safe-comment.sh"
  "scripts/request-pr-review.sh"
  "scripts/validate-pr-metadata.py"
  "handbook/README.md"
  "handbook/sops/README.md"
  "handbook/sops/general-process-improvement-loop.md"
  "handbook/runbooks/README.md"
  "handbook/runbooks/general-governance-label-bootstrap.md"
  "handbook/runbooks/general-github-commenting.md"
  "handbook/runbooks/general-reviewer-request-preflight.md"
  "handbook/templates/README.md"
  "handbook/templates/general-efficiency-opportunity.md"
  "handbook/references/README.md"
)

if [ "$ROLE_SLUG" = "compliance-officer" ]; then
  managed_files+=(
    "scripts/co-pr-review.sh"
    "scripts/co-pr-review-report.sh"
    "handbook/runbooks/compliance-pr-review-wrapper.md"
    "handbook/runbooks/compliance-rereview-after-changes.md"
    "handbook/templates/compliance-pr-review-report.md"
  )
fi

run_publishability_preflight() {
  local target_dir="$1"
  local -a scan_paths=()
  local -a missing=()
  local -a patterns=(
    "BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE KEY"
    "ghp_[A-Za-z0-9]{36}"
    "github_pat_[A-Za-z0-9_]{50,}"
    "ghs_[A-Za-z0-9]{36}"
    "ghu_[A-Za-z0-9]{36}"
    "xoxb-[0-9A-Za-z-]{10,}"
    "sk-[A-Za-z0-9_-]{20,}"
    "sk_[A-Za-z0-9_-]{20,}"
    "AKIA[0-9A-Z]{16}"
    "ASIA[0-9A-Z]{16}"
    "\\b10\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\b"
    "\\b192\\.168\\.[0-9]{1,3}\\.[0-9]{1,3}\\b"
    "\\b172\\.(1[6-9]|2[0-9]|3[0-1])\\.[0-9]{1,3}\\.[0-9]{1,3}\\b"
    "\\.internal\\b"
    "\\.corp\\b"
    "\\.lan\\b"
    "\\.local\\b"
  )

  for file in "${managed_files[@]}"; do
    if [ -f "${target_dir}/${file}" ]; then
      scan_paths+=("${target_dir}/${file}")
    else
      missing+=("${file}")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Publishability preflight failed: missing expected files in ${target_dir}." >&2
    printf '%s\n' "Missing: ${missing[*]}" >&2
    exit 1
  fi

  local violations="false"
  local matches=""
  for pattern in "${patterns[@]}"; do
    matches="$(grep -REn -e "$pattern" "${scan_paths[@]}" || true)"
    if [ -n "$matches" ]; then
      echo "Publishability preflight failed. Disallowed pattern detected: $pattern" >&2
      echo "$matches" >&2
      violations="true"
    fi
  done

  if [ "$violations" = "true" ]; then
    echo "Resolve the flagged content before syncing the role repository." >&2
    exit 1
  fi
}

if [ -z "${GH_TOKEN:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  export GH_TOKEN="$GITHUB_TOKEN"
fi

if [ -z "${GH_TOKEN:-}" ] && [ -z "${GITHUB_TOKEN:-}" ]; then
  if ! gh auth status --hostname github.com >/dev/null 2>&1; then
    echo "GitHub CLI not authenticated. Run: gh auth login" >&2
    exit 1
  fi
fi

if [ -z "$REPO_NAME" ]; then
  REPO_NAME="context-engineering-role-${ROLE_SLUG}"
fi

if [ -z "$SYNC_BRANCH" ]; then
  SYNC_BRANCH="sync/role-repo/${ROLE_SLUG}"
fi

if [ -z "$PR_TITLE" ]; then
  PR_TITLE="Implementation Specialist: Sync role repo job description for ${ROLE_SLUG}"
fi

FULL_REPO="${OWNER}/${REPO_NAME}"

if [ -z "$SOURCE_REF" ]; then
  if git -C "${SCRIPT_DIR}/../../../.." rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    SOURCE_REF="$(git -C "${SCRIPT_DIR}/../../../.." rev-parse --short HEAD)"
  else
    SOURCE_REF="unknown"
  fi
fi

if ! gh repo view "$FULL_REPO" >/dev/null 2>&1; then
  echo "Target repo does not exist or is inaccessible: $FULL_REPO" >&2
  exit 1
fi

if [ -z "$WORK_DIR" ]; then
  WORK_DIR="$(mktemp -d "/tmp/${REPO_NAME}-sync-XXXXXX")"
fi

RENDER_DIR="${WORK_DIR}/rendered"
TARGET_DIR="${WORK_DIR}/target"

mkdir -p "$RENDER_DIR" "$TARGET_DIR"

render_args=(
  --role-slug "$ROLE_SLUG"
  --repo-name "$REPO_NAME"
  --output-dir "$RENDER_DIR"
  --source-ref "$SOURCE_REF"
)

if [ -n "$ROLE_NAME" ]; then
  render_args+=(--role-name "$ROLE_NAME")
fi

"$RENDER_SCRIPT" "${render_args[@]}" >/dev/null

if [ "$SKIP_PREFLIGHT" != "true" ]; then
  run_publishability_preflight "$RENDER_DIR"
fi

if [ "$PREFLIGHT_ONLY" = "true" ]; then
  echo "Publishability preflight succeeded for ${ROLE_SLUG}."
  exit 0
fi

git clone "https://github.com/${FULL_REPO}.git" "$TARGET_DIR" --branch "$BASE_BRANCH" --single-branch >/dev/null

mkdir -p "$TARGET_DIR/.github" "$TARGET_DIR/.vscode"
mkdir -p "$TARGET_DIR/handbook/sops" "$TARGET_DIR/handbook/runbooks" "$TARGET_DIR/handbook/templates" "$TARGET_DIR/handbook/references"
for file in "${managed_files[@]}"; do
  mkdir -p "$(dirname "$TARGET_DIR/$file")"
  cp "$RENDER_DIR/$file" "$TARGET_DIR/$file"
done

if git -C "$TARGET_DIR" diff --quiet -- "${managed_files[@]}"; then
  echo "No role-repo sync changes detected for ${FULL_REPO} (${ROLE_SLUG})."
  exit 0
fi

git -C "$TARGET_DIR" checkout -B "$SYNC_BRANCH" >/dev/null

git -C "$TARGET_DIR" config user.name "context-engineering-sync[bot]"
git -C "$TARGET_DIR" config user.email "context-engineering-sync@users.noreply.github.com"

git -C "$TARGET_DIR" add "${managed_files[@]}"

if git -C "$TARGET_DIR" diff --cached --quiet; then
  echo "No staged changes after sync for ${FULL_REPO}."
  exit 0
fi

commit_message="Sync role job description artifacts for ${ROLE_SLUG} (${SOURCE_REF})"
git -C "$TARGET_DIR" commit -m "$commit_message" >/dev/null

if [ "$DRY_RUN" = "true" ]; then
  echo "Dry run enabled. Prepared sync commit for ${FULL_REPO} on branch ${SYNC_BRANCH}."
  git -C "$TARGET_DIR" --no-pager log --oneline -n 1
  git -C "$TARGET_DIR" --no-pager diff --stat "${BASE_BRANCH}...${SYNC_BRANCH}"
  exit 0
fi

remote_ref="refs/heads/${SYNC_BRANCH}"
remote_sha="$(git -C "$TARGET_DIR" ls-remote --heads origin "$SYNC_BRANCH" | awk '{print $1}')"

if [ -n "$remote_sha" ]; then
  git -C "$TARGET_DIR" push origin "$SYNC_BRANCH" --force-with-lease="${remote_ref}:${remote_sha}" >/dev/null
else
  git -C "$TARGET_DIR" push origin "$SYNC_BRANCH" >/dev/null
fi

if [ "$CREATE_PR" = "false" ]; then
  echo "Pushed sync branch without PR creation: ${FULL_REPO}:${SYNC_BRANCH}"
  exit 0
fi

PR_BODY_FILE="${WORK_DIR}/pr-body.md"
managed_files_markdown="$(printf -- '- `%s`\n' "${managed_files[@]}")"
cat > "$PR_BODY_FILE" <<PRBODY
Primary-Role: Implementation Specialist
Reviewed-By-Role: Compliance Officer
Executive-Sponsor-Approval: Not-Required

## Summary
Automated sync of role-repo managed artifacts from Context-Engineering source \`${SOURCE_REF}\` for role \`${ROLE_SLUG}\`.

## Managed Files Updated
${managed_files_markdown}

Generated via:
- \`10-templates/repo-starters/role-repo-template/scripts/render-role-repo-template.sh\`
- \`10-templates/repo-starters/role-repo-template/scripts/build-agent-job-description.py\`
PRBODY

existing_pr="$(gh api "repos/${FULL_REPO}/pulls?state=open&head=${OWNER}:${SYNC_BRANCH}&base=${BASE_BRANCH}" --jq '.[0].number' 2>/dev/null || true)"

if [ -z "$existing_pr" ] || [ "$existing_pr" = "null" ]; then
  existing_pr="$(gh api "repos/${FULL_REPO}/pulls?state=open&head=${SYNC_BRANCH}&base=${BASE_BRANCH}" --jq '.[0].number' 2>/dev/null || true)"
fi

pr_body="$(cat "$PR_BODY_FILE")"

if [ -n "$existing_pr" ] && [ "$existing_pr" != "null" ]; then
  gh api --method PATCH "repos/${FULL_REPO}/pulls/${existing_pr}" -f title="$PR_TITLE" -f body="$pr_body" >/dev/null
  pr_number="$existing_pr"
else
  create_err_file="$(mktemp "/tmp/${ROLE_SLUG}-pr-create-XXXXXX.err")"
  if pr_number="$(
    gh api --method POST "repos/${FULL_REPO}/pulls" \
      -f title="$PR_TITLE" \
      -f head="$SYNC_BRANCH" \
      -f base="$BASE_BRANCH" \
      -f body="$pr_body" \
      --jq '.number' 2>"$create_err_file"
  )"; then
    true
  else
    existing_pr="$(gh api "repos/${FULL_REPO}/pulls?state=open&head=${OWNER}:${SYNC_BRANCH}&base=${BASE_BRANCH}" --jq '.[0].number' 2>/dev/null || true)"
    if [ -z "$existing_pr" ] || [ "$existing_pr" = "null" ]; then
      existing_pr="$(gh api "repos/${FULL_REPO}/pulls?state=open&head=${SYNC_BRANCH}&base=${BASE_BRANCH}" --jq '.[0].number' 2>/dev/null || true)"
    fi
    if [ -n "$existing_pr" ] && [ "$existing_pr" != "null" ]; then
      pr_number="$existing_pr"
    else
      cat "$create_err_file" >&2
      exit 1
    fi
  fi
fi

# Best-effort labeling. If labels are missing in target repos, do not fail sync.
gh api --method POST "repos/${FULL_REPO}/issues/${pr_number}/labels" \
  -f labels[]="role:implementation-specialist" \
  -f labels[]="status:needs-review" >/dev/null 2>&1 || true

if [ "$AUTO_MERGE" = "true" ]; then
  pr_meta_file="$(mktemp "/tmp/${ROLE_SLUG}-pr-meta-XXXXXX.json")"
  if gh api "repos/${FULL_REPO}/pulls/${pr_number}" >"$pr_meta_file" 2>/dev/null; then
    pr_state="$(python3 - <<'PY' "$pr_meta_file"
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

state = data.get("state", "")
is_draft = bool(data.get("draft", False))
merge_state = (data.get("mergeable_state", "") or "").upper()
print(f"{state.upper()}|{str(is_draft).lower()}|{merge_state}")
PY
)"
    IFS='|' read -r pr_state_value pr_draft_value pr_merge_state <<<"$pr_state"
    mergeable="false"
    case "$pr_merge_state" in
      CLEAN|HAS_HOOKS|UNSTABLE)
        mergeable="true"
        ;;
    esac

    if [ "$pr_state_value" != "OPEN" ]; then
      echo "Auto-merge skipped for ${FULL_REPO} PR #${pr_number}: PR state is ${pr_state_value}."
    elif [ "$pr_draft_value" = "true" ]; then
      echo "Auto-merge skipped for ${FULL_REPO} PR #${pr_number}: PR is draft."
    elif [ "$mergeable" != "true" ]; then
      echo "Auto-merge skipped for ${FULL_REPO} PR #${pr_number}: mergeStateStatus=${pr_merge_state}."
    else
      merge_err_file="$(mktemp "/tmp/${ROLE_SLUG}-pr-merge-XXXXXX.err")"
      if gh pr merge --repo "$FULL_REPO" "$pr_number" --auto --squash --delete-branch >/dev/null 2>"$merge_err_file"; then
        echo "Auto-merge enabled for ${FULL_REPO} PR #${pr_number}."
      else
        merge_err_msg="$(tr '\n' ' ' < "$merge_err_file" | sed -E 's/[[:space:]]+/ /g')"
        echo "Auto-merge request failed (non-fatal) for ${FULL_REPO} PR #${pr_number}: ${merge_err_msg}"
      fi
      rm -f "$merge_err_file"
    fi
  else
    echo "Auto-merge skipped for ${FULL_REPO} PR #${pr_number}: unable to query PR metadata."
  fi
  rm -f "$pr_meta_file"
fi

echo "Synced role repo and opened/updated PR: https://github.com/${FULL_REPO}/pull/${pr_number}"
