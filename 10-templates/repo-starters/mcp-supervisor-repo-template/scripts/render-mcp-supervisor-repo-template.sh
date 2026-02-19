#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  render-mcp-supervisor-repo-template.sh \
    --repo-name <repo-name> \
    --output-dir <output-dir> \
    [--source-ref <source-ref>] \
    [--force]

Example:
  render-mcp-supervisor-repo-template.sh \
    --repo-name codex-supervisor-mcp \
    --output-dir /tmp/codex-supervisor-mcp
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
CONTRACT_ROOT="${REPO_ROOT}/10-templates/mcp-contracts"

REPO_NAME=""
OUTPUT_DIR=""
SOURCE_REF=""
FORCE="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
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

if [ -z "$REPO_NAME" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

if [ ! -d "$CONTRACT_ROOT" ]; then
  echo "Contract source directory not found: $CONTRACT_ROOT" >&2
  exit 1
fi

if [ -z "$SOURCE_REF" ]; then
  if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    SOURCE_REF="$(git -C "$REPO_ROOT" rev-parse --short HEAD)"
  else
    SOURCE_REF="unknown"
  fi
fi

if [ -d "$OUTPUT_DIR" ] && [ -n "$(ls -A "$OUTPUT_DIR" 2>/dev/null || true)" ] && [ "$FORCE" != "true" ]; then
  echo "Output directory is not empty: $OUTPUT_DIR" >&2
  echo "Use --force to overwrite generated files in an existing directory." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/src"
mkdir -p "$OUTPUT_DIR/contracts"

GENERATED_AT_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

escape_sed_replacement() {
  printf '%s' "$1" | sed -e 's/[&@]/\\&/g'
}

REPO_NAME_ESCAPED="$(escape_sed_replacement "$REPO_NAME")"
SOURCE_REF_ESCAPED="$(escape_sed_replacement "$SOURCE_REF")"
GENERATED_AT_ESCAPED="$(escape_sed_replacement "$GENERATED_AT_UTC")"

render_template() {
  local template_file="$1"
  local output_file="$2"

  sed \
    -e "s@{{REPO_NAME}}@${REPO_NAME_ESCAPED}@g" \
    -e "s@{{SOURCE_REF}}@${SOURCE_REF_ESCAPED}@g" \
    -e "s@{{GENERATED_AT_UTC}}@${GENERATED_AT_ESCAPED}@g" \
    "$template_file" \
    > "$output_file"
}

render_template "${TEMPLATE_ROOT}/templates/README.md.tmpl" "${OUTPUT_DIR}/README.md"
render_template "${TEMPLATE_ROOT}/templates/Dockerfile.tmpl" "${OUTPUT_DIR}/Dockerfile"
render_template "${TEMPLATE_ROOT}/templates/docker-compose.yml.tmpl" "${OUTPUT_DIR}/docker-compose.yml"
render_template "${TEMPLATE_ROOT}/templates/.env.example.tmpl" "${OUTPUT_DIR}/.env.example"
render_template "${TEMPLATE_ROOT}/templates/requirements.txt.tmpl" "${OUTPUT_DIR}/requirements.txt"
render_template "${TEMPLATE_ROOT}/templates/.gitignore.tmpl" "${OUTPUT_DIR}/.gitignore"
render_template "${TEMPLATE_ROOT}/templates/src/supervisor_mcp_server.py.tmpl" "${OUTPUT_DIR}/src/supervisor_mcp_server.py"

cp "${CONTRACT_ROOT}/ask-codex-supervisor.request.schema.json" "${OUTPUT_DIR}/contracts/"
cp "${CONTRACT_ROOT}/ask-codex-supervisor.response.schema.json" "${OUTPUT_DIR}/contracts/"
cp "${CONTRACT_ROOT}/ask-codex-supervisor.tool.json" "${OUTPUT_DIR}/contracts/"

echo "Generated MCP supervisor repo scaffold: ${OUTPUT_DIR}"
echo "Repo name: ${REPO_NAME}"
echo "Source ref: ${SOURCE_REF}"
