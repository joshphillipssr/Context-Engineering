# Runbook: Governance Label Bootstrap

## Scenario

You need to apply canonical governance labels in a repository that does not have them yet.

## Immediate Actions

1. Confirm target repository (`owner/repo`).
2. Bootstrap canonical labels before applying `role:*` or `status:*` labels in PR workflows.

```bash
scripts/bootstrap-governance-labels.sh --repo <owner/repo>
```

## Decision Points

- If labels already exist, re-running bootstrap is safe (`--force` behavior keeps labels deterministic).
- If the target repository is outside governance scope, escalate before applying governance labels.

## Verification Steps

```bash
gh label list -R <owner/repo> | rg "^(role:|status:)"
```

Required minimum set:

- `role:implementation-specialist`
- `role:compliance-officer`
- `role:systems-architect`
- `role:hr-ai-agent-specialist`
- `role:ai-governance-manager`
- `role:business-analyst`
- `role:executive-sponsor`
- `status:needs-review`
- `status:changes-requested`
- `status:approved`
- `status:merged`
- `status:closed`
- `status:superseded`

## Post-Incident Follow-up

- If label bootstrap was required unexpectedly during active review, file or append an `efficiency-opportunity` issue with repo link and failure evidence.
