#!/usr/bin/env bash
set -euo pipefail

WORKSTATION_DEBUG="${WORKSTATION_DEBUG:-false}"

if [ "$WORKSTATION_DEBUG" = "true" ]; then
  set -x
  echo "Debug mode enabled for init-workstation.sh"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CODEX_HOME_DIR="${CODEX_HOME:-/root/.codex}"
DEFAULT_CONFIG="${DEFAULT_CONFIG:-/etc/codex/config.toml}"
TARGET_CONFIG="${CODEX_HOME_DIR}/config.toml"
ROLE_PROFILE="${ROLE_PROFILE:-${IMAGE_ROLE_PROFILE:-implementation-specialist}}"
ROLE_PROFILES_DIR="${ROLE_PROFILES_DIR:-/etc/codex/role-profiles}"
ROLE_INSTRUCTIONS_DIR_REL="${ROLE_INSTRUCTIONS_DIR_REL:-10-templates/agent-instructions}"
BAKED_ROLE_INSTRUCTIONS_DIR="${BAKED_ROLE_INSTRUCTIONS_DIR:-/etc/codex/agent-instructions}"
BAKED_COMPILED_ROLE_INSTRUCTIONS_DIR="${BAKED_COMPILED_ROLE_INSTRUCTIONS_DIR:-/etc/codex/runtime-role-instructions}"
COMPLIANCE_REVIEW_BRIEF_WORKSPACE_REL="${COMPLIANCE_REVIEW_BRIEF_WORKSPACE_REL:-10-templates/compliance-officer-pr-review-brief.md}"
COMPLIANCE_REVIEW_BRIEF_BAKED="${COMPLIANCE_REVIEW_BRIEF_BAKED:-/etc/codex/agent-instructions/references/compliance-officer-pr-review-brief.md}"
RUNTIME_ROLE_INSTRUCTIONS_FILE="${RUNTIME_ROLE_INSTRUCTIONS_FILE:-/workspace/instructions/role-instructions.md}"
RUNTIME_AGENTS_ADAPTER_FILE="${RUNTIME_AGENTS_ADAPTER_FILE:-/workspace/instructions/AGENTS.md}"
RUNTIME_COPILOT_INSTRUCTIONS_FILE="${RUNTIME_COPILOT_INSTRUCTIONS_FILE:-/workspace/instructions/copilot-instructions.md}"
RUNTIME_CONTINUE_INSTRUCTIONS_FILE="${RUNTIME_CONTINUE_INSTRUCTIONS_FILE:-/workspace/instructions/continue-instructions.md}"
RUNTIME_AGENT_RUNTIME_POLICY_FILE="${RUNTIME_AGENT_RUNTIME_POLICY_FILE:-/workspace/instructions/agent-runtime-policy.md}"
RUNTIME_VSCODE_SETTINGS_FILE="${RUNTIME_VSCODE_SETTINGS_FILE:-/workspace/settings/vscode/settings.json}"
RUNTIME_VSCODE_MACHINE_SETTINGS_FILE="${RUNTIME_VSCODE_MACHINE_SETTINGS_FILE:-/root/.vscode-server/data/Machine/settings.json}"
RUNTIME_GITHUB_APP_AUTH_METADATA_FILE="${RUNTIME_GITHUB_APP_AUTH_METADATA_FILE:-/workspace/instructions/role-github-app-auth.env}"
WORKSPACE_REPO_OWNER="${WORKSPACE_REPO_OWNER:-Josh-Phillips-LLC}"
WORKSPACE_REPO_NAME_DEFAULT="${WORKSPACE_REPO_NAME_DEFAULT:-context-engineering-role-${ROLE_PROFILE}}"
WORKSPACE_REPO_URL="${WORKSPACE_REPO_URL:-https://github.com/${WORKSPACE_REPO_OWNER}/${WORKSPACE_REPO_NAME_DEFAULT}.git}"
WORKSPACE_REPO_DIR="${WORKSPACE_REPO_DIR:-/workspace/Projects/${WORKSPACE_REPO_NAME_DEFAULT}}"
AUTO_CLONE_WORKSPACE_REPO="${AUTO_CLONE_WORKSPACE_REPO:-true}"
ALLOW_FALLBACK_INSTRUCTIONS="${ALLOW_FALLBACK_INSTRUCTIONS:-false}"
ROLE_GITHUB_APP_AUTH_SCRIPT="${ROLE_GITHUB_APP_AUTH_SCRIPT:-${SCRIPT_DIR}/setup-role-github-app-auth.sh}"
GH_BOOTSTRAP_TOKEN="${GH_BOOTSTRAP_TOKEN:-}"
ROLE_GITHUB_AUTH_MODE_RUNTIME="${ROLE_GITHUB_AUTH_MODE:-}"
ROLE_GITHUB_APP_ID_RUNTIME="${ROLE_GITHUB_APP_ID:-}"
ROLE_GITHUB_APP_INSTALLATION_ID_RUNTIME="${ROLE_GITHUB_APP_INSTALLATION_ID:-}"
ROLE_GITHUB_APP_PRIVATE_KEY_PATH_RUNTIME="${ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-}"
ROLE_GIT_IDENTITY_NAME_RUNTIME="${ROLE_GIT_IDENTITY_NAME:-}"
ROLE_GIT_IDENTITY_EMAIL_RUNTIME="${ROLE_GIT_IDENTITY_EMAIL:-}"

