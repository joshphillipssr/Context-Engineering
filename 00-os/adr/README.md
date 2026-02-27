# ADR Schema and Lifecycle (Normative)

This document defines the canonical Architecture Decision Record (ADR) schema and lifecycle for Context-Engineering.

This specification is normative for issue #66.

## Related ADR Authoring Artifacts

- Template: `00-os/adr/0000-template.md`
- Starter ADR: `00-os/adr/0001-record-architecture-decisions.md`
- Authoring guide: `00-os/adr/AUTHORING.md`

## 1. Canonical Location and Naming

- ADR files MUST live under `00-os/adr/`.
- ADR filename MUST match: `^\d{4}-[a-z0-9-]+\.md$`.
- ADR ID MUST be a zero-padded 4-digit number: `^\d{4}$`.
- ADR file prefix MUST equal `ADR-ID` (for example, `0007-...` MUST contain `ADR-ID: 0007`).
- Each ADR file MUST represent one decision.
- ADR IDs are immutable and MUST NOT be reused.

## 2. Required Metadata Keys

Each ADR MUST include the following metadata keys exactly once using `Key: Value` format:

- `ADR-ID: <4-digit>`
- `Title: <short decision title>`
- `Status: Draft|Proposed|Accepted|Superseded|Deprecated`
- `Date: YYYY-MM-DD`
- `Decision-Owners: <role list>`
- `Approvers: <role list>`
- `Supersedes: <ADR-ID>|N/A`
- `Superseded-By: <ADR-ID>|N/A`

Format rules:

- `Status` MUST use one of the allowed enum values exactly.
- `Date` MUST match `YYYY-MM-DD`.
- `Supersedes` and `Superseded-By` MUST be either a valid ADR ID or `N/A`.

## 3. Required Sections

Each ADR MUST include the following headings exactly once:

1. `## Context`
2. `## Decision`
3. `## Consequences`
4. `## Alternatives Considered`
5. `## References`

## 4. Lifecycle Model

Allowed transitions:

- `Draft -> Proposed`
- `Proposed -> Accepted`
- `Proposed -> Deprecated`
- `Accepted -> Superseded`
- `Accepted -> Deprecated`

Disallowed examples:

- `Accepted -> Proposed`
- `Superseded -> Accepted`
- `Deprecated -> Accepted`

State semantics:

- `Draft`: working record, not ready for approval.
- `Proposed`: review-ready candidate decision.
- `Accepted`: approved active decision.
- `Superseded`: replaced by a newer accepted ADR.
- `Deprecated`: intentionally retired without direct replacement.

`Superseded` and `Deprecated` are terminal states.

## 5. Approval and Authority Matrix

- Compliance Officer review is required for ADR conformance and traceability.
- Executive Sponsor approval is required before merge for ADRs with `Status: Accepted` that affect protected paths or the operating model.
- Superseding decisions require reciprocal supersession fields (`Supersedes` and `Superseded-By`) before merge.

Current repository note:

- ADR files are stored under `00-os/adr/`.
- `00-os/` is a protected path under current governance.
- Therefore, ADR changes that establish or modify accepted operating-model decisions are treated as protected changes.

## 5.1 ADR Trigger Calibration for PRs

Use this deterministic distinction for PR-level ADR expectations:

- New ADR required when a PR introduces, modifies, or supersedes a durable architecture or operating-model decision.
- No new ADR required for implementation-only bugfix/refactor work that executes under an existing accepted decision.

PR metadata expectations:

- Decision-level path: `ADR-Required: Yes`, `Primary-ADR`, `ADR-Status-At-Merge`, and exception/supersession fields when applicable.
- Implementation-only path: `ADR-Required: No`, `Primary-ADR` (existing accepted ADR), `ADR-Status-At-Merge: Accepted`, `ADR-Implementation-Rationale`.

Examples:

- Decision-level: new branch protection operating-model decision -> new ADR artifact required.
- Implementation-only: security bugfix in existing workflow wiring under an accepted auth/governance ADR -> no new ADR artifact; existing ADR linkage + rationale required.

## 6. Supersession Rules (Reciprocal)

When ADR `NNNN` supersedes ADR `MMMM`:

- New ADR MUST set `Supersedes: MMMM`.
- Prior ADR `MMMM` MUST be updated to set `Superseded-By: NNNN`.
- Self-supersession is invalid.
- Supersession targets MUST exist.

## 7. Machine-Checkable Validation Contract

The ADR validator (issue #68) MUST be able to check at minimum:

- Path and filename constraints (`00-os/adr/`, filename regex).
- Metadata key presence and uniqueness.
- Metadata format/enum validity.
- `ADR-ID` to filename prefix match.
- Required heading presence and uniqueness.
- Supersession target existence and reciprocal-link consistency.
- Lifecycle transition validity (when transition-check mode is enabled).

Recommended rule IDs for deterministic output:

- `ADR001`: invalid path/location
- `ADR002`: invalid filename pattern
- `ADR003`: missing/duplicate required metadata
- `ADR004`: invalid metadata enum/format
- `ADR005`: missing/duplicate required heading
- `ADR006`: ADR-ID and filename mismatch
- `ADR007`: supersession target missing/invalid
- `ADR008`: reciprocal supersession mismatch
- `ADR009`: invalid status transition

## 8. Validator CLI and Exit Codes

Canonical validator script:

- `python3 00-os/scripts/validate-adr.py --path <DIR_OR_FILE>`

Supported options:

- `--strict`
- `--json`
- `--check-transitions --before <DIR> --after <DIR>`
- `--include-glob '<pattern>'`
- `--exclude-glob '<pattern>'`

Exit code contract:

- `0`: validation passed
- `1`: one or more conformance violations
- `2`: invocation/runtime error
