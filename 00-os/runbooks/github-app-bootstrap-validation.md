# GitHub App Bootstrap Validation Runbook

## Overview

This runbook provides deterministic checks for GitHub App readiness during role onboarding.

## Purpose

GitHub Apps require manual creation and installation by org admins. This validation ensures:
- App is created with correct naming
- Org secrets are configured
- App is installed on required repositories
- Permissions are correctly scoped

## When to Use

- **New role onboarding**: Before running sync/publish workflows
- **Debugging workflow auth failures**: When role agents report GitHub API 403 errors
- **Audit**: Periodic verification of role app configurations

## Validation Script

**Location**: `00-os/scripts/validate-github-app-setup.sh`

### Usage

```bash
# Validate a specific role
./00-os/scripts/validate-github-app-setup.sh --role-slug implementation-specialist

# Validate for different org
./00-os/scripts/validate-github-app-setup.sh --role-slug compliance-officer --org MyOrg

# Help
./00-os/scripts/validate-github-app-setup.sh --help
```

### What It Checks

1. **Organization Secrets**
   - `{ROLE}_APP_ID` exists
   - `{ROLE}_APP_PRIVATE_KEY` exists

2. **App Installation**
   - App slug follows naming convention
   - App is installed in organization
   - Installation ID is detected from org installation data

3. **Repository Access**
   - Context-Engineering repo exists
   - Role repo exists (or warns if not yet created)

4. **Naming Conventions**
   - App slug matches expected pattern
   - Secret naming follows standards

### Exit Codes

- `0`: All checks passed (or warnings only)
- `1`: Errors found - action required

## Naming Conventions

### App Slug
Current pattern in this org: `a-{role-slug-without-hyphens}`  
Legacy/alternate pattern accepted by validator: `context-engineering-{role-slug}`

Examples:
- `a-implementationspecialist`
- `a-complianceofficer`
- `a-systemsarchitect`
- `context-engineering-implementation-specialist`
- `context-engineering-compliance-officer`
- `context-engineering-systems-architect`

### Organization Secrets

**App ID Secret**:
Pattern: `{ROLE_UPPERCASE}_APP_ID`

Examples:
- `IMPLEMENTATION_SPECIALIST_APP_ID`
- `COMPLIANCE_OFFICER_APP_ID`
- `SYSTEMS_ARCHITECT_APP_ID`

**Private Key Secret**:
Pattern: `{ROLE_UPPERCASE}_APP_PRIVATE_KEY`

Examples:
- `IMPLEMENTATION_SPECIALIST_APP_PRIVATE_KEY`
- `COMPLIANCE_OFFICER_APP_PRIVATE_KEY`
- `SYSTEMS_ARCHITECT_APP_PRIVATE_KEY`

### Installation ID Source
Installation IDs are validated from GitHub's installation API, not org secrets:

```bash
gh api /orgs/{ORG}/installations
```

The validator confirms the role app exists in this list and reports the detected installation ID.

## Manual Setup Checklist

When validation reports missing configuration:

### 1. Create GitHub App

1. Navigate to: `https://github.com/organizations/{ORG}/settings/apps/new`
2. Configure:
   - **Name**: `context-engineering-{role-slug}`
   - **Homepage URL**: `https://github.com/{ORG}/Context-Engineering`
   - **Webhook**: Inactive (not needed for role agents)
   - **Permissions**: Per role charter requirements
3. Generate private key and save `.pem` file securely
4. Note the App ID

### 2. Install App

1. Navigate to App settings → "Install App"
2. Select your organization
3. Choose repositories:
   - `Context-Engineering` (required)
   - `context-engineering-role-{role-slug}` (required)
   - Any other repos the role needs access to
4. Approve installation

### 3. Configure Org Secrets

```bash
# Set App ID
gh secret set {ROLE_UPPERCASE}_APP_ID \
  --org {ORG} \
  --body "{app_id}"

# Set Private Key  
gh secret set {ROLE_UPPERCASE}_APP_PRIVATE_KEY \
  --org {ORG} \
  < path/to/{role-slug}.private-key.pem
```

### 4. Verify

```bash
# Run validation again
./00-os/scripts/validate-github-app-setup.sh --role-slug {role-slug}

# Should now pass all checks
```

## Troubleshooting

### Script reports "Cannot confirm app is installed"

**Cause**: Limited CLI visibility into app installations

**Resolution**:
1. Visit: `https://github.com/organizations/{ORG}/settings/installations`
2. Manually verify app appears in list
3. Click "Configure" to verify repository access

### Secret exists but workflows still fail

**Causes**:
- Secret visibility not set to "All repositories" or workflow doesn't have access
- Private key file corrupted or incorrect format
- App permissions insufficient

**Resolution**:
1. Check secret visibility: `gh secret list --org {ORG}`
2. Regenerate app private key if needed
3. Review app permissions vs role charter requirements
4. Check workflow logs for specific error messages

### Role repo doesn't exist yet

**Expected**: During initial role onboarding, role repo may not exist until after first sync.

**Workflow**:
1. Validate app setup (will warn about missing repo)
2. Run sync workflow (creates role repo)
3. Install app on newly created repo
4. Re-validate (should pass)

## Integration with Onboarding

### Recommended Workflow Order

1. **Preflight**: Run validation script
   - Identifies missing setup before attempting workflows
   - Provides specific remediation steps

2. **Setup**: Follow manual checklist if validation fails
   - Create app
   - Install app
   - Configure secrets

3. **Verify**: Re-run validation
   - Confirms setup is correct
   - Catches configuration errors early

4. **Proceed**: Run sync and publish workflows
   - Should succeed without auth errors

## Automation Limitations

**What CAN be automated**:
- Secret existence checks
- Naming convention validation  
- Repository existence checks
- Basic installation list queries

**What CANNOT be automated** (requires GitHub UI + org admin):
- GitHub App creation
- App permission configuration
- App installation approval
- Private key generation

These limitations are GitHub platform constraints, not tooling gaps.

## Future Enhancements

Potential improvements:
- Add to CI as non-blocking check on role onboarding PRs
- Generate app configuration templates (permissions manifest)
- Add monitoring for app installation health
- Create dashboard of role app status across org

## Related Documentation

- **Permission Escalation**: `00-os/runbooks/github-app-permission-escalation.md`
- **Role Onboarding**: `10-templates/agent-work-orders/role-creation-work-order.md`
- **Sync Workflow**: `.github/workflows/sync-role-repos.yml`