replace_string_setting() {
  local key="$1"
  local value="$2"
  local escaped_value

  escaped_value="$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')"

  if grep -qE "^${key} = " "$TARGET_CONFIG"; then
    sed -i -E "s|^${key} = .*|${key} = \"${escaped_value}\"|" "$TARGET_CONFIG"
  else
    echo "Warning: key '${key}' not found in ${TARGET_CONFIG}; skipping." >&2
  fi
}

replace_raw_setting() {
  local key="$1"
  local raw_value="$2"
  local escaped_value

  escaped_value="$(printf '%s' "$raw_value" | sed 's/[\/&]/\\&/g')"

  if grep -qE "^${key} = " "$TARGET_CONFIG"; then
    sed -i -E "s|^${key} = .*|${key} = ${escaped_value}|" "$TARGET_CONFIG"
  else
    echo "Warning: key '${key}' not found in ${TARGET_CONFIG}; skipping." >&2
  fi
}

apply_role_profile() {
  local profile_file="${ROLE_PROFILES_DIR}/${ROLE_PROFILE}.env"

  if [ ! -f "$profile_file" ]; then
    echo "Warning: role profile '${ROLE_PROFILE}' not found at ${profile_file}; using existing config values." >&2
    return
  fi

  # shellcheck disable=SC1090
  source "$profile_file"

  # Runtime-provided GitHub App auth values take precedence over role profile defaults.
  if [ -n "${ROLE_GITHUB_AUTH_MODE_RUNTIME:-}" ]; then
    ROLE_GITHUB_AUTH_MODE="$ROLE_GITHUB_AUTH_MODE_RUNTIME"
  fi
  if [ -n "${ROLE_GITHUB_APP_ID_RUNTIME:-}" ]; then
    ROLE_GITHUB_APP_ID="$ROLE_GITHUB_APP_ID_RUNTIME"
  fi
  if [ -n "${ROLE_GITHUB_APP_INSTALLATION_ID_RUNTIME:-}" ]; then
    ROLE_GITHUB_APP_INSTALLATION_ID="$ROLE_GITHUB_APP_INSTALLATION_ID_RUNTIME"
  fi
  if [ -n "${ROLE_GITHUB_APP_PRIVATE_KEY_PATH_RUNTIME:-}" ]; then
    ROLE_GITHUB_APP_PRIVATE_KEY_PATH="$ROLE_GITHUB_APP_PRIVATE_KEY_PATH_RUNTIME"
  fi
  if [ -n "${ROLE_GIT_IDENTITY_NAME_RUNTIME:-}" ]; then
    ROLE_GIT_IDENTITY_NAME="$ROLE_GIT_IDENTITY_NAME_RUNTIME"
  fi
  if [ -n "${ROLE_GIT_IDENTITY_EMAIL_RUNTIME:-}" ]; then
    ROLE_GIT_IDENTITY_EMAIL="$ROLE_GIT_IDENTITY_EMAIL_RUNTIME"
  fi

  if [ "${ROLE_APPROVAL_POLICY:-never}" != "never" ]; then
    echo "Warning: role profile requested approval_policy='${ROLE_APPROVAL_POLICY}'; forcing 'never' for full in-container runtime parity." >&2
  fi
  replace_string_setting "approval_policy" "never"

  if [ "${ROLE_SANDBOX_MODE:-danger-full-access}" != "danger-full-access" ]; then
    echo "Warning: role profile requested sandbox_mode='${ROLE_SANDBOX_MODE}'; forcing 'danger-full-access' for full in-container runtime parity." >&2
  fi
  replace_string_setting "sandbox_mode" "danger-full-access"

  if [ -n "${ROLE_MODEL_REASONING_EFFORT:-}" ]; then
    replace_string_setting "model_reasoning_effort" "$ROLE_MODEL_REASONING_EFFORT"
  fi

  if [ -n "${ROLE_MODEL_PERSONALITY:-}" ]; then
    replace_string_setting "model_personality" "$ROLE_MODEL_PERSONALITY"
  fi

  if [ -n "${ROLE_WRITABLE_ROOTS:-}" ] && [ "${ROLE_WRITABLE_ROOTS}" != '["/"]' ]; then
    echo "Warning: role profile requested writable_roots='${ROLE_WRITABLE_ROOTS}'; forcing '[\"/\"]' for full in-container runtime parity." >&2
  fi
  replace_raw_setting "writable_roots" '["/"]'

  if [ -n "${ROLE_PROJECT_DOC_FALLBACK_FILENAMES:-}" ]; then
    replace_raw_setting "project_doc_fallback_filenames" "$ROLE_PROJECT_DOC_FALLBACK_FILENAMES"
  fi

  echo "Applied role profile '${ROLE_PROFILE}'."
}

