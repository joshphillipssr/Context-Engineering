# Mixed-Layout Deprecation Notice

Owner: AI Governance Manager  
Executive Sponsor approval required for protected-path exceptions.  
Issued: 2026-02-26

## Scope

This notice applies to mixed-layout authority/execution paths in:

- `Josh-Phillips-LLC/Context-Engineering`

Canonical replacements:

- `Josh-Phillips-LLC/context-engineering-governance`
- `Josh-Phillips-LLC/context-engineering-implementation`

## Deprecation Policy

- No new governance-authority changes should be merged in legacy mixed-layout paths.
- No new implementation/tooling authority changes should be merged in legacy mixed-layout paths.
- Legacy content remains for migration traceability, historical reference, and rollback coordination only.

## Timeline

| Milestone | Date | Owner | Status |
|---|---|---|---|
| ADR 0002 accepted and split execution started | 2026-02-26 | AI Governance Manager | Complete |
| Governance and implementation repos bootstrapped with boundary/contract gates | 2026-02-26 | Systems Architect + AI Governance Manager | Complete |
| Role sync flow cut over to implementation repo | 2026-02-26 | Implementation Specialist | Complete |
| Mixed-layout repo marked deprecated and source-of-truth mapping published | 2026-02-26 | AI Governance Manager | Complete |
| Legacy mixed-layout authority updates blocked (except deprecation/rollback docs) | 2026-03-05 | AI Governance Manager | Planned |
| Legacy mixed-layout artifacts archived/superseded per follow-up governance decision | 2026-03-31 | Executive Sponsor | Planned |

## Exception Handling

Any temporary exception to this notice must:

1. Be approved in a linked issue in `Josh-Phillips-LLC/Context-Engineering`.
2. Include explicit rollback steps and owner.
3. Be documented in PR metadata as `Development-Linkage: Exception` when direct linkage cannot be established.

