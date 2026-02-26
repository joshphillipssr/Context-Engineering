# Compliance Officer PR Review Checklist (Template)

This file is a checklist + post-review enforcement actions for the Compliance Officer (Codex assignment).

Canonical review brief and required PR Review Report format: `10-templates/compliance-officer-pr-review-brief.md` (source of truth: `governance.md`).

## PR
- Link:
- Issue:
- Scope summary:

## Blockers (REQUEST CHANGES if any fail)
- [ ] PR description includes all three exact metadata keys (Primary-Role:, Reviewed-By-Role:, Executive-Sponsor-Approval:)
- [ ] PR description links and closes the Issue (example: `Closes #<ISSUE_NUMBER>`)
- [ ] Branch was created via `gh issue develop <ISSUE_NUMBER> --checkout` (confirm via PR template)
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
- [ ] `governance.md`, `context-flow.md`, or `00-os/` touched → Executive Sponsor approval required
- [ ] Plane A/B boundary changes detected → Executive Sponsor approval required

## Decision
- [ ] Approve
- [ ] Request changes (list blockers)
- [ ] Escalate to Executive Sponsor

### Required Enforcement Actions (Post-Review)

After issuing a PR review verdict, Codex must (1) post the PR Review Report as a PR comment, and (2) enforce PR state via GitHub labels.

**Always (regardless of verdict)**
- Post the PR Review Report as a PR comment using:

```bash
gh pr comment <PR_NUMBER> --body-file <PATH_TO_PR_REVIEW_REPORT_MD>
```

**If verdict = REQUEST CHANGES**
- Apply label `role:compliance-officer`
- Apply label `status:changes-requested`
- Remove label `status:needs-review` if present

**If verdict = APPROVE**
- Apply label `role:compliance-officer`
- Apply label `status:approved`
- Remove labels `status:needs-review` and `status:changes-requested` if present

**If PR touches protected paths and an explicit Executive Sponsor approval comment exists**
- Optionally apply label `role:executive-sponsor-approved`

Label changes may be executed using GitHub UI, API/automation, or `gh`. If using `gh`, apply changes with `gh pr edit`.

Compliance Officer (Codex assignment) must request permission before executing shell commands.
Compliance Officer (Codex assignment) must not merge the PR.

## TODO
- Add repo-specific gates (tests, lint, etc.).
