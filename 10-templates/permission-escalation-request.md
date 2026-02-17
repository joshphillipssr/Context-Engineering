# GitHub App Permission Escalation Request

**Date:** YYYY-MM-DD  
**Requestor:** @username  
**Role App Affected:** [Select: Implementation Specialist | Compliance Officer | Systems Architect | Other]

---

## Summary

<!-- One-sentence description of what permission is needed and why -->

---

## Failing Operation

**Operation Type:** <!-- e.g., Create branch, Add PR comment, Update workflow file -->

**Repository/Scope:** <!-- e.g., Context-Engineering, all role repos, org-level -->

**Agent Task/Workflow:** <!-- Link to failing workflow run or task ID -->

**Failure Timestamp (UTC):** YYYY-MM-DD HH:MM:SS

---

## Evidence

### Error Details

```
[Paste complete error message here]
```

**HTTP Status Code:** 

**API Endpoint:** `[METHOD] /path/to/endpoint`

**Relevant Logs:**
```
[Paste sanitized log excerpts - remove any secrets/tokens]
```

### Current Permission State

<!-- Navigate to: https://github.com/organizations/Josh-Phillips-LLC/settings/apps/[role-app] -->

**Current Repository Permissions:**
- [ ] List current permissions here
- [ ] Include both granted and not-granted relevant to this request

**Current Organization Permissions:**
- [ ] List current org-level permissions
- [ ] Highlight any that might be relevant

**Installation Scope:**
- [ ] Installed on: [List repositories or "All repositories"]

---

## Requested Permission

**Permission Name:** <!-- e.g., "Contents: Write", "Pull Requests: Write" -->

**Scope:** <!-- Repository-level or Organization-level -->

**Access Level:** <!-- Read or Write -->

**GitHub API Documentation:**
<!-- Link to https://docs.github.com/en/rest/... -->

---

## Justification

### Why This Permission is Required

<!-- Explain what role capability requires this permission -->

1. **Role Charter Alignment:**
   <!-- Quote relevant section from role charter that implies this capability -->

2. **Specific Use Case:**
   <!-- Describe the operation that fails without this permission -->

3. **Frequency:**
   <!-- How often will this permission be used? -->

### Least Privilege Analysis

**Alternatives Considered:**
- [ ] Different API endpoint with lower permission: <!-- Yes/No - explain -->
- [ ] Workflow redesign to avoid permission: <!-- Yes/No - explain -->
- [ ] Different role performing operation: <!-- Yes/No - explain -->
- [ ] Read-only instead of write access: <!-- Yes/No - explain -->

**Why requested scope is minimal:**
<!-- Explain why you can't use a narrower permission -->

---

## Risk Assessment

**Risk Level:** <!-- Low | Medium | High -->

**Risk Justification:**

| Factor | Assessment |
|--------|------------|
| **Data Access** | <!-- What data becomes accessible? --> |
| **Write Capability** | <!-- What can be modified? --> |
| **Protected Resources** | <!-- Any protected branches, settings, etc.? --> |
| **Blast Radius** | <!-- If misused, what's the impact scope? --> |

**Mitigation Measures:**
- [ ] Describe how agent code limits permission usage
- [ ] Describe validation/safeguards in place
- [ ] Describe monitoring/audit for permission use

---

## Testing Plan

### Pre-Implementation Verification

- [ ] Confirmed error is permission-related (not auth/network)
- [ ] Confirmed app is properly installed on target repos
- [ ] Confirmed operation is within role charter scope

### Post-Implementation Validation

1. **Success Criteria:**
   - [ ] Original failing operation succeeds
   - [ ] No new errors introduced
   - [ ] Related functionality unaffected

2. **Test Steps:**
   ```markdown
   1. [Step-by-step test procedure]
   2. [Expected result for each step]
   3. [How to verify success]
   ```

3. **Rollback Plan:**
   - [ ] Document how to revert if issues occur
   - [ ] Identify monitoring signals for problems

---

## Approval Required

<!-- Automatically determined by risk level: -->

**Risk Level: Low**
- [ ] @RoleCharterOwner review

**Risk Level: Medium**
- [ ] @ExecutiveSponsor approval

**Risk Level: High**
- [ ] @ExecutiveSponsor approval
- [ ] Security/Compliance review

---

## Implementation Checklist

<!-- To be completed by approver/implementer after approval -->

- [ ] Approval granted (link to approval comment)
- [ ] GitHub App permissions updated via UI
- [ ] Installation update approved via UI
- [ ] Permission change verified in GitHub App settings
- [ ] Original operation retested successfully
- [ ] Documentation updated (role app inventory, charter if needed)
- [ ] Issue closed with validation evidence

---

## Notes

<!-- Any additional context, concerns, or follow-up items -->