apply_role_git_identity() {
  if [ -z "${ROLE_GIT_IDENTITY_NAME:-}" ] || [ -z "${ROLE_GIT_IDENTITY_EMAIL:-}" ]; then
    echo "Warning: role git identity is not fully configured (ROLE_GIT_IDENTITY_NAME/ROLE_GIT_IDENTITY_EMAIL); skipping global git identity setup." >&2
    return
  fi

  if ! command -v git >/dev/null 2>&1; then
    echo "Warning: git is not available; skipping global git identity setup." >&2
    return
  fi

  git config --global user.name "${ROLE_GIT_IDENTITY_NAME}"
  git config --global user.email "${ROLE_GIT_IDENTITY_EMAIL}"

  echo "Applied global git identity '${ROLE_GIT_IDENTITY_NAME} <${ROLE_GIT_IDENTITY_EMAIL}>'."
}

render_runtime_role_instructions() {
  local workspace_agents_file="${WORKSPACE_REPO_DIR}/AGENTS.md"
  local target_file="${RUNTIME_ROLE_INSTRUCTIONS_FILE}"
  local allow_fallback_normalized
  local agents_status="available"
  local fallback_note=""

  mkdir -p "$(dirname "$target_file")"

  allow_fallback_normalized="$(printf '%s' "$ALLOW_FALLBACK_INSTRUCTIONS" | tr '[:upper:]' '[:lower:]')"

  if [ ! -r "$workspace_agents_file" ]; then
    agents_status="missing"
  fi

  if [ "$agents_status" = "missing" ]; then
    if [ "$allow_fallback_normalized" = "true" ]; then
      fallback_note="Break-glass note: ALLOW_FALLBACK_INSTRUCTIONS=true is enabled for operators, but role-repo AGENTS.md remains canonical."
    else
      echo "Warning: required role-repo AGENTS.md is missing or unreadable: ${workspace_agents_file}" >&2
      echo "Runtime instructions will remain in bootstrap-only mode until role-repo AGENTS.md is available." >&2
    fi
  fi

  cat > "$target_file" <<EOF
# Runtime Role Instructions (Bootstrap Loader)

Generated by .devcontainer-workstation/scripts/init-workstation.sh

- Role profile: ${ROLE_PROFILE}
- Role workspace repo: ${WORKSPACE_REPO_DIR}
- Canonical role contract: ${workspace_agents_file}
- AGENTS availability: ${agents_status}

## Required behavior

1. Treat role-repo AGENTS.md as canonical instructions for role mission, authority boundaries, and workflow execution.
2. If AGENTS.md is missing/unreadable, perform bootstrap actions only until it is restored.
3. Once AGENTS.md is available, follow it and treat this file as a loader/adapter only.

## Allowed bootstrap-only actions (before AGENTS is available)

- Clone/fetch/sync the role workspace repo at ${WORKSPACE_REPO_URL}
- Resolve role GitHub auth issues (including deterministic app-auth re-mint)
- Verify AGENTS.md readability and source metadata
- Report blockers preventing AGENTS.md availability

## Prohibited until AGENTS is available

- Do not execute normal role work beyond bootstrap/recovery actions.
- Do not reinterpret role authority boundaries without canonical AGENTS.md.

## Recovery hint

If AGENTS.md is unavailable, restore it by ensuring the role repo exists and is up to date at:

- ${WORKSPACE_REPO_DIR}

${fallback_note}
EOF

  chmod 444 "$target_file"
  echo "Generated runtime role bootstrap instructions at ${target_file}."
}

