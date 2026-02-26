ADR-ID: 0002
Title: Define governance and implementation split
Status: Accepted
Date: 2026-02-26
Decision-Owners: Systems Architect, Compliance Officer
Approvers: Executive Sponsor
Supersedes: N/A
Superseded-By: 0003

## Context
Split boundaries need explicit architecture control.

## Decision
Keep governance and implementation as separate repositories.

## Consequences
- Positive: Clear boundaries.
- Negative / Trade-offs: Coordination overhead.

## Alternatives Considered
1. Single monorepo - rejected.
2. Split only role repos - rejected.

## References
- Primary Issue: #57
