# ADR Authoring Guide

This guide explains how to author ADRs using the canonical schema defined in `00-os/adr/README.md`.

## 1. Path, Naming, and Numbering

- Store ADR files in `00-os/adr/`.
- Use filename format: `<ADR-ID>-<kebab-case-title>.md`.
- Use zero-padded 4-digit IDs: `0001`, `0002`, `0003`, ...
- One ADR file = one decision.
- ADR IDs are immutable and never reused.

## 2. New ADR Flow (Non-Superseding)

1. Copy `00-os/adr/0000-template.md` to the next ADR ID filename.
2. Fill all required metadata keys and required sections.
3. Set initial status to `Draft` while iterating.
4. Promote to `Proposed` when opening review PR.
5. Move to `Accepted` only when required approvals are present.

## 3. PR Issue-Linkage (`Closes` vs `Refs`)

When opening a PR that introduces or updates ADR content:

- Use `Primary-Issue-Ref: Closes #<ISSUE_NUMBER>` when the PR fully satisfies that issue's definition of done.
- Use `Primary-Issue-Ref: Refs #<ISSUE_NUMBER>` when the PR is partial, dependency work, or otherwise non-closing.

Keep exactly one primary issue reference in the PR body, and include Development-linkage evidence per repo workflow.

## 4. Superseding ADR Flow

When replacing an accepted ADR decision:

1. Create a new ADR with a new ID.
2. In the new ADR, set `Supersedes: <OLD_ID>`.
3. In the old ADR, set `Superseded-By: <NEW_ID>`.
4. Update status of old ADR to `Superseded`.
5. Ensure reciprocal links are merged together to maintain traceability.

## 5. Minimal Migration Guidance (Pre-ADR Decisions)

For historical architecture decisions recorded only in issues/PRs:

1. Create a new ADR that captures the decision and rationale.
2. Link legacy issue/PR artifacts in `## References`.
3. Mark unknown supersession values as `N/A` until formally superseded.
4. Do not rewrite historical issue/PR content; add traceability forward via ADR references.

## 6. Role and Approval Notes

- Compliance Officer review is required for ADR conformance.
- Executive Sponsor approval is required before merge when ADR status/impact triggers protected-change gates.

## 7. Local Validation

Run ADR validation before opening or updating PRs:

- `python3 00-os/scripts/validate-adr.py --path 00-os/adr --strict --exclude-glob '00-os/adr/_fixtures/**' --exclude-glob '00-os/adr/README.md' --exclude-glob '00-os/adr/AUTHORING.md' --exclude-glob '00-os/adr/0000-template.md'`

Exit codes:

- `0`: pass
- `1`: conformance failures
- `2`: runtime/invocation error