render_instruction_adapter_files() {
  local target_file="${RUNTIME_ROLE_INSTRUCTIONS_FILE}"
  local agents_file="${RUNTIME_AGENTS_ADAPTER_FILE}"
  local copilot_file="${RUNTIME_COPILOT_INSTRUCTIONS_FILE}"
  local continue_file="${RUNTIME_CONTINUE_INSTRUCTIONS_FILE}"
  local runtime_policy_file="${RUNTIME_AGENT_RUNTIME_POLICY_FILE}"

  mkdir -p "$(dirname "$agents_file")"
  mkdir -p "$(dirname "$copilot_file")"
  mkdir -p "$(dirname "$continue_file")"
  mkdir -p "$(dirname "$runtime_policy_file")"

  {
    echo "# Runtime Agent Access Policy"
    echo
    echo "Generated by .devcontainer-workstation/scripts/init-workstation.sh"
    echo
    echo "Role workstations intentionally run all in-container agent runtimes with full container-local access."
    echo
    echo "Policy applies to:"
    echo "- Codex"
    echo "- Copilot"
    echo "- Continue"
    echo "- Future in-container integrations"
    echo
    echo "Expected behavior: routine operations do not require approval prompts, including temp-path operations such as /tmp and mktemp."
    echo
    echo "Safety model: role-scoped isolated containers + role-attributed execution."
  } > "$runtime_policy_file"

  {
    echo "# Runtime Agent Instructions Adapter"
    echo
    echo "Generated by .devcontainer-workstation/scripts/init-workstation.sh"
    echo
    echo "Use the canonical runtime role instructions in \`${RUNTIME_ROLE_INSTRUCTIONS_FILE}\`."
    echo
    echo "Apply runtime access policy from \`${runtime_policy_file}\`."
    echo
    echo "- Role profile: ${ROLE_PROFILE}"
    echo "- Canonical instructions file: \`${RUNTIME_ROLE_INSTRUCTIONS_FILE}\`"
    echo "- Runtime access policy file: \`${runtime_policy_file}\`"
    echo
    echo "If \`${RUNTIME_ROLE_INSTRUCTIONS_FILE}\` is missing or unreadable, escalate."
  } > "$agents_file"

  {
    echo "# Runtime Copilot Instructions Adapter"
    echo
    echo "Generated by .devcontainer-workstation/scripts/init-workstation.sh"
    echo
    echo "Use the canonical runtime role instructions at:"
    echo
    echo "- \`${RUNTIME_ROLE_INSTRUCTIONS_FILE}\`"
    echo "- \`${runtime_policy_file}\`"
    echo "- Role profile: ${ROLE_PROFILE}"
    echo
    echo "Do not reinterpret or override role authority boundaries defined there."
  } > "$copilot_file"

  {
    echo "# Runtime Continue Instructions Adapter"
    echo
    echo "Generated by .devcontainer-workstation/scripts/init-workstation.sh"
    echo
    echo "Use the canonical runtime role instructions at:"
    echo
    echo "- \`${RUNTIME_ROLE_INSTRUCTIONS_FILE}\`"
    echo "- \`${runtime_policy_file}\`"
    echo "- Role profile: ${ROLE_PROFILE}"
    echo
    echo "Do not reinterpret or override role authority boundaries defined there."
  } > "$continue_file"

  chmod 444 "$runtime_policy_file" "$agents_file" "$copilot_file" "$continue_file"

  if [ ! -f "$target_file" ]; then
    echo "Warning: canonical runtime role instructions file '${target_file}' was not found when generating adapter files." >&2
  fi

  echo "Generated runtime access policy at ${runtime_policy_file}."
  echo "Generated instruction adapter files at ${agents_file}, ${copilot_file}, and ${continue_file}."
}

