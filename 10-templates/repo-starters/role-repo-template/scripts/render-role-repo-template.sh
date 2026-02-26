#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  render-role-repo-template.sh \
    --role-slug <role-slug> \
    --repo-name <repo-name> \
    --output-dir <output-dir> \
    [--source-ref <source-ref>] \
    [--force]

Example:
  render-role-repo-template.sh \
    --role-slug implementation-specialist \
    --repo-name context-engineering-role-implementation-specialist \
    --output-dir /tmp/context-engineering-role-implementation-specialist \
    --source-ref main
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
JOB_DESCRIPTION_BUILDER="${SCRIPT_DIR}/build-agent-job-description.py"

ROLE_SLUG=""
ROLE_NAME=""
REPO_NAME=""
OUTPUT_DIR=""
SOURCE_REF=""
FORCE="false"

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
    --repo-name)
      REPO_NAME="$2"
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

if [ -z "$ROLE_SLUG" ] || [ -z "$REPO_NAME" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

if [ -z "$SOURCE_REF" ]; then
  if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    SOURCE_REF="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
  else
    SOURCE_REF="unknown"
  fi
fi

if [ -z "$ROLE_NAME" ]; then
  case "$ROLE_SLUG" in
    implementation-specialist)
      ROLE_NAME="Implementation Specialist"
      ;;
    compliance-officer)
      ROLE_NAME="Compliance Officer"
      ;;
    *)
      ROLE_NAME="$(echo "$ROLE_SLUG" | tr '-' ' ' | awk '{for (i=1; i<=NF; i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')"
      ;;
  esac
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to build AGENTS job descriptions." >&2
  exit 1
fi

if [ ! -x "$JOB_DESCRIPTION_BUILDER" ]; then
  echo "Job description builder not found or not executable: $JOB_DESCRIPTION_BUILDER" >&2
  exit 1
fi

if [ -d "$OUTPUT_DIR" ] && [ -n "$(ls -A "$OUTPUT_DIR" 2>/dev/null || true)" ] && [ "$FORCE" != "true" ]; then
  echo "Output directory is not empty: $OUTPUT_DIR" >&2
  echo "Use --force to overwrite generated files in an existing directory." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR/.github/workflows" "$OUTPUT_DIR/.vscode" "$OUTPUT_DIR/scripts"
mkdir -p "$OUTPUT_DIR/handbook/sops" "$OUTPUT_DIR/handbook/runbooks" "$OUTPUT_DIR/handbook/templates" "$OUTPUT_DIR/handbook/references"

GENERATED_AT_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
COMPILED_INSTRUCTIONS_FILE="$(mktemp)"
trap 'rm -f "$COMPILED_INSTRUCTIONS_FILE"' EXIT

{
  python3 "$JOB_DESCRIPTION_BUILDER" \
    --role-slug "$ROLE_SLUG" \
    --role-name "$ROLE_NAME" \
    --source-ref "$SOURCE_REF" \
    --generated-at-utc "$GENERATED_AT_UTC" \
    --repo-root "$REPO_ROOT"
} > "$COMPILED_INSTRUCTIONS_FILE"

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[&@]/\\&/g'
}

ROLE_NAME_ESCAPED="$(escape_sed_replacement "$ROLE_NAME")"
ROLE_SLUG_ESCAPED="$(escape_sed_replacement "$ROLE_SLUG")"
REPO_NAME_ESCAPED="$(escape_sed_replacement "$REPO_NAME")"
SOURCE_REF_ESCAPED="$(escape_sed_replacement "$SOURCE_REF")"
GENERATED_AT_ESCAPED="$(escape_sed_replacement "$GENERATED_AT_UTC")"

render_template() {
  local template_file="$1"
  local output_file="$2"

  sed \
    -e "s@{{ROLE_NAME}}@${ROLE_NAME_ESCAPED}@g" \
    -e "s@{{ROLE_SLUG}}@${ROLE_SLUG_ESCAPED}@g" \
    -e "s@{{REPO_NAME}}@${REPO_NAME_ESCAPED}@g" \
    -e "s@{{SOURCE_REF}}@${SOURCE_REF_ESCAPED}@g" \
    -e "s@{{GENERATED_AT_UTC}}@${GENERATED_AT_ESCAPED}@g" \
    "$template_file" \
  | sed "/{{ROLE_INSTRUCTIONS}}/r ${COMPILED_INSTRUCTIONS_FILE}" \
  | sed "s/{{ROLE_INSTRUCTIONS}}//g" \
  > "$output_file"
}

