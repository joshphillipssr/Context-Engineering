#!/usr/bin/env bash
set -euo pipefail

REMINT_HELPER="${REMINT_HELPER:-/usr/local/bin/remint-role-github-app-auth.sh}"
MODE="${ROLE_GITHUB_AUTH_MODE:-${RUNTIME_ROLE_GITHUB_AUTH_MODE:-}}"

gh_cmd() {
  env -u GH_TOKEN -u GITHUB_TOKEN gh "$@"
}

auth_status_ok() {
  env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --hostname github.com >/dev/null 2>&1
}

auth_api_ok() {
  gh_cmd api graphql -f query='query { viewer { login } }' --jq '.data.viewer.login' >/dev/null 2>&1
}

if [ "$MODE" = "app" ] && [ -x "$REMINT_HELPER" ]; then
  if ! auth_status_ok || ! auth_api_ok; then
    "$REMINT_HELPER" >/dev/null
  fi
fi

exec env -u GH_TOKEN -u GITHUB_TOKEN gh "$@"
