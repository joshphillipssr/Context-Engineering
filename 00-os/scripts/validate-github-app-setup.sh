#!/usr/bin/env bash
set -euo pipefail

# Validate GitHub App setup for a role
# This script checks that role-specific GitHub App is properly configured
# with required secrets and installation permissions.

usage() {
  cat <<'EOF'
Usage:
  validate-github-app-setup.sh --role-slug <role-slug> [--org <org>]

Required:
  --role-slug   Role slug (e.g., implementation-specialist)

Optional:
  --org         GitHub organization (default: Josh-Phillips-LLC)

Examples:
  ./validate-github-app-setup.sh --role-slug implementation-specialist
  ./validate-github-app-setup.sh --role-slug compliance-officer --org MyOrg

Requirements:
  - gh CLI authenticated with org admin permissions
  - GitHub App must be created and installed
  - Org secrets must be configured
EOF
}

ROLE_SLUG=""
ORG="Josh-Phillips-LLC"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --role-slug)
      ROLE_SLUG="$2"
      shift 2
      ;;
    --org)
      ORG="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [ -z "$ROLE_SLUG" ]; then
  echo "❌ Missing required argument: --role-slug" >&2
  usage >&2
  exit 1
fi

echo "=== GitHub App Setup Validation for ${ROLE_SLUG} ==="
echo "Organization: ${ORG}"
echo ""

# Determine expected secret names based on role slug naming convention.
# Convention:
#   <role-slug> -> <ROLE_SLUG_UPPER_SNAKE>_APP_ID / _APP_PRIVATE_KEY
role_secret_prefix="$(
  printf '%s' "$ROLE_SLUG" \
    | tr '[:lower:]' '[:upper:]' \
    | sed -E 's/[^A-Z0-9]+/_/g; s/^_+//; s/_+$//; s/_+/_/g'
)"

if [ -z "$role_secret_prefix" ]; then
  echo "❌ Could not derive secret naming prefix from role slug: ${ROLE_SLUG}" >&2
  exit 1
fi

APP_ID_SECRET="${role_secret_prefix}_APP_ID"
PRIVATE_KEY_SECRET="${role_secret_prefix}_APP_PRIVATE_KEY"

validation_errors=0
validation_warnings=0
context_repo="Context-Engineering"
role_repo="context-engineering-role-${ROLE_SLUG}"
role_slug_compact="$(
  printf '%s' "$ROLE_SLUG" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cd '[:alnum:]'
)"
if [ -z "$role_slug_compact" ]; then
  echo "❌ Could not derive app slug naming from role slug: ${ROLE_SLUG}" >&2
  exit 1
fi
EXPECTED_APP_SLUG_PRIMARY="a-${role_slug_compact}"
EXPECTED_APP_SLUG_LEGACY="context-engineering-${ROLE_SLUG}"

# Check 0: Verify gh authentication
echo "🔐 Checking gh authentication..."
if gh auth status >/dev/null 2>&1; then
  echo "  ✅ gh CLI authenticated"
else
  echo "  ❌ gh CLI is not authenticated"
  echo ""
  echo "Authenticate and retry:"
  echo "  gh auth login"
  echo "  gh auth status"
  exit 1
fi
echo ""

# Check 1: Verify org secrets exist
echo "📋 Checking organization secrets..."
app_id_exists="false"
private_key_exists="false"
org_secret_list="$(gh secret list --org "$ORG" || true)"

if printf '%s\n' "$org_secret_list" | grep -q "^${APP_ID_SECRET}[[:space:]]"; then
  echo "  ✅ ${APP_ID_SECRET} exists"
  app_id_exists="true"
else
  echo "  ❌ ${APP_ID_SECRET} NOT FOUND"
  validation_errors=$((validation_errors + 1))
fi

if printf '%s\n' "$org_secret_list" | grep -q "^${PRIVATE_KEY_SECRET}[[:space:]]"; then
  echo "  ✅ ${PRIVATE_KEY_SECRET} exists"
  private_key_exists="true"
else
  echo "  ❌ ${PRIVATE_KEY_SECRET} NOT FOUND"
  validation_errors=$((validation_errors + 1))
fi

echo ""

