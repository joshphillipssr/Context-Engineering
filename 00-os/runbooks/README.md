# Operational Runbooks

This directory contains operational runbooks for Context-Engineering infrastructure and role agent operations.

## Purpose

Runbooks provide step-by-step procedures for:
- Incident response and troubleshooting
- Routine operational tasks
- Escalation and approval workflows
- Emergency procedures

## Available Runbooks

### [Role Workstation Bootstrap](./role-workstation-bootstrap.md)

**When to use:** Understanding workstation container startup behavior, troubleshooting VS Code command approval prompts, or debugging role configuration issues

**Scope:** All role workstation containers (local builds and GHCR published images)

**Key processes:**
- Automated bootstrap sequence and what gets seeded at startup
- VS Code machine settings for persistent command auto-approval
- Role GitHub App authentication setup and validation
- Runtime instruction generation and AGENTS.md canonical contract
- Common troubleshooting procedures and override mechanisms

**Related scripts:** `.devcontainer-workstation/scripts/init-workstation.sh`, `setup-role-github-app-auth.sh`, `remint-role-github-app-auth.sh`

### [GitHub App Bootstrap Validation](./github-app-bootstrap-validation.md)

**When to use:** New role onboarding or debugging role agent authentication failures

**Scope:** All role-specific GitHub Apps during setup and ongoing operations

**Key processes:**
- Validate GitHub App creation and naming
- Verify organization secrets configuration
- Validate required app-id/private-key secret conventions and installation ID detection
- Check app installation on required repositories
- Manual setup checklist for new roles
- Troubleshooting auth failures

**Related script:** `00-os/scripts/validate-github-app-setup.sh`

### [GitHub App Permission Escalation](./github-app-permission-escalation.md)

**When to use:** Role agent operations fail due to missing GitHub App permissions

**Scope:** All role-specific GitHub Apps (Implementation Specialist, Compliance Officer, Systems Architect, and future roles)

**Key processes:**
- Detection and triage of permission failures
- Evidence capture and analysis
- Escalation and approval workflow
- Manual permission update procedures
- Post-update validation
- Rollback procedures

**Related template:** `10-templates/permission-escalation-request.md`

---

## Runbook Standards

All runbooks should include:

1. **Clear scope and triggers** - When to use this runbook
2. **Role-agnostic design** - Applicable across current and future roles where possible
3. **Evidence requirements** - What to capture for analysis
4. **Approval authorities** - Who authorizes actions at each step
5. **Automation vs manual** - Clear distinction of what requires human action
6. **Validation procedures** - How to verify success
7. **Rollback procedures** - How to revert if needed
8. **Related documentation** - Links to governance, charters, templates

## Contributing

New runbooks should:
- Follow the existing format and structure
- Be added to the list above with clear description
- Include maintenance/review schedule
- Specify runbook owner role
- Be referenced in related templates or governance docs

## Maintenance

Runbooks should be reviewed:
- After each incident that uses the runbook
- Quarterly for correctness and completeness
- When governance or role structures change
- When tooling or automation capabilities change
