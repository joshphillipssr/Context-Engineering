# Repository Source-of-Truth Map

Effective date: 2026-02-26  
Authority: ADR 0002 (`00-os/adr/0002-split-context-engineering-into-governance-and-implementation-repos.md`)

## Canonical Repositories

| Concern | Canonical repository | Notes |
|---|---|---|
| Governance policy authority | `Josh-Phillips-LLC/context-engineering-governance` | Authoritative for governance contracts, ADRs, policy, and role charters. |
| Implementation/tooling authority | `Josh-Phillips-LLC/context-engineering-implementation` | Authoritative for workflows, scripts, generators, and role-repo sync execution. |
| Legacy mixed-layout coordination | `Josh-Phillips-LLC/Context-Engineering` | Deprecated mixed layout retained for transition records and migration notices only. |

## Path Mapping (Legacy -> Canonical)

| Legacy path (`Context-Engineering`) | Canonical destination |
|---|---|
| `governance.md` | `context-engineering-governance/governance.md` |
| `context-flow.md` | `context-engineering-governance/context-flow.md` |
| `00-os/adr/` | `context-engineering-governance/00-os/adr/` |
| `00-os/role-charters/` | `context-engineering-governance/00-os/role-charters/` |
| `00-os/scripts/` (execution scripts) | `context-engineering-implementation/00-os/scripts/` |
| `.github/workflows/` (execution workflows) | `context-engineering-implementation/.github/workflows/` |
| `10-templates/repo-starters/` (generator/starter implementation) | `context-engineering-implementation/10-templates/repo-starters/` |

## Change Routing Rule

1. Governance or policy change requests: open issue/PR in `context-engineering-governance`.
2. Tooling/workflow/generator change requests: open issue/PR in `context-engineering-implementation`.
3. Do not introduce new mixed-layout authority changes in this repository.