render_template "${TEMPLATE_ROOT}/templates/AGENTS.md.tmpl" "${OUTPUT_DIR}/AGENTS.md"
render_template "${TEMPLATE_ROOT}/templates/.github/copilot-instructions.md.tmpl" "${OUTPUT_DIR}/.github/copilot-instructions.md"
render_template "${TEMPLATE_ROOT}/templates/.github/pull_request_template.md.tmpl" "${OUTPUT_DIR}/.github/pull_request_template.md"
render_template "${TEMPLATE_ROOT}/templates/.github/workflows/governance-pr-gates.yml.tmpl" "${OUTPUT_DIR}/.github/workflows/governance-pr-gates.yml"
render_template "${TEMPLATE_ROOT}/templates/README.md.tmpl" "${OUTPUT_DIR}/README.md"
render_template "${TEMPLATE_ROOT}/templates/.vscode/settings.json.tmpl" "${OUTPUT_DIR}/.vscode/settings.json"
render_template "${TEMPLATE_ROOT}/templates/scripts/validate-pr-metadata.py.tmpl" "${OUTPUT_DIR}/scripts/validate-pr-metadata.py"
render_template "${TEMPLATE_ROOT}/templates/scripts/bootstrap-governance-labels.sh.tmpl" "${OUTPUT_DIR}/scripts/bootstrap-governance-labels.sh"
render_template "${TEMPLATE_ROOT}/templates/scripts/gh-safe-comment.sh.tmpl" "${OUTPUT_DIR}/scripts/gh-safe-comment.sh"
render_template "${TEMPLATE_ROOT}/templates/scripts/request-pr-review.sh.tmpl" "${OUTPUT_DIR}/scripts/request-pr-review.sh"
render_template "${TEMPLATE_ROOT}/templates/handbook/README.md.tmpl" "${OUTPUT_DIR}/handbook/README.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/sops/README.md.tmpl" "${OUTPUT_DIR}/handbook/sops/README.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/sops/general-process-improvement-loop.md.tmpl" "${OUTPUT_DIR}/handbook/sops/general-process-improvement-loop.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/runbooks/README.md.tmpl" "${OUTPUT_DIR}/handbook/runbooks/README.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/runbooks/general-governance-label-bootstrap.md.tmpl" "${OUTPUT_DIR}/handbook/runbooks/general-governance-label-bootstrap.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/runbooks/general-github-commenting.md.tmpl" "${OUTPUT_DIR}/handbook/runbooks/general-github-commenting.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/runbooks/general-reviewer-request-preflight.md.tmpl" "${OUTPUT_DIR}/handbook/runbooks/general-reviewer-request-preflight.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/templates/README.md.tmpl" "${OUTPUT_DIR}/handbook/templates/README.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/templates/general-efficiency-opportunity.md.tmpl" "${OUTPUT_DIR}/handbook/templates/general-efficiency-opportunity.md"
render_template "${TEMPLATE_ROOT}/templates/handbook/references/README.md.tmpl" "${OUTPUT_DIR}/handbook/references/README.md"

if [ "$ROLE_SLUG" = "compliance-officer" ]; then
  render_template "${TEMPLATE_ROOT}/templates/scripts/co-pr-review.sh.tmpl" "${OUTPUT_DIR}/scripts/co-pr-review.sh"
  render_template "${TEMPLATE_ROOT}/templates/scripts/co-pr-review-report.sh.tmpl" "${OUTPUT_DIR}/scripts/co-pr-review-report.sh"
  chmod +x "${OUTPUT_DIR}/scripts/co-pr-review.sh"
  chmod +x "${OUTPUT_DIR}/scripts/co-pr-review-report.sh"
  render_template "${TEMPLATE_ROOT}/templates/handbook/runbooks/compliance-pr-review-wrapper.md.tmpl" "${OUTPUT_DIR}/handbook/runbooks/compliance-pr-review-wrapper.md"
  render_template "${TEMPLATE_ROOT}/templates/handbook/runbooks/compliance-rereview-after-changes.md.tmpl" "${OUTPUT_DIR}/handbook/runbooks/compliance-rereview-after-changes.md"
  render_template "${TEMPLATE_ROOT}/templates/handbook/templates/compliance-pr-review-report.md.tmpl" "${OUTPUT_DIR}/handbook/templates/compliance-pr-review-report.md"
fi

chmod +x "${OUTPUT_DIR}/scripts/validate-pr-metadata.py"
chmod +x "${OUTPUT_DIR}/scripts/bootstrap-governance-labels.sh"
chmod +x "${OUTPUT_DIR}/scripts/gh-safe-comment.sh"
chmod +x "${OUTPUT_DIR}/scripts/request-pr-review.sh"

echo "Generated role repo scaffold: ${OUTPUT_DIR}"
echo "Role: ${ROLE_NAME} (${ROLE_SLUG})"
echo "Source ref: ${SOURCE_REF}"
