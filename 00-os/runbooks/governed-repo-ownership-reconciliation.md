# Governed Repo Ownership Reconciliation Runbook

## Overview

This runbook defines a deterministic reconciliation process for governance ownership declarations between:

- Central registry: `00-os/governed-repos.yml`
- Per-repo marker: `.context-engineering/governance.yml`

The reconciliation scope is repositories in `transition` or `governed` state.

## When to Run

Run reconciliation on this cadence:

- Weekly (recommended baseline)
- After any merge that changes:
  - `00-os/governed-repos.yml`
  - `.context-engineering/governance.yml` template or semantics
  - governance state for any repository
- Before promoting any repository state (`autonomous -> transition -> governed`)

## Owner and Evidence Location

- **Primary operator:** AI Governance Manager (or delegated Systems Architect)
- **Reviewer:** Compliance Officer
- **Evidence record location:** reconciliation log comment in a Context-Engineering issue for the current cycle, plus linked updates in repo-family rollout issues (`rollout_issue` in registry entries) when mismatches affect rollout state

Minimum evidence for each run:

- UTC timestamp
- operator identity
- checklist result table per repo
- mismatch severity and remediation issue links

## Deterministic Checklist

### 1) Validate central ownership artifacts

From `Context-Engineering` root:

```bash
python3 00-os/scripts/validate-governance-ownership.py
```

Expected result: success for canonical files on `main`.

### 2) Enumerate target repositories

List only `transition` and `governed` repositories from the central registry:

```bash
python3 - <<'PY'
import yaml
from pathlib import Path
data = yaml.safe_load(Path("00-os/governed-repos.yml").read_text())
for entry in data["repositories"]:
    if entry["state"] in {"transition", "governed"}:
        print(f'{entry["repo"]}\t{entry["state"]}\t{entry["marker_path"]}')
PY
```

### 3) Verify marker presence in each target repo

For each target repo:

```bash
gh api repos/<OWNER>/<REPO>/contents/.context-engineering/governance.yml >/dev/null
```

Expected result:

- `governed`: marker must exist
- `transition`: marker must exist

### 4) Compare central vs local ownership fields

For each target repo, compare:

- registry `repo` vs marker `repository`
- registry `state` vs marker `governance.state`
- registry `marker_path` vs marker location used
- marker `governance.owner_repo` points to `Josh-Phillips-LLC/Context-Engineering`
- marker `governance.registry_ref` points to `00-os/governed-repos.yml`

Minimal marker read example:

```bash
gh api repos/<OWNER>/<REPO>/contents/.context-engineering/governance.yml --jq .download_url \
  | xargs curl -fsSL
```

### 5) Record reconciliation outcome

Post a reconciliation evidence comment with one row per repo:

| repo | target_state | marker_present | state_match | owner_repo_match | action |
| --- | --- | --- | --- | --- | --- |
| owner/repo | transition|governed | yes/no | yes/no | yes/no | none/follow-up issue |

## Mismatch Triage and Priority

Use this severity model:

- **Critical**
  - `governed` repo missing marker
  - marker state differs from central state on a `governed` repo
  - owner-repo reference mismatch on a `governed` repo
- **High**
  - `transition` repo missing marker
  - marker state differs from central state on a `transition` repo
- **Medium**
  - stale evidence links or non-blocking metadata drift

## Remediation Requirements

For every mismatch:

1. Open a follow-up issue in `Josh-Phillips-LLC/Context-Engineering`.
2. Link the mismatch to the appropriate rollout issue (`rollout_issue` from registry entry).
3. Set explicit owner and target window in the follow-up issue.
4. Update reconciliation evidence log with follow-up issue URL.
5. Re-run reconciliation for affected repo(s) after fix merges.

No mismatch should be closed without a linked remediation PR/issue trail.

## Related Artifacts

- `governance.md` (`Repository Governance Adoption Model`)
- `00-os/governed-repos.yml`
- `.context-engineering/governance.yml`
- `00-os/scripts/validate-governance-ownership.py`
