#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  create-public-role-repo.sh \
    --role-slug <role-slug> \
    --owner <github-owner> \
    [--repo-name <repo-name>] \
    [--role-name <role-name>] \
    [--description <repo-description>] \
    [--output-dir <local-output-dir>] \
    [--source-ref <source-ref>] \
    [--force] \
    [--dry-run]

Required:
  --role-slug   Role slug (for example: implementation-specialist)
  --owner       GitHub owner (organization or user)

Optional:
  --repo-name   Defaults to: context-engineering-role-<role-slug>
  --role-name   Optional display name override
  --description Optional repository description
  --output-dir  Local scaffold directory (defaults to a temporary directory)
  --source-ref  Passed through to renderer; default is current git short SHA
  --force       Allow writing into existing non-empty output directory
  --dry-run     Render locally and print planned create/push command without creating remote repo

Examples:
  create-public-role-repo.sh \
    --role-slug implementation-specialist \
    --owner Josh-Phillips-LLC

  create-public-role-repo.sh \
    --role-slug compliance-officer \
    --owner Josh-Phillips-LLC \
    --repo-name context-engineering-role-compliance-officer \
    --description "Public role workspace for Compliance Officer"
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDER_SCRIPT="${SCRIPT_DIR}/render-role-repo-template.sh"

ROLE_SLUG=""
ROLE_NAME=""
OWNER=""
REPO_NAME=""
DESCRIPTION=""
OUTPUT_DIR=""
SOURCE_REF=""
FORCE="false"
DRY_RUN="false"

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
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --source-ref)
      SOURCE_REF="$2"
      shift 2
      ;;
    --force)
      FORCE="true"
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
  echo "Missing required arguments: --role-slug and --owner are required." >&2
  usage
  exit 1
fi

if [ ! -x "$RENDER_SCRIPT" ]; then
  echo "Renderer script not found or not executable: $RENDER_SCRIPT" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "git is required." >&2
  exit 1
fi

run_publishability_preflight() {
  local target_dir="$1"
  local -a scan_files=(
    "AGENTS.md"
    "README.md"
    ".github/copilot-instructions.md"
    ".github/pull_request_template.md"
    ".github/workflows/governance-pr-gates.yml"
    ".vscode/settings.json"
    "scripts/validate-pr-metadata.py"
  )
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

  for file in "${scan_files[@]}"; do
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
    echo "Resolve the flagged content before creating the role repository." >&2
    exit 1
  fi
}

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "GitHub CLI is not authenticated. Run: gh auth login" >&2
  exit 1
fi

if [ -z "$REPO_NAME" ]; then
  REPO_NAME="context-engineering-role-${ROLE_SLUG}"
fi

if [ -z "$DESCRIPTION" ]; then
  DESCRIPTION="Public role workspace for ${ROLE_SLUG}"
fi

if [ -z "$OUTPUT_DIR" ]; then
  OUTPUT_DIR="$(mktemp -d "/tmp/${REPO_NAME}-XXXXXX")"
fi

FULL_REPO="${OWNER}/${REPO_NAME}"

if gh repo view "$FULL_REPO" >/dev/null 2>&1; then
  echo "Repository already exists: $FULL_REPO" >&2
  exit 1
fi

render_args=(
  --role-slug "$ROLE_SLUG"
  --repo-name "$REPO_NAME"
  --output-dir "$OUTPUT_DIR"
)

if [ -n "$ROLE_NAME" ]; then
  render_args+=(--role-name "$ROLE_NAME")
fi

if [ -n "$SOURCE_REF" ]; then
  render_args+=(--source-ref "$SOURCE_REF")
fi

if [ "$FORCE" = "true" ]; then
  render_args+=(--force)
fi

"$RENDER_SCRIPT" "${render_args[@]}"

run_publishability_preflight "$OUTPUT_DIR"

if [ "$DRY_RUN" = "true" ]; then
  echo
  echo "Dry run complete. Planned actions:"
  echo "1) git init -b main \"$OUTPUT_DIR\""
  echo "2) commit generated files"
  echo "3) gh repo create \"$FULL_REPO\" --public --source \"$OUTPUT_DIR\" --remote origin --push --description \"$DESCRIPTION\""
  echo
  echo "No remote repository was created."
  echo "Rendered output directory: $OUTPUT_DIR"
  exit 0
fi

if [ ! -d "$OUTPUT_DIR/.git" ]; then
  git -C "$OUTPUT_DIR" init -b main >/dev/null
fi

git -C "$OUTPUT_DIR" add .

if git -C "$OUTPUT_DIR" diff --cached --quiet; then
  echo "No files staged for initial commit in $OUTPUT_DIR" >&2
  exit 1
fi

git -C "$OUTPUT_DIR" commit -m "Initial role repo scaffold for ${ROLE_SLUG}" >/dev/null

gh repo create "$FULL_REPO" \
  --public \
  --source "$OUTPUT_DIR" \
  --remote origin \
  --push \
  --description "$DESCRIPTION" >/dev/null

REPO_URL="https://github.com/${FULL_REPO}"

echo "Created public role repository: ${REPO_URL}"
echo "Local scaffold path: ${OUTPUT_DIR}"
