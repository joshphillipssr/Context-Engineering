ADR-ID: 0003
Title: Enforce governed main branch protection baseline
Status: Accepted
Date: 2026-02-26
Decision-Owners: AI Governance Manager, Compliance Officer
Approvers: Executive Sponsor
Supersedes: N/A
Superseded-By: N/A

## Context
`Josh-Phillips-LLC/Context-Engineering` default branch (`main`) was unprotected, which allowed non-governed merges and weakened enforcement of required review/compliance controls.

The governance model already requires enforced branch protection/check policy for governed repositories, but a concrete baseline for `main` enforcement and emergency override handling was not explicitly documented and activated.

## Decision
Apply and maintain a governed main-branch protection baseline for `Josh-Phillips-LLC/Context-Engineering`:

1. Require pull requests for routine merge flow.
2. Require at least one approving review.
3. Require code owner review on protected governance paths.
4. Require conversation resolution before merge.
5. Require strict status checks and enforce a governed check set (`Analyze (actions)`, `Analyze (python)`, `Validate machine-readable PR metadata`, `CodeQL`).
6. Disable force pushes and branch deletion.
7. Retain emergency override only through administrator bypass as break-glass, with mandatory rationale comment and post-merge audit issue.

## Consequences
- Positive:
  - Deterministic merge enforcement for governed policy/process changes.
  - Lower risk of bypassing required compliance gates.
  - Clear audit expectations for emergency override events.
- Negative / Trade-offs:
  - Higher friction for urgent changes when checks are degraded.
  - Current emergency override relies on administrator bypass rather than fully role-scoped bypass actors.
  - Ongoing maintenance needed when required check names change.

## Alternatives Considered
1. Keep `main` unprotected - rejected due to direct-governance bypass risk.
2. Enforce all settings with no override path - rejected because break-glass capability is required for operational continuity.
3. Use broad permanent bypass for maintainers/admins - rejected as routine policy because it weakens governed enforcement intent.

## References
- Primary Issue: #53
- Governance Policy Section: `governance.md#repository-governance-adoption-model-ownership-states`