ensure_workspace_vscode_settings() {
  local settings_file="${RUNTIME_VSCODE_SETTINGS_FILE}"
  local settings_dir
  local defaults_json

  settings_dir="$(dirname "$settings_file")"
  mkdir -p "$settings_dir"

  defaults_json='{
  "github.copilot.chat.codeGeneration.useInstructionFiles": true,
  "chat.useAgentsMdFile": true,
  "chat.includeApplyingInstructions": true,
  "chat.includeReferencedInstructions": true
}'

  if command -v jq >/dev/null 2>&1; then
    local tmp_file
    tmp_file="$(mktemp)"

    if [ -f "$settings_file" ] && jq -e . "$settings_file" >/dev/null 2>&1; then
      jq -S -s '.[0] * .[1]' "$settings_file" <(printf '%s\n' "$defaults_json") > "$tmp_file"
    else
      printf '%s\n' "$defaults_json" | jq -S . > "$tmp_file"
    fi

    mv "$tmp_file" "$settings_file"
  else
    printf '%s\n' "$defaults_json" > "$settings_file"
  fi

  chmod 444 "$settings_file"
  echo "Ensured workstation VS Code chat settings at ${settings_file}."
}

ensure_vscode_machine_settings() {
  local settings_file="${RUNTIME_VSCODE_MACHINE_SETTINGS_FILE}"
  local settings_dir
  local defaults_json

  settings_dir="$(dirname "$settings_file")"
  mkdir -p "$settings_dir"

  defaults_json='{
  "chat.tools.global.autoApprove": true,
  "chat.tools.terminal.enableAutoApprove": true,
  "chat.tools.terminal.autoApprove": {
    "/.*/": true
  }
}'

  if command -v jq >/dev/null 2>&1; then
    local tmp_file
    tmp_file="$(mktemp)"

    if [ -f "$settings_file" ] && jq -e . "$settings_file" >/dev/null 2>&1; then
      jq -S -s '.[0] * .[1]' "$settings_file" <(printf '%s\n' "$defaults_json") > "$tmp_file"
    else
      printf '%s\n' "$defaults_json" | jq -S . > "$tmp_file"
    fi

    mv "$tmp_file" "$settings_file"
  else
    printf '%s\n' "$defaults_json" > "$settings_file"
  fi

  chmod 600 "$settings_file"
  echo "Ensured VS Code machine settings at ${settings_file}."
}

write_runtime_github_app_auth_metadata() {
  local metadata_file="${RUNTIME_GITHUB_APP_AUTH_METADATA_FILE}"
  mkdir -p "$(dirname "$metadata_file")"

  {
    echo "# Runtime GitHub App auth metadata"
    echo "# Generated by .devcontainer-workstation/scripts/init-workstation.sh"
    printf 'RUNTIME_ROLE_PROFILE=%q\n' "${ROLE_PROFILE:-}"
    printf 'RUNTIME_ROLE_GITHUB_AUTH_MODE=%q\n' "${ROLE_GITHUB_AUTH_MODE:-}"
    printf 'RUNTIME_ROLE_GITHUB_APP_ID=%q\n' "${ROLE_GITHUB_APP_ID:-}"
    printf 'RUNTIME_ROLE_GITHUB_APP_INSTALLATION_ID=%q\n' "${ROLE_GITHUB_APP_INSTALLATION_ID:-}"
    printf 'RUNTIME_ROLE_GITHUB_APP_PRIVATE_KEY_PATH=%q\n' "${ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-}"
  } > "$metadata_file"

  chmod 444 "$metadata_file"
  echo "Generated runtime GitHub App auth metadata at ${metadata_file}."
}


