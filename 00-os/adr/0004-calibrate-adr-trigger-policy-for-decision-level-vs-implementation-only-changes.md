ADR-ID: 0004
Title: Calibrate ADR trigger policy for decision-level vs implementation-only changes
Status: Accepted
Date: 2026-02-27
Decision-Owners: AI Governance Manager, Compliance Officer
Approvers: Executive Sponsor
Supersedes: N/A
Superseded-By: N/A

## Context
Current ADR enforcement over-triggered on protected-path implementation fixes by treating them as if they always required new ADR artifacts.

That behavior increased merge friction for bugfix and refactor work that executes under already accepted decisions and does not introduce or modify a durable architecture or operating-model decision.

A deterministic rule is needed that preserves traceability while preventing unnecessary ADR artifact churn.

## Decision
Adopt a two-path deterministic ADR trigger policy for PR governance:

1. Decision-level path (new ADR required)
- Applies when a PR introduces, modifies, or supersedes a durable architecture decision, operating-model decision, or protected-path policy/process decision.
- Requires ADR metadata path:
  - `ADR-Required: Yes`
  - `Primary-ADR: <new or updated ADR artifact>`
  - `ADR-Status-At-Merge: Accepted|Exception`
  - `ADR-Exception-Evidence` when status is `Exception`
  - `ADR-Supersession-Traceability` when supersession applies

2. Implementation-only path (no new ADR artifact required)
- Applies when a PR is bugfix/refactor/implementation work under an existing accepted decision and does not introduce, modify, or supersede a durable decision.
- Requires linkage-only metadata path:
  - `ADR-Required: No`
  - `Primary-ADR: <existing accepted ADR>`
  - `ADR-Status-At-Merge: Accepted`
  - `ADR-Implementation-Rationale: <explicit non-decision-level rationale>`
  - `ADR-Exception-Evidence: N/A`
  - `ADR-Supersession-Traceability: N/A` unless supersession is actually involved

Compliance enforcement rule:
- Request changes when required metadata/evidence for the applicable path is missing.
- Do not require a new ADR artifact for the implementation-only path.

## Consequences
- Positive:
  - Reduces unnecessary ADR creation for implementation-only fixes.
  - Preserves deterministic and auditable decision traceability.
  - Aligns governance enforcement with standard ADR practices.
- Negative / Trade-offs:
  - Requires disciplined classification between decision-level and implementation-only changes.
  - Requires consistent updates across templates/checklists and reviewer behavior.

## Alternatives Considered
1. Require a new ADR for every protected-path PR.
- Rejected due to overblocking and excessive ADR churn.
2. Never require ADR metadata for implementation-only fixes.
- Rejected due to weaker traceability and auditability.
3. Reviewer discretion without deterministic criteria.
- Rejected due to inconsistent enforcement risk.

## References
- Primary Issue: #84
- Primary PR: #85
- Related ADR(s): 0001-record-architecture-decisions.md
