#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  exo-with-az-token.sh [--org <tenant-domain>] [--resource <aad-resource>] [--] [powershell-snippet]

Examples:
  exo-with-az-token.sh
  exo-with-az-token.sh -- "Get-OrganizationConfig | Select-Object DisablePlusAddressInRecipients"
  exo-with-az-token.sh --org cfhidta.org -- "Get-Mailbox support@cfhidta.org | Select-Object PrimarySmtpAddress"

Notes:
  - Requires an active 'az login' session.
  - Uses AccessToken auth for Connect-ExchangeOnline to avoid repeated interactive prompts.
  - If no snippet is provided, defaults to:
      Get-OrganizationConfig | Select-Object DisablePlusAddressInRecipients
EOF
}

require_bin() {
  local bin="$1"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Missing required command: $bin" >&2
    exit 1
  fi
}

org=""
resource="https://outlook.office365.com"
snippet=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org)
      [[ $# -ge 2 ]] || { echo "Missing value for --org" >&2; exit 1; }
      org="$2"
      shift 2
      ;;
    --resource)
      [[ $# -ge 2 ]] || { echo "Missing value for --resource" >&2; exit 1; }
      resource="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      if [[ $# -gt 0 ]]; then
        snippet="$*"
      fi
      break
      ;;
    *)
      snippet="$*"
      break
      ;;
  esac
done

require_bin az
require_bin pwsh

if [[ -z "$org" ]]; then
  # Prefer explicit org when provided; otherwise infer from current az account context.
  org="$(az account show --query tenantDefaultDomain -o tsv 2>/dev/null || true)"
fi

if [[ -z "$org" ]]; then
  echo "Unable to determine organization. Pass --org <tenant-domain> (for example: cfhidta.org)." >&2
  exit 1
fi

token="$(az account get-access-token --resource "$resource" --query accessToken -o tsv)"
if [[ -z "$token" ]]; then
  echo "Failed to obtain access token from Azure CLI. Run 'az login' and retry." >&2
  exit 1
fi

if [[ -z "$snippet" ]]; then
  snippet="Get-OrganizationConfig | Select-Object DisablePlusAddressInRecipients"
fi

EXO_ACCESS_TOKEN="$token" EXO_ORGANIZATION="$org" EXO_SNIPPET="$snippet" pwsh -NoLogo -NoProfile -Command '
Import-Module ExchangeOnlineManagement -ErrorAction Stop
Connect-ExchangeOnline -ShowBanner:$false -AccessToken $env:EXO_ACCESS_TOKEN -Organization $env:EXO_ORGANIZATION -ErrorAction Stop | Out-Null
try {
  & ([ScriptBlock]::Create($env:EXO_SNIPPET))
} finally {
  Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}
'
