# Operational Runbooks

This directory contains operational runbooks for Context-Engineering infrastructure and role agent operations.

## Purpose

Runbooks provide step-by-step procedures for:
- Incident response and troubleshooting
- Routine operational tasks
- Escalation and approval workflows
- Emergency procedures

## Available Runbooks

### [GitHub App Bootstrap Validation](./github-app-bootstrap-validation.md)

**When to use:** New role onboarding or debugging role agent authentication failures

**Scope:** All role-specific GitHub Apps during setup and ongoing operations

**Key processes:**
- Validate GitHub App creation and naming
- Verify organization secrets configuration
- Check app installation on required repositories
- Manual setup checklist for new roles
- Troubleshooting auth failures

**Related script:** `00-os/scripts/validate-github-app-setup.sh`

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
