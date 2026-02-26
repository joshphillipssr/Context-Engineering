# PR Review Checklist (Deterministic)

## Blockers (Must Pass)
- [ ] PR description includes required role metadata keys (Primary-Role:, Reviewed-By-Role:, Executive-Sponsor-Approval:)
- [ ] PR description declares exactly one primary tracked issue using `Primary-Issue-Ref: Closes #<ISSUE_NUMBER>` or `Primary-Issue-Ref: Refs #<ISSUE_NUMBER>`
- [ ] Development linkage requirement is satisfied: `Development-Linkage: Verified`, or `Development-Linkage: Exception` with compensating evidence
- [ ] At least one role label exists (role:implementation-specialist / role:compliance-officer / role:ai-governance-manager / role:business-analyst / role:executive-sponsor)
- [ ] Exactly one status:* label exists
- [ ] No legacy role terms used in metadata/labels (CEO, Director of AI Context, role:CEO, CEO-Approval)

## Review Gate (Minimum)
- [ ] No secrets, tokens, internal hostnames, or personal data
- [ ] No new top-level folders without explicit instruction
- [ ] Changes are scoped to the Issue
- [ ] Templates/checklists used instead of long prose where applicable
- [ ] TODOs added where human judgment is required

## Role Attribution Verification
- [ ] Commit messages include role prefixes ([Implementation Specialist], [Compliance Officer], [AI Governance Manager], [Business Analyst], [Executive Sponsor])
- [ ] PR title or labels identify the primary role
- [ ] Executive Sponsor approval comment exists when required (protected paths)

## Protected Changes Logic
- [ ] If `governance.md`, `context-flow.md`, or `00-os/` changed → Executive Sponsor approval required
- [ ] If Plane A/B boundary changes detected → Executive Sponsor approval required

## Low-Risk Fast-Track
- [ ] Only low-risk paths changed (10-templates/, 30-vendor-notes/, new 20-canvases/)
- [ ] Review gate passed → eligible for fast-track

## Outcome
- [ ] Approve
- [ ] Request changes (list blockers)
- [ ] Escalate to Executive Sponsor

## TODO
- Add repo-specific gates (tests, lint, etc.).
