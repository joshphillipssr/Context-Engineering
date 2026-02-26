# Runbook: Compliance PR Review Wrapper

## Scenario

You need deterministic, app-attributed PR review events for Compliance Officer actions.

## Immediate Actions

1. Ensure you are in role-app auth mode and avoid PAT overrides.
2. Use `scripts/co-pr-review.sh` instead of direct `gh pr review`.
3. Provide one review mode only: `--approve`, `--request-changes`, or `--comment`.
4. For report drafting, prefer:

```bash
scripts/co-pr-review-report.sh --repo <owner/repo> --pr <pr-number>
```

## Standard Commands

### Request changes

```bash
scripts/co-pr-review.sh \
  --repo Josh-Phillips-LLC/Context-Engineering \
  --pr 176 \
  --request-changes \
  --body-file WIP/pr176_review.md
```

### Approve

```bash
scripts/co-pr-review.sh \
  --repo Josh-Phillips-LLC/Context-Engineering \
  --pr 176 \
  --approve \
  --body "All governance checks pass."
```

### Comment-only review

```bash
scripts/co-pr-review.sh \
  --repo Josh-Phillips-LLC/Context-Engineering \
  --pr 176 \
  --comment \
  --body-file WIP/pr176_note.md
```

## Decision Points

- If identity verification fails, stop and re-mint app auth before retrying.
- If post-submit verification fails (author/state mismatch), treat as blocking and investigate before handoff.

## Verification Steps

- Confirm script output shows reviewer identity and expected state.
- Optionally re-check API output:

```bash
env -u GH_TOKEN -u GITHUB_TOKEN gh pr view 176 -R Josh-Phillips-LLC/Context-Engineering --json reviews
```

## Post-Incident Follow-up

- If mismatch repeats, file or append an `efficiency-opportunity` issue with evidence and exact command output.
- For re-review cycles after requested changes, run `handbook/runbooks/compliance-rereview-after-changes.md`.
