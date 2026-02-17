#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSTATION_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  start-role-workstation.sh [options]

Options:
  --role <implementation|compliance|systems-architect|hraias>
  --auth-mode <app|user>
  --pem-path <host_path_to_pem>
  --source <ghcr|local>
  --clone-context-engineering
  --no-clone-context-engineering
  --help

Notes:
  - If options are omitted, the script prompts interactively.
  - In app mode, --pem-path is required (or prompted).
  - You can optionally clone Context-Engineering into:
    /workspace/Projects/Context-Engineering
  - After startup, if Codex is unauthenticated, the script prompts
    whether to run device auth.
  - The PEM is mounted as a compose secret at:
    /run/secrets/role_github_app_private_key
EOF
}

prompt_if_empty() {
  local var_name="$1"
  local prompt_label="$2"
  local default_value="${3:-}"
  local value="${!var_name:-}"

  if [ -n "$value" ]; then
    return
  fi

  if [ -n "$default_value" ]; then
    read -r -p "${prompt_label} [${default_value}]: " value
    value="${value:-$default_value}"
  else
    read -r -p "${prompt_label}: " value
  fi

  printf -v "$var_name" '%s' "$value"
}

normalize_role() {
  case "$1" in
    # GENERATED:BEGIN:NORMALIZE_ROLE_CASES
    implementation|implementation-specialist) echo "implementation" ;;
    compliance|compliance-officer) echo "compliance" ;;
    systems-architect) echo "systems-architect" ;;
    hraias|hr-ai-agent-specialist) echo "hraias" ;;
# GENERATED:END:NORMALIZE_ROLE_CASES
    *) return 1 ;;
  esac
}

normalize_auth_mode() {
  case "$1" in
    app|user) echo "$1" ;;
    *) return 1 ;;
  esac
}

normalize_source() {
  case "$1" in
    ghcr|local) echo "$1" ;;
    *) return 1 ;;
  esac
}

ROLE=""
AUTH_MODE=""
PEM_PATH=""
SOURCE=""
CLONE_CONTEXT_ENGINEERING=""
CONTEXT_ENGINEERING_REPO_URL="${CONTEXT_ENGINEERING_REPO_URL:-https://github.com/Josh-Phillips-LLC/Context-Engineering.git}"
CONTEXT_ENGINEERING_REPO_DIR="${CONTEXT_ENGINEERING_REPO_DIR:-/workspace/Projects/Context-Engineering}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --role)
      ROLE="${2:-}"
      shift 2
      ;;
    --auth-mode)
      AUTH_MODE="${2:-}"
      shift 2
      ;;
    --pem-path)
      PEM_PATH="${2:-}"
      shift 2
      ;;
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --clone-context-engineering)
      CLONE_CONTEXT_ENGINEERING="yes"
      shift
      ;;
    --no-clone-context-engineering)
      CLONE_CONTEXT_ENGINEERING="no"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -n "$ROLE" ]; then
  ROLE="$(normalize_role "$ROLE")" || {
    echo "Invalid --role value: $ROLE" >&2
    exit 1
  }
fi

if [ -n "$AUTH_MODE" ]; then
  AUTH_MODE="$(normalize_auth_mode "$AUTH_MODE")" || {
    echo "Invalid --auth-mode value: $AUTH_MODE" >&2
    exit 1
  }
fi

if [ -n "$SOURCE" ]; then
  SOURCE="$(normalize_source "$SOURCE")" || {
    echo "Invalid --source value: $SOURCE" >&2
    exit 1
  }
fi

if [ -z "$SOURCE" ]; then
  echo "Select image source:"
  echo "  1) ghcr (published images)"
  echo "  2) local (build from local Dockerfile)"
  read -r -p "Choice [1]: " source_choice
  case "${source_choice:-1}" in
    1) SOURCE="ghcr" ;;
    2) SOURCE="local" ;;
    *)
      echo "Invalid source choice." >&2
      exit 1
      ;;
  esac
fi

if [ -z "$ROLE" ]; then
  echo "Select role:"
  # GENERATED:BEGIN:ROLE_MENU
  echo "  1) implementation"
  echo "  2) compliance"
  echo "  3) systems-architect"
  echo "  4) hraias"
# GENERATED:END:ROLE_MENU
  read -r -p "Choice [2]: " role_choice
  case "${role_choice:-2}" in
    # GENERATED:BEGIN:ROLE_MENU_CASE
    1) ROLE="implementation" ;;
    2) ROLE="compliance" ;;
    3) ROLE="systems-architect" ;;
    4) ROLE="hraias" ;;
# GENERATED:END:ROLE_MENU_CASE
    *)
      echo "Invalid role choice." >&2
      exit 1
      ;;
  esac
fi

