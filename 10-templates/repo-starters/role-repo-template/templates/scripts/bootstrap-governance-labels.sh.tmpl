#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/bootstrap-governance-labels.sh --repo <owner/repo> [--dry-run]

Examples:
  scripts/bootstrap-governance-labels.sh --repo Josh-Phillips-LLC/mcp-auth-broker
  scripts/bootstrap-governance-labels.sh --repo Josh-Phillips-LLC/Context-Engineering --dry-run
USAGE
}

repo=""
dry_run="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run="true"
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

if [ -z "$repo" ]; then
  echo "Missing required --repo <owner/repo>" >&2
  usage
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required" >&2
  exit 1
fi

labels=(
  "role:implementation-specialist|0052CC|Implementation role"
  "role:compliance-officer|5319E7|Compliance review role"
  "role:systems-architect|0B7285|System architecture role"
  "role:hr-ai-agent-specialist|1D76DB|HR + AI Agent Specialist role"
  "role:ai-governance-manager|1D76DB|AI Governance Manager role"
  "role:business-analyst|0E8A16|Business analysis role"
  "role:executive-sponsor|B60205|Executive Sponsor role"
  "status:needs-review|FBCA04|Awaiting review"
  "status:changes-requested|D93F0B|Changes requested by reviewer"
  "status:approved|0E8A16|Approved by reviewer"
  "status:merged|6F42C1|PR has been merged"
  "status:closed|6A737D|PR has been closed without merge"
  "status:superseded|5319E7|PR superseded by another PR"
)

for spec in "${labels[@]}"; do
  IFS='|' read -r name color description <<<"$spec"
  if [ "$dry_run" = "true" ]; then
    echo "[dry-run] gh label create \"$name\" -R \"$repo\" --color \"$color\" --description \"$description\" --force"
    continue
  fi
  gh label create "$name" -R "$repo" --color "$color" --description "$description" --force >/dev/null
  echo "Ensured label: $name"
done

echo "Canonical governance labels are ready for $repo"
