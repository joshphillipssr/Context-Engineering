# Governance Label Bootstrap

## When to use

Use this runbook before applying canonical governance labels in a repository that has not yet adopted the standard `role:*` and `status:*` label set.

Typical trigger:

- `gh pr edit ... --add-label <canonical-label>` fails with `label does not exist`.

## Scope

- Any repository entering governance adoption workflows
- Any repository where deterministic role/status label operations are required

## Canonical bootstrap command

```bash
00-os/scripts/bootstrap-governance-labels.sh --repo <owner/repo>
```

Dry-run preview:

```bash
00-os/scripts/bootstrap-governance-labels.sh --repo <owner/repo> --dry-run
```

## Verification

```bash
gh label list -R <owner/repo> | rg "^(role:|status:)"
```

Expected minimum labels:

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

## Notes

- Script is idempotent and safe to re-run.
- Use bootstrap as a precondition before automated governance labeling workflows.
