ADR-ID: 0002
Title: Split Context-Engineering into governance and implementation repositories
Status: Accepted
Date: 2026-02-26
Decision-Owners: Systems Architect, AI Governance Manager
Approvers: Executive Sponsor
Supersedes: N/A
Superseded-By: N/A

## Context
Context-Engineering currently combines governance policy artifacts and execution/tooling artifacts in one repository. This mixed layout creates review ambiguity, weakens policy-vs-implementation boundaries, and increases the risk of governance drift during implementation changes.

A deterministic operating model is required where policy authority and execution mechanics remain separate while preserving traceable dependency flow.

## Decision
Adopt a repository split with explicit authority and dependency boundaries:

1. Governance repository (`context-engineering-governance`) is the authoritative policy source.
2. Implementation repository (`context-engineering-implementation`) owns generators/scripts/workflows and consumes governance contracts.
3. Role repositories consume implementation outputs and governance requirements.
4. Tooling repositories remain independent implementation lifecycles governed by policy contracts.

Normative boundary rules:

- Dependency direction is one-way: governance -> implementation -> role repositories.
- Governance repository must not depend on implementation internals.
- Implementation repository must not redefine or conflict with governance policy contracts.
- Protected governance/process decisions require Executive Sponsor approval before merge.

## Consequences
- Positive:
  - Clear separation of authority and execution responsibilities.
  - Cleaner compliance review with lower policy-drift risk.
  - Safer implementation velocity within defined governance boundaries.
- Negative / Trade-offs:
  - Initial migration and cutover coordination overhead.
  - Required contract/version compatibility management across repos.
  - Temporary dual-maintenance during transition.

## Alternatives Considered
1. Keep a single mixed repository - rejected due to governance/implementation ambiguity and review friction.
2. Split only role repositories but keep governance and implementation together - rejected because policy authority boundaries remain blurred.
3. Move only tooling out first without governance contract formalization - rejected due to traceability and conformance risk.

## References
- Primary Issue: #65
- Parent Execution Issue: #57
- Child Execution Issues: #59, #62, #61, #58, #60, #63
- Related ADR(s): 0001-record-architecture-decisions.md