# Check 2: Verify app installation (requires secrets to query)
if [ "$app_id_exists" = "true" ] && [ "$private_key_exists" = "true" ]; then
  echo "📦 Checking GitHub App installation..."
  
  # Try to query installations using gh API
  installations=$(
    gh api "/orgs/${ORG}/installations" --jq '.installations[] | [.app_slug, (.id|tostring)] | @tsv' 2>/dev/null || true
  )

  matched_slug=""
  matched_installation_id=""
  for expected in "$EXPECTED_APP_SLUG_PRIMARY" "$EXPECTED_APP_SLUG_LEGACY"; do
    matched_row="$(printf '%s\n' "$installations" | awk -F'\t' -v expected="$expected" '$1==expected {print $0; exit}')"
    if [ -n "$matched_row" ]; then
      matched_slug="$(printf '%s' "$matched_row" | awk -F'\t' '{print $1}')"
      matched_installation_id="$(printf '%s' "$matched_row" | awk -F'\t' '{print $2}')"
      break
    fi
  done

  if [ -n "$matched_slug" ]; then
    echo "  ✅ App installed: ${matched_slug}"
    echo "  ✅ Installation ID detected: ${matched_installation_id}"
  else
    echo "  ⚠️  Cannot confirm app installation for role '${ROLE_SLUG}'"
    echo "     Expected one of:"
    echo "     - ${EXPECTED_APP_SLUG_PRIMARY}"
    echo "     - ${EXPECTED_APP_SLUG_LEGACY}"
    echo "     Found installed apps:"
    if [ -n "$installations" ]; then
      printf '%s\n' "$installations" | awk -F'\t' '{print "     - " $1 " (installation_id=" $2 ")"}'
    else
      echo "     (none found)"
    fi
    validation_warnings=$((validation_warnings + 1))
  fi
  
  echo ""
  
  # Check 3: Verify installation visibility on target repos
  echo "🔍 Checking installation visibility..."

  for repo in "$context_repo" "$role_repo"; do
    repo_exists=$(gh repo view "${ORG}/${repo}" --json name --jq '.name' 2>/dev/null || echo "")
    if [ -z "$repo_exists" ]; then
      echo "  ⚠️  Repository ${ORG}/${repo} not accessible (may not exist yet)"
      validation_warnings=$((validation_warnings + 1))
      continue
    fi
    
    # Note: Cannot reliably check app installation on specific repo via gh CLI
    # This would require authenticated app token, which we're validating the setup for
    echo "  ℹ️  Repository ${ORG}/${repo} exists"
  done
  
  echo ""
else
  echo "⏭️  Skipping installation checks (secrets not configured)"
  echo ""
fi

# Check 4: Validate naming conventions
echo "📝 Validating naming conventions..."
echo "   Expected App Slug (current): ${EXPECTED_APP_SLUG_PRIMARY}"
echo "   Expected App Slug (legacy): ${EXPECTED_APP_SLUG_LEGACY}"
echo "   Expected Secrets:"
echo "     - ${APP_ID_SECRET}"
echo "     - ${PRIVATE_KEY_SECRET}"
echo "   Installation ID source: GitHub App installations API (/orgs/${ORG}/installations)"
echo ""

# Summary
echo "=== Validation Summary ==="
if [ "$validation_errors" -eq 0 ] && [ "$validation_warnings" -eq 0 ]; then
  echo "✅ All checks passed"
  exit 0
elif [ "$validation_errors" -eq 0 ]; then
  echo "⚠️  ${validation_warnings} warning(s) - review recommended"
  echo ""
  echo "Common warnings:"
  echo "- App installation cannot be fully verified via CLI"
  echo "- Role repository may not exist yet (normal during onboarding)"
  echo ""
  echo "Manual verification steps:"
  echo "1. Visit: https://github.com/organizations/${ORG}/settings/apps"
  echo "2. Verify ${EXPECTED_APP_SLUG_PRIMARY} (or ${EXPECTED_APP_SLUG_LEGACY}) exists and is configured"
  echo "3. Visit: https://github.com/organizations/${ORG}/settings/installations"
  echo "4. Verify the role app is installed on Context-Engineering and role repo"
  exit 0
else
  echo "❌ ${validation_errors} error(s), ${validation_warnings} warning(s)"
  echo ""
  echo "Resolution steps:"
  echo ""
  echo "1. Create GitHub App:"
  echo "   - Visit: https://github.com/organizations/${ORG}/settings/apps/new"
  echo "   - Name: ${EXPECTED_APP_SLUG_PRIMARY}"
  echo "   - Configure required permissions (see role charter)"
  echo ""
  echo "2. Install GitHub App:"
  echo "   - Visit App settings → Install App"
  echo "   - Select ${ORG}"
  echo "   - Grant access to Context-Engineering and ${role_repo}"
  echo ""
  echo "3. Configure org secrets:"
  echo "   gh secret set ${APP_ID_SECRET} --org ${ORG} --body \"<app_id>\""
  echo "   gh secret set ${PRIVATE_KEY_SECRET} --org ${ORG} < path/to/${ROLE_SLUG}.private-key.pem"
  echo ""
  echo "4. Verify installation visibility:"
  echo "   gh api /orgs/${ORG}/installations"
  echo ""
  exit 1
fi
