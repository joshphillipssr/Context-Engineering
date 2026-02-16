# GitHub App Permission Escalation Runbook

**Version:** 1.0  
**Last Updated:** 2026-02-16  
**Scope:** All role-specific GitHub Apps

## Purpose

This runbook provides a role-agnostic, deterministic process for detecting, escalating, and resolving GitHub App permission failures across all role agents (Implementation Specialist, Compliance Officer, Systems Architect, and future roles).

## When to Use This Runbook

Use this runbook when:
- Role agent operations fail with HTTP 403 or integration authorization errors
- Agent logs indicate missing GitHub App permissions
- New agent functionality requires additional GitHub API access
- Role app permission audits reveal gaps between required and granted permissions

## Role App Inventory

Current role-specific GitHub Apps:

| Role | App Name Pattern | Secret Prefix | Primary Operations |
|------|------------------|---------------|-------------------|
| Implementation Specialist | `context-engineering-implementation-specialist` | `IMPLEMENTATION_SPECIALIST_` | Code changes, PR creation, branch management |
| Compliance Officer | `context-engineering-compliance-officer` | `COMPLIANCE_OFFICER_` | PR reviews, status checks, issue labeling |
| Systems Architect | `context-engineering-systems-architect` | `SYSTEMS_ARCHITECT_` | Repository analysis, workflow planning |

*(Future roles will be added to this table)*

## Process Overview

```
Detection → Evidence Capture → Analysis → Escalation Request → 
Approval & Update → Validation → Documentation
```

---

## Phase 1: Detection and Triage

### Detection Methods

1. **Agent Runtime Failure**
   - Agent returns HTTP 403 Forbidden errors
   - Agent logs contain "Insufficient permissions" or similar messages
   - GitHub API responses indicate missing scopes/permissions

2. **Proactive Audit**
   - Planned feature requires new API endpoints
   - Role charter updates expand agent responsibilities
   - Security review identifies over-privileged access

### Initial Triage Checklist

- [ ] Verify the error is permission-related (not auth token expiry or network issue)
- [ ] Identify which role app is affected
- [ ] Confirm the app is properly installed on target repositories
- [ ] Check if this is a new operation or regression on existing functionality

---

## Phase 2: Evidence Capture

**Required Information:**

1. **Failing Operation Context**
   - Exact API endpoint or operation attempted
   - Repository/organization scope
   - Agent workflow or task ID
   - Timestamp (UTC)

2. **Error Details**
   - Complete error message
   - HTTP status code
   - Response headers (if available)
   - Relevant log excerpts (sanitize any secrets)

3. **Current Permission State**
   - Navigate to GitHub org settings → GitHub Apps → [Role App]
   - Screenshot or list current repository permissions
   - Screenshot or list current organization permissions
   - Note current installation scope (which repos)

4. **Required Permission**
   - Document the specific GitHub API permission needed
   - Link to GitHub API documentation for the endpoint
   - Specify read vs write access requirement
   - Justify scope (repo-level vs org-level)

**Template Location:** `10-templates/permission-escalation-request.md`

---

## Phase 3: Analysis and Scoping

### Least Privilege Assessment

Before requesting permissions, verify:

1. **Necessity**: Is this permission required for core role functionality?
2. **Scope Minimization**: Can we use a narrower permission?
   - Repo-level vs org-level
   - Read-only vs write
   - Specific resource vs broad category
3. **Alternatives**: Can the goal be achieved via:
   - Different API endpoint with lower permission requirements
   - Workflow redesign
   - Different role handling the operation

### Risk Classification

| Risk Level | Criteria | Approval Authority |
|------------|----------|-------------------|
| **Low** | Read-only repo metadata, public data | Role Charter Owner review |
| **Medium** | Write access to non-protected resources, issue/PR management | Executive Sponsor approval |
| **High** | Protected branch writes, org settings, member management | Executive Sponsor + Security review |

---

## Phase 4: Escalation Request

### Opening a Permission Change Request

1. **Create Issue**
   ```bash
   gh issue create \
     --repo Josh-Phillips-LLC/Context-Engineering \
     --title "GitHub App Permission: [Role] needs [Permission] for [Operation]" \
     --label "role:systems-architect,priority:P1,scope:security" \
     --body-file 10-templates/permission-escalation-request.md
   ```

2. **Fill Required Sections** (see template)
   - Role app affected
   - Failing operation
   - Evidence captured
   - Requested permission with justification
   - Risk assessment
   - Proposed testing plan

3. **Assign for Review**
   - For Medium/High risk: Tag Executive Sponsor
   - For High risk: Also tag compliance/security reviewer

### What Can Be Automated vs Manual

| Action | Automation Capability | Notes |
|--------|----------------------|-------|
| **Permission Request Creation** | ✅ Fully automated | CLI/API driven |
| **App Permission Modification** | ❌ Manual only | Requires GitHub UI + App owner approval |
| **App Re-installation** | ❌ Manual only | Requires org admin approval via GitHub UI |
| **Permission Verification** | ✅ Partially automated | Can query via API, but UI confirmation recommended |
| **Rollback** | ❌ Manual only | GitHub Apps don't support programmatic rollback |

