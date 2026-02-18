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
RUNTIME_VSCODE_SETTINGS_FILE="${RUNTIME_VSCODE_SETTINGS_FILE:-/workspace/settings/vscode/settings.json}"
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

  if [ -n "${ROLE_APPROVAL_POLICY:-}" ]; then
    replace_string_setting "approval_policy" "$ROLE_APPROVAL_POLICY"
  fi

  if [ -n "${ROLE_MODEL_REASONING_EFFORT:-}" ]; then
    replace_string_setting "model_reasoning_effort" "$ROLE_MODEL_REASONING_EFFORT"
  fi

  if [ -n "${ROLE_MODEL_PERSONALITY:-}" ]; then
    replace_string_setting "model_personality" "$ROLE_MODEL_PERSONALITY"
  fi

  if [ -n "${ROLE_WRITABLE_ROOTS:-}" ]; then
    replace_raw_setting "writable_roots" "$ROLE_WRITABLE_ROOTS"
  fi

  if [ -n "${ROLE_PROJECT_DOC_FALLBACK_FILENAMES:-}" ]; then
    replace_raw_setting "project_doc_fallback_filenames" "$ROLE_PROJECT_DOC_FALLBACK_FILENAMES"
  fi

  echo "Applied role profile '${ROLE_PROFILE}'."
}

render_runtime_role_instructions() {
  local workspace_source_dir="${WORKSPACE_REPO_DIR}/${ROLE_INSTRUCTIONS_DIR_REL}"
  local workspace_agents_file="${WORKSPACE_REPO_DIR}/AGENTS.md"
  local source_dir="$workspace_source_dir"
  local source_label="workspace:${ROLE_INSTRUCTIONS_DIR_REL}"
  local base_file="${source_dir}/base.md"
  local role_file="${source_dir}/roles/${ROLE_PROFILE}.md"
  local compliance_brief_file="${WORKSPACE_REPO_DIR}/${COMPLIANCE_REVIEW_BRIEF_WORKSPACE_REL}"
  local compiled_role_file="${BAKED_COMPILED_ROLE_INSTRUCTIONS_DIR}/${ROLE_PROFILE}.md"
  local target_file="${RUNTIME_ROLE_INSTRUCTIONS_FILE}"
  local allow_fallback_normalized

  mkdir -p "$(dirname "$target_file")"

  allow_fallback_normalized="$(printf '%s' "$ALLOW_FALLBACK_INSTRUCTIONS" | tr '[:upper:]' '[:lower:]')"

  if [ -r "$workspace_agents_file" ]; then
    cp "$workspace_agents_file" "$target_file"
    chmod 444 "$target_file"
    echo "Generated runtime role instructions at ${target_file} from workspace role repo AGENTS.md."
    return
  fi

  if [ "$allow_fallback_normalized" != "true" ]; then
    rm -f "$target_file"
    echo "Error: required role-repo AGENTS.md is missing or unreadable: ${workspace_agents_file}" >&2
    echo "Fail-closed instruction loading is active (ALLOW_FALLBACK_INSTRUCTIONS=${ALLOW_FALLBACK_INSTRUCTIONS})." >&2
    echo "Fix role-repo clone/sync at ${WORKSPACE_REPO_URL} or set ALLOW_FALLBACK_INSTRUCTIONS=true for break-glass fallback." >&2
    return 1
  fi

  echo "Warning: ALLOW_FALLBACK_INSTRUCTIONS=true; using fallback instruction sources because ${workspace_agents_file} is unavailable." >&2

  if [ ! -f "$base_file" ] || [ ! -f "$role_file" ]; then
    if [ -f "$compiled_role_file" ]; then
      cp "$compiled_role_file" "$target_file"
      chmod 444 "$target_file"
      echo "Generated runtime role instructions at ${target_file} from baked compiled source ${compiled_role_file}."
      return
    fi

    source_dir="$BAKED_ROLE_INSTRUCTIONS_DIR"
    source_label="image:${BAKED_ROLE_INSTRUCTIONS_DIR}"
    base_file="${source_dir}/base.md"
    role_file="${source_dir}/roles/${ROLE_PROFILE}.md"
    compliance_brief_file="${COMPLIANCE_REVIEW_BRIEF_BAKED}"

    if [ ! -f "$base_file" ] || [ ! -f "$role_file" ]; then
      rm -f "$target_file"
      echo "Warning: missing centralized role instruction sources for '${ROLE_PROFILE}' in both workspace and image fallback; runtime role instructions not generated." >&2
      return
    fi
  fi

  {
    echo "# Runtime Role Instructions"
    echo
    echo "Generated by .devcontainer-workstation/scripts/init-workstation.sh"
    echo "Role profile: ${ROLE_PROFILE}"
    echo "Source: ${source_label}"
    echo
    cat "$base_file"
    echo
    cat "$role_file"

    if [ "$ROLE_PROFILE" = "compliance-officer" ]; then
      if [ ! -f "$compliance_brief_file" ] && [ -f "$COMPLIANCE_REVIEW_BRIEF_BAKED" ]; then
        compliance_brief_file="$COMPLIANCE_REVIEW_BRIEF_BAKED"
      fi

      if [ -f "$compliance_brief_file" ]; then
        echo
        echo "# Embedded Compliance Review Brief"
        echo
        cat "$compliance_brief_file"
      else
        echo
        echo "Warning: compliance review brief source not found; role instructions are missing the embedded PR review brief." >&2
      fi
    fi
  } > "$target_file"

  chmod 444 "$target_file"
  echo "Generated runtime role instructions at ${target_file}."
}

render_instruction_adapter_files() {
  local target_file="${RUNTIME_ROLE_INSTRUCTIONS_FILE}"
  local agents_file="${RUNTIME_AGENTS_ADAPTER_FILE}"
  local copilot_file="${RUNTIME_COPILOT_INSTRUCTIONS_FILE}"

  mkdir -p "$(dirname "$agents_file")"
  mkdir -p "$(dirname "$copilot_file")"

  {
    echo "# Runtime Agent Instructions Adapter"
    echo
    echo "Generated by .devcontainer-workstation/scripts/init-workstation.sh"
    echo
    echo "Use the canonical runtime role instructions in \`${RUNTIME_ROLE_INSTRUCTIONS_FILE}\`."
    echo
    echo "- Role profile: ${ROLE_PROFILE}"
    echo "- Canonical instructions file: \`${RUNTIME_ROLE_INSTRUCTIONS_FILE}\`"
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
    echo "- Role profile: ${ROLE_PROFILE}"
    echo
    echo "Do not reinterpret or override role authority boundaries defined there."
  } > "$copilot_file"

  chmod 444 "$agents_file" "$copilot_file"

  if [ ! -f "$target_file" ]; then
    echo "Warning: canonical runtime role instructions file '${target_file}' was not found when generating adapter files." >&2
  fi

  echo "Generated instruction adapter files at ${agents_file} and ${copilot_file}."
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

exec "$@"
