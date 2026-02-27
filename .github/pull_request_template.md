# Summary
- 

# Issue
- Linked issue (primary tracked issue):
- Primary-Issue-Ref: Closes #
- Additional issue references (optional):
- Refs #

# Issue Linkage (Outcome-Based, Required)
- [ ] Exactly one primary tracked issue is declared using `Primary-Issue-Ref: Closes #<ISSUE_NUMBER>` or `Primary-Issue-Ref: Refs #<ISSUE_NUMBER>`
- [ ] Primary issue shows this PR in GitHub Development before merge, or an explicit exception with compensating evidence is documented
- [ ] `gh issue develop <ISSUE_NUMBER> --checkout` was used where practical (recommended, not mandatory)

# Development Linkage Evidence (Required)
- Development-Linkage: Verified
- Development-Linkage-Evidence:
- If exception is required instead of verified linkage:
  - Development-Linkage: Exception
  - Development-Linkage-Evidence: <why linkage is blocked + compensating evidence>

# ADR Linkage (Required for architecture/protected changes)
- ADR-Required: No
- Primary-ADR: N/A
- ADR-Status-At-Merge: N/A
- ADR-Implementation-Rationale: N/A
- ADR-Exception-Evidence: N/A
- ADR-Supersession-Traceability: N/A
- Set `ADR-Required: Yes` when this PR introduces, modifies, or supersedes architecture decisions, protected-path policy/process decisions, or operating-model structure.
- Use `ADR-Required: No` for implementation-only bugfix/refactor changes under an existing accepted decision.
- `Primary-ADR` must reference an ADR artifact using either canonical filename (`0001-...`) or `ADR-<ID>`.
- `ADR-Status-At-Merge` allowed values: `Accepted | Exception | N/A`.
- If `ADR-Required: No`, set `ADR-Status-At-Merge: Accepted` and provide `ADR-Implementation-Rationale` explaining why the change is implementation-only under the linked ADR.
- If `ADR-Status-At-Merge: Exception`, provide explicit compensating evidence in `ADR-Exception-Evidence` and ensure Executive Sponsor approval is recorded before merge.
- If this PR replaces a prior decision, set `ADR-Supersession-Traceability` to `Supersedes: <ADR-ID>` or `Superseded-By: <ADR-ID>` (otherwise `N/A`).

# Machine-Readable Metadata (Required)
Primary-Role: Implementation Specialist
Reviewed-By-Role: Compliance Officer
Executive-Sponsor-Approval: Not-Required

Allowed values:
- Primary-Role: Executive Sponsor | AI Governance Manager | Compliance Officer | Business Analyst | Implementation Specialist | Systems Architect
- Reviewed-By-Role: Compliance Officer | Executive Sponsor | N/A
- Executive-Sponsor-Approval: Required | Not-Required | Provided

# Role Attribution
- **Primary Role:** (Executive Sponsor / AI Governance Manager / Compliance Officer / Business Analyst / Implementation Specialist)
- [ ] Commit messages include role prefixes ([Executive Sponsor], [AI Governance Manager], [Compliance Officer], [Business Analyst], [Implementation Specialist])
- [ ] At least one role label applied (role:executive-sponsor / role:ai-governance-manager / role:compliance-officer / role:business-analyst / role:implementation-specialist)
- [ ] Exactly one status:* label applied
- [ ] No legacy role terms used in metadata/labels (CEO, Director of AI Context, role:CEO, CEO-Approval)
- [ ] Executive Sponsor approval provided (required for protected paths)

# Review Gate (Minimum)
- [ ] No secrets, tokens, internal hostnames, or personal data
- [ ] No new top-level folders without explicit instruction
- [ ] Changes are scoped to the Issue
- [ ] Templates/checklists used instead of long prose where applicable
- [ ] TODOs added where human judgment is required

# Protected Changes Logic
- [ ] `governance.md`, `context-flow.md`, or `00-os/` touched → Executive Sponsor approval required
- [ ] Plane A/B boundary changes detected → Executive Sponsor approval required
- [ ] Decision-level architecture/protected changes include ADR linkage (`ADR-Required: Yes`, `Primary-ADR`, `ADR-Status-At-Merge`)
- [ ] Implementation-only architecture/protected changes under existing accepted decisions include linkage (`ADR-Required: No`, `Primary-ADR`, `ADR-Status-At-Merge: Accepted`, `ADR-Implementation-Rationale`)
- [ ] Replacing decisions include `ADR-Supersession-Traceability` and reciprocal ADR metadata updates

# Low-Risk Fast-Track
- [ ] Only low-risk paths changed (10-templates/, 30-vendor-notes/, new 20-canvases/)
- [ ] Review gate passed → eligible for fast-track