**Platform Limitation:** GitHub does not provide API endpoints to modify GitHub App permissions programmatically. All permission changes require:
1. App owner to update app manifest via GitHub UI
2. Organization admin to approve updated permissions via GitHub UI

---

## Phase 5: Approval and Update

### Approval Workflow

1. **Review Period**
   - Reviewer evaluates justification and risk assessment
   - Reviewer may request scope reduction or alternatives
   - Target response time: 24-48 hours for P1 issues

2. **Approval Signal**
   - Approver comments on issue: "Approved for implementation"
   - For High risk: Requires explicit Executive Sponsor comment

3. **Update Procedure** (Manual - GitHub UI Required)

   **Step 1: Update App Permissions**
   - Navigate to: https://github.com/organizations/Josh-Phillips-LLC/settings/apps
   - Select the role-specific app
   - Click "Permissions & events"
   - Modify requested permission(s)
   - Add changelog note in description
   - Click "Save changes"
   
   **Step 2: Approve Installation Update**
   - GitHub will mark installation as "pending"
   - Navigate to: https://github.com/organizations/Josh-Phillips-LLC/settings/installations
   - Click "Configure" on the role app
   - Review permission changes
   - Click "Accept new permissions"

   **Step 3: Verify Installation Scope**
   - Confirm app is installed on required repositories
   - Verify no unexpected permission grants

---

## Phase 6: Validation

### Post-Update Testing

1. **Retry Failed Operation**
   - Re-run the original failing agent workflow
   - Verify operation succeeds
   - Check for any unexpected side effects

2. **Permission Verification**
   ```bash
   # Query current app installation permissions
   gh api /orgs/Josh-Phillips-LLC/installations \
     --jq '.[] | select(.app_slug == "context-engineering-[role-slug]") | .permissions'
   ```

3. **Regression Check**
   - Verify existing functionality still works
   - Test related operations with similar permission requirements

4. **Evidence of Success**
   - Screenshot or log output showing successful operation
   - Link to successful workflow run or agent task

### Validation Checklist

- [ ] Original failing operation now succeeds
- [ ] No new permission errors introduced
- [ ] App installation shows updated permissions in GitHub UI
- [ ] Related operations still function correctly
- [ ] No unnecessary permissions granted beyond request scope

---

## Phase 7: Documentation and Close-out

### Required Documentation Updates

1. **Update Role App Inventory** (this runbook)
   - If new permission category added, update table above
   - Document which operations require which permissions

2. **Update Role Charter** (if applicable)
   - If new capability is now officially supported, update `00-os/role-charters/[role].md`

3. **Close Issue**
   - Summarize: What was requested, approved, implemented, and validated
   - Reference evidence artifacts
   - Note any follow-up tasks or monitoring required

4. **Audit Trail**
   - Permission change should be logged in:
     - GitHub App update changelog
     - Issue history with approval comments
     - Any security/compliance logs required by governance

---

## Troubleshooting

### Common Issues

**Issue:** Permission change approved but operation still fails  
**Resolution:**
- Verify app installation was updated (check GitHub UI)
- Confirm secret environment variables are current (not stale cached tokens)
- Check if permission requires both repo AND org scope

**Issue:** Can't find where to approve installation update  
**Resolution:**
- Only org admins can approve installation updates
- Navigate directly to: https://github.com/organizations/Josh-Phillips-LLC/settings/installations
- Look for yellow "Review request" banner

**Issue:** Permission seems correct but API still returns 403  
**Resolution:**
- Check rate limiting (X-RateLimit headers)
- Verify repository-level app installation (may be installed on org but not specific repo)
- Confirm endpoint requires App auth (not user auth)
- Check if fine-grained permissions require multiple permission grants

---

## Emergency Rollback

If a permission change causes unexpected issues:

1. **Immediate Mitigation**
   - Disable affected role agent operations (comment out workflow triggers)
   - Notify via issue comment and incident channel

2. **Rollback Procedure** (Manual)
   - Navigate to GitHub App settings (UI)
   - Revert permission to previous state
   - Re-approve installation with rolled-back permissions
   - Verify mitigation

3. **Post-Incident**
   - Document what went wrong
   - Update testing procedures to catch similar issues
   - Consider whether permission was actually needed

---

## Related Documentation

- **Least Privilege Token Strategy:** (Issue #8)
- **Role Charters:** `00-os/role-charters/`
- **Security Policy:** `SECURITY.md`
- **Governance:** `governance.md`

---

## Maintenance

This runbook should be updated when:
- New role apps are created
- GitHub changes App permission model or capabilities
- Escalation paths or approval authorities change
- Automation capabilities expand

**Runbook Owner:** Executive Sponsor  
**Review Frequency:** Quarterly or after each permission escalation incident