mkdir -p "$CODEX_HOME_DIR"

# Seed CODEX_HOME with repo-defined defaults when no config exists yet.
if [ ! -f "$TARGET_CONFIG" ]; then
  cp "$DEFAULT_CONFIG" "$TARGET_CONFIG"
  chmod 600 "$TARGET_CONFIG"
fi

apply_role_profile
apply_role_git_identity
write_runtime_github_app_auth_metadata

if [ "${ROLE_GITHUB_AUTH_MODE:-}" = "app" ]; then
  missing_vars=()
  if [ -z "${ROLE_GITHUB_APP_ID:-}" ]; then
    missing_vars+=("ROLE_GITHUB_APP_ID")
  fi
  if [ -z "${ROLE_GITHUB_APP_INSTALLATION_ID:-}" ]; then
    missing_vars+=("ROLE_GITHUB_APP_INSTALLATION_ID")
  fi
  if [ -z "${ROLE_GITHUB_APP_PRIVATE_KEY_PATH:-}" ]; then
    missing_vars+=("ROLE_GITHUB_APP_PRIVATE_KEY_PATH")
  fi

  if [ "${#missing_vars[@]}" -gt 0 ]; then
    printf 'Warning: ROLE_GITHUB_AUTH_MODE=app but missing %s; skipping role app auth.\n' "${missing_vars[*]}" >&2
  else
    if [ -x "$ROLE_GITHUB_APP_AUTH_SCRIPT" ]; then
      "$ROLE_GITHUB_APP_AUTH_SCRIPT"
    else
      echo "Warning: role GitHub App auth helper not found at ${ROLE_GITHUB_APP_AUTH_SCRIPT}; skipping." >&2
    fi
  fi
fi

if [ "${ROLE_GITHUB_AUTH_MODE:-}" = "app" ] && [ -n "${GH_BOOTSTRAP_TOKEN:-}" ]; then
  echo "Warning: GH_BOOTSTRAP_TOKEN is ignored when ROLE_GITHUB_AUTH_MODE=app to preserve role-attributed GitHub App identity." >&2
fi

if [ "${ROLE_GITHUB_AUTH_MODE:-}" != "app" ] && [ -n "${GH_BOOTSTRAP_TOKEN:-}" ] && command -v gh >/dev/null 2>&1; then
  if ! gh auth status --hostname github.com >/dev/null 2>&1; then
    if printf '%s' "$GH_BOOTSTRAP_TOKEN" | env -u GH_TOKEN -u GITHUB_TOKEN gh auth login --hostname github.com --git-protocol https --with-token >/dev/null 2>&1; then
      gh auth setup-git >/dev/null 2>&1 || true
      echo "Initialized GitHub auth from GH_BOOTSTRAP_TOKEN."
    else
      echo "Warning: failed to initialize GitHub auth from GH_BOOTSTRAP_TOKEN." >&2
    fi
  fi
fi

if [ "$AUTO_CLONE_WORKSPACE_REPO" = "true" ]; then
  mkdir -p "$(dirname "$WORKSPACE_REPO_DIR")"
  if [ ! -d "$WORKSPACE_REPO_DIR/.git" ]; then
    if [ -d "$WORKSPACE_REPO_DIR" ] && [ -n "$(ls -A "$WORKSPACE_REPO_DIR" 2>/dev/null || true)" ]; then
      echo "Skipping auto-clone; $WORKSPACE_REPO_DIR exists and is not empty."
    else
      if git clone "$WORKSPACE_REPO_URL" "$WORKSPACE_REPO_DIR" >/dev/null 2>&1; then
        echo "Auto-cloned $WORKSPACE_REPO_URL to $WORKSPACE_REPO_DIR."
      else
        echo "Warning: auto-clone failed for $WORKSPACE_REPO_URL." >&2
      fi
    fi
  fi
fi

render_runtime_role_instructions
render_instruction_adapter_files
ensure_workspace_vscode_settings
ensure_vscode_machine_settings

exec "$@"
