#!/usr/bin/env bash
set -euo pipefail

# Deterministic runtime policy validation script for role workstations.
# Verifies that generated instruction adapters and enforced runtime policy
# values persist after init-workstation.sh and meet full in-container access
# parity requirements.

WORKSTATION_DEBUG="${WORKSTATION_DEBUG:-false}"

if [ "$WORKSTATION_DEBUG" = "true" ]; then
  set -x
  echo "Debug mode enabled for verify-runtime-policy.sh"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Expected generated files
RUNTIME_POLICY_FILE="${RUNTIME_AGENT_RUNTIME_POLICY_FILE:-/workspace/instructions/agent-runtime-policy.md}"
RUNTIME_AGENTS_ADAPTER_FILE="${RUNTIME_AGENTS_ADAPTER_FILE:-/workspace/instructions/AGENTS.md}"
RUNTIME_COPILOT_INSTRUCTIONS_FILE="${RUNTIME_COPILOT_INSTRUCTIONS_FILE:-/workspace/instructions/copilot-instructions.md}"
RUNTIME_CONTINUE_INSTRUCTIONS_FILE="${RUNTIME_CONTINUE_INSTRUCTIONS_FILE:-/workspace/instructions/continue-instructions.md}"
CODEX_CONFIG_FILE="${CODEX_HOME:-/root/.codex}/config.toml"

# Exit codes for validation results
EXIT_OK=0
EXIT_MISSING_FILE=1
EXIT_POLICY_MISMATCH=2
EXIT_ADAPTER_MISMATCH=4

exit_code=$EXIT_OK

echo "=== Runtime Policy Verification ==="
echo

# 1. Verify generated runtime policy file exists
if [ ! -f "$RUNTIME_POLICY_FILE" ]; then
  echo "FAIL: Runtime policy file not found: $RUNTIME_POLICY_FILE" >&2
  exit_code=$((exit_code | EXIT_MISSING_FILE))
else
  echo "PASS: Runtime policy file present: $RUNTIME_POLICY_FILE"
  if grep -q "full container-local access" "$RUNTIME_POLICY_FILE"; then
    echo "PASS: Runtime policy documents full container-local access parity"
  else
    echo "FAIL: Runtime policy missing full container-local access language" >&2
    exit_code=$((exit_code | EXIT_POLICY_MISMATCH))
  fi
  missing_runtime_mentions=()
  for runtime_name in Codex Copilot Continue; do
    if ! grep -q "$runtime_name" "$RUNTIME_POLICY_FILE"; then
      missing_runtime_mentions+=("$runtime_name")
    fi
  done
  if [ "${#missing_runtime_mentions[@]}" -eq 0 ]; then
    echo "PASS: Runtime policy covers Codex, Copilot, Continue"
  else
    echo "FAIL: Runtime policy missing runtime mention(s): ${missing_runtime_mentions[*]}" >&2
    exit_code=$((exit_code | EXIT_POLICY_MISMATCH))
  fi
fi

echo

# 2. Verify Codex config enforcement
if [ ! -f "$CODEX_CONFIG_FILE" ]; then
  echo "FAIL: Codex config file not found: $CODEX_CONFIG_FILE" >&2
  exit_code=$((exit_code | EXIT_MISSING_FILE))
else
  echo "PASS: Codex config file present: $CODEX_CONFIG_FILE"

  # Check approval_policy
  if grep -q '^approval_policy = "never"' "$CODEX_CONFIG_FILE"; then
    echo "PASS: Codex approval_policy enforced as 'never'"
  else
    echo "FAIL: Codex approval_policy not set to 'never'" >&2
    exit_code=$((exit_code | EXIT_POLICY_MISMATCH))
  fi

  # Check sandbox_mode
  if grep -q '^sandbox_mode = "danger-full-access"' "$CODEX_CONFIG_FILE"; then
    echo "PASS: Codex sandbox_mode enforced as 'danger-full-access'"
  else
    echo "FAIL: Codex sandbox_mode not set to 'danger-full-access'" >&2
    exit_code=$((exit_code | EXIT_POLICY_MISMATCH))
  fi

  # Check writable_roots fallback
  if grep -qE '^\[sandbox_workspace_write\]' "$CODEX_CONFIG_FILE"; then
    if grep -A 5 '^\[sandbox_workspace_write\]' "$CODEX_CONFIG_FILE" | grep -q 'writable_roots = \["/"\]'; then
      echo "PASS: Codex writable_roots fallback enforced as ['/']"
    else
      echo "FAIL: Codex writable_roots not set to ['/'] in sandbox section" >&2
      exit_code=$((exit_code | EXIT_POLICY_MISMATCH))
    fi
  fi
fi

echo

# 3. Verify adapter files exist and reference policy
for adapter_file in "$RUNTIME_AGENTS_ADAPTER_FILE" "$RUNTIME_COPILOT_INSTRUCTIONS_FILE" "$RUNTIME_CONTINUE_INSTRUCTIONS_FILE"; do
  adapter_name="$(basename "$adapter_file")"
  if [ ! -f "$adapter_file" ]; then
    echo "FAIL: Adapter file not found: $adapter_file" >&2
    exit_code=$((exit_code | EXIT_MISSING_FILE))
  else
    echo "PASS: Adapter file present: $adapter_name"
    if grep -q "agent-runtime-policy.md\|runtime-access policy" "$adapter_file"; then
      echo "PASS: $adapter_name references shared runtime policy"
    else
      echo "FAIL: $adapter_name does not reference shared runtime policy" >&2
      exit_code=$((exit_code | EXIT_ADAPTER_MISMATCH))
    fi
  fi
done

echo
echo "=== Verification Summary ==="
if [ $exit_code -eq $EXIT_OK ]; then
  echo "SUCCESS: All policy validation checks passed."
  exit 0
else
  echo "FAILURE: Policy validation failed with exit code $exit_code" >&2
  exit "$exit_code"
fi