prompt_if_empty AUTH_MODE "Auth mode (app|user)" "app"
AUTH_MODE="$(normalize_auth_mode "$AUTH_MODE")" || {
  echo "Invalid auth mode: $AUTH_MODE" >&2
  exit 1
}

case "$ROLE" in
  # GENERATED:BEGIN:ROLE_MAPPING_CASES
  implementation)
    ROLE_PROFILE="implementation-specialist"
    SERVICE_NAME="implementation-workstation"
    PROFILE_NAME=""
    ROLE_ENV_PREFIX="IMPLEMENTATION"
    ;;
  compliance)
    ROLE_PROFILE="compliance-officer"
    SERVICE_NAME="compliance-workstation"
    PROFILE_NAME="compliance-officer"
    ROLE_ENV_PREFIX="COMPLIANCE"
    ;;
  systems-architect)
    ROLE_PROFILE="systems-architect"
    SERVICE_NAME="systems-architect-workstation"
    PROFILE_NAME="systems-architect"
    ROLE_ENV_PREFIX="SYSTEMS_ARCHITECT"
    ;;
  hraias)
    ROLE_PROFILE="hr-ai-agent-specialist"
    SERVICE_NAME="hr-ai-agent-specialist-workstation"
    PROFILE_NAME="hr-ai-agent-specialist"
    ROLE_ENV_PREFIX="HR_AI_AGENT_SPECIALIST"
    ;;
# GENERATED:END:ROLE_MAPPING_CASES
esac

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD=(docker compose)
else
  COMPOSE_CMD=(docker-compose)
fi

case "$SOURCE" in
  ghcr) COMPOSE_FILE="${WORKSTATION_DIR}/docker-compose.ghcr.yml" ;;
  local) COMPOSE_FILE="${WORKSTATION_DIR}/docker-compose.yml" ;;
esac

COMPOSE_ARGS=(-f "$COMPOSE_FILE")
ENV_ARGS=("${ROLE_ENV_PREFIX}_ROLE_GITHUB_AUTH_MODE=${AUTH_MODE}")

TMP_OVERRIDE_FILE=""
cleanup() {
  if [ -n "${TMP_OVERRIDE_FILE:-}" ] && [ -f "$TMP_OVERRIDE_FILE" ]; then
    rm -f "$TMP_OVERRIDE_FILE"
  fi
}
trap cleanup EXIT

if [ "$AUTH_MODE" = "app" ]; then
  if [ -z "$PEM_PATH" ]; then
    read -r -p "PEM path on host filesystem: " PEM_PATH
  fi

  if [ -z "$PEM_PATH" ]; then
    echo "PEM path is required in app mode." >&2
    exit 1
  fi

  if [ ! -r "$PEM_PATH" ]; then
    echo "PEM file is not readable: $PEM_PATH" >&2
    exit 1
  fi

  ENV_ARGS+=("${ROLE_ENV_PREFIX}_ROLE_GITHUB_APP_PRIVATE_KEY_PATH=/run/secrets/role_github_app_private_key")
  ENV_ARGS+=(GH_TOKEN= GITHUB_TOKEN=)

  TMP_OVERRIDE_FILE="$(mktemp "/tmp/${SERVICE_NAME}.app-secret.XXXXXX.yml")"
  cat > "$TMP_OVERRIDE_FILE" <<EOF
services:
  ${SERVICE_NAME}:
    secrets:
      - source: role_github_app_private_key
        target: role_github_app_private_key
secrets:
  role_github_app_private_key:
    file: "${PEM_PATH}"
EOF
  COMPOSE_ARGS+=(-f "$TMP_OVERRIDE_FILE")
fi

if [ -n "$PROFILE_NAME" ]; then
  COMPOSE_ARGS+=(--profile "$PROFILE_NAME")
fi

UP_ARGS=(up -d)
if [ "$SOURCE" = "local" ]; then
  UP_ARGS+=(--build)
fi
UP_ARGS+=("$SERVICE_NAME")

has_interactive_tty() {
  [ -t 0 ] && [ -t 1 ]
}

if [ -z "$CLONE_CONTEXT_ENGINEERING" ]; then
  if has_interactive_tty; then
    read -r -p "Clone Context-Engineering into ${SERVICE_NAME} at ${CONTEXT_ENGINEERING_REPO_DIR}? [y/N]: " clone_context_choice
    case "${clone_context_choice:-n}" in
      y|Y|yes|YES)
        CLONE_CONTEXT_ENGINEERING="yes"
        ;;
      *)
        CLONE_CONTEXT_ENGINEERING="no"
        ;;
    esac
  else
    CLONE_CONTEXT_ENGINEERING="no"
  fi
fi

