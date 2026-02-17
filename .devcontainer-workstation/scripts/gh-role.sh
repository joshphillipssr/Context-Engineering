#!/usr/bin/env bash
set -euo pipefail

REMINT_HELPER="${REMINT_HELPER:-/usr/local/bin/remint-role-github-app-auth.sh}"
MODE="${ROLE_GITHUB_AUTH_MODE:-${RUNTIME_ROLE_GITHUB_AUTH_MODE:-}}"

auth_ok() {
  env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --hostname github.com >/dev/null 2>&1
}

if ! auth_ok && [ "$MODE" = "app" ] && [ -x "$REMINT_HELPER" ]; then
  "$REMINT_HELPER" >/dev/null
fi

exec env -u GH_TOKEN -u GITHUB_TOKEN gh "$@"
