ADR-ID: 0005
Title: Wrong location outside canonical root
Status: Draft
Date: 2026-02-26
Decision-Owners: Implementation Specialist
Approvers: Compliance Officer
Supersedes: N/A
Superseded-By: N/A

## Context
This file intentionally lives outside 00-os/adr.

## Decision
Use this file only as a path validation fixture.

## Consequences
- Positive: Exercises ADR001 location checks.
- Negative / Trade-offs: Not a valid ADR artifact.

## Alternatives Considered
1. Place under canonical root - rejected for this test.

## References
- Test Fixture