clone_context_engineering_repo() {
  if [ "${CLONE_CONTEXT_ENGINEERING}" != "yes" ]; then
    return 0
  fi

  if ! docker exec "$SERVICE_NAME" sh -lc 'command -v git >/dev/null 2>&1'; then
    echo "Warning: 'git' is not available in ${SERVICE_NAME}; skipping Context-Engineering clone." >&2
    return 0
  fi

  if docker exec -e CE_REPO_DIR="$CONTEXT_ENGINEERING_REPO_DIR" "$SERVICE_NAME" sh -lc '[ -d "$CE_REPO_DIR/.git" ]'; then
    echo "Context-Engineering already present at ${CONTEXT_ENGINEERING_REPO_DIR}; skipping clone."
    return 0
  fi

  if ! docker exec -e CE_REPO_DIR="$CONTEXT_ENGINEERING_REPO_DIR" "$SERVICE_NAME" sh -lc '[ ! -d "$CE_REPO_DIR" ] || [ -z "$(ls -A "$CE_REPO_DIR" 2>/dev/null || true)" ]'; then
    echo "Skipping Context-Engineering clone; ${CONTEXT_ENGINEERING_REPO_DIR} exists and is not empty."
    return 0
  fi

  echo "Cloning Context-Engineering into ${CONTEXT_ENGINEERING_REPO_DIR}..."
  if docker exec \
    -e CE_REPO_URL="$CONTEXT_ENGINEERING_REPO_URL" \
    -e CE_REPO_DIR="$CONTEXT_ENGINEERING_REPO_DIR" \
    "$SERVICE_NAME" \
    bash -lc 'set -euo pipefail; mkdir -p "$(dirname "$CE_REPO_DIR")"; git clone "$CE_REPO_URL" "$CE_REPO_DIR" >/dev/null 2>&1'; then
    echo "Cloned Context-Engineering to ${CONTEXT_ENGINEERING_REPO_DIR}."
  else
    echo "Warning: failed to clone Context-Engineering from ${CONTEXT_ENGINEERING_REPO_URL}." >&2
  fi
}

run_codex_auth_flow() {
  if ! docker exec "$SERVICE_NAME" sh -lc 'command -v codex >/dev/null 2>&1'; then
    echo "Warning: 'codex' CLI is not available in ${SERVICE_NAME}; skipping Codex auth flow." >&2
    return 0
  fi

  if docker exec "$SERVICE_NAME" sh -lc 'codex login status >/dev/null 2>&1'; then
    echo "Codex auth already active in ${SERVICE_NAME}."
    return 0
  fi

  if ! has_interactive_tty; then
    echo "Skipping Codex auth setup prompt in non-interactive shell."
    echo "Run this manually after attach:"
    echo "  docker exec -it ${SERVICE_NAME} sh -lc 'codex login --device-auth || codex login'"
    return 0
  fi

  read -r -p "Codex is not authenticated in ${SERVICE_NAME}. Set up Codex auth now? [Y/n]: " codex_auth_choice
  case "${codex_auth_choice:-y}" in
    y|Y|yes|YES) ;;
    *)
      echo "Skipped Codex auth setup by operator choice."
      return 0
      ;;
  esac

  echo "Starting Codex device auth inside ${SERVICE_NAME}..."
  if ! docker exec -it "$SERVICE_NAME" sh -lc 'if codex login --help 2>/dev/null | grep -q -- "--device-auth"; then codex login --device-auth; else codex login; fi'; then
    echo "Warning: Codex device auth command failed." >&2
    return 1
  fi

  if docker exec "$SERVICE_NAME" sh -lc 'codex login status >/dev/null 2>&1'; then
    echo "Codex auth verified in ${SERVICE_NAME}."
    echo "If VS Code chat still shows 'Sign in with ChatGPT', run: Developer: Reload Window"
    return 0
  fi

  echo "Warning: Codex login completed but status check still failed in ${SERVICE_NAME}." >&2
  echo "Run this manually to troubleshoot:" >&2
  echo "  docker exec -it ${SERVICE_NAME} sh -lc 'codex login status'" >&2
  return 1
}

echo "Starting ${SERVICE_NAME} (${ROLE_PROFILE}) using ${SOURCE}..."
env "${ENV_ARGS[@]}" "${COMPOSE_CMD[@]}" "${COMPOSE_ARGS[@]}" "${UP_ARGS[@]}"

if docker ps --filter "name=^/${SERVICE_NAME}$" --filter "status=running" --format '{{.Names}}' | grep -qx "$SERVICE_NAME"; then
  echo "Container is running: ${SERVICE_NAME}"
  echo "VS Code attach target: ${SERVICE_NAME}"
  clone_context_engineering_repo
  if ! run_codex_auth_flow; then
    echo "Continuing without verified Codex auth."
  fi
else
  echo "Container failed to stay running: ${SERVICE_NAME}" >&2
  echo "Inspect logs with:" >&2
  echo "  ${COMPOSE_CMD[*]} ${COMPOSE_ARGS[*]} logs --tail=200 ${SERVICE_NAME}" >&2
  exit 1
fi
