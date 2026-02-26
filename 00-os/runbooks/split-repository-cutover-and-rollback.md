# Split Repository Cutover and Rollback

## Purpose

Provide deterministic execution steps for cutover from the legacy mixed-layout repository model to the split governance/implementation model defined by ADR 0002, including rollback criteria and procedure.

## Scope

Applies to:

- `Josh-Phillips-LLC/Context-Engineering` (legacy mixed-layout coordination)
- `Josh-Phillips-LLC/context-engineering-governance` (governance authority)
- `Josh-Phillips-LLC/context-engineering-implementation` (execution authority)

Runbook owner: AI Governance Manager  
Approval authority for protected changes: Executive Sponsor  
Last updated: 2026-02-26

## Preconditions

1. ADR 0002 is `Accepted`.
2. Execution issues completed: #58, #59, #60, #61, #62.
3. Split-repo CI gates are enabled and passing:
   - Governance boundary validation
   - Implementation boundary validation
   - Governance contract spec/consumption validation
4. Role sync workflow in implementation repo has at least one successful post-cutover run.

## Cutover Procedure

1. Confirm freeze point
   - In legacy `Context-Engineering`, permit only deprecation, mapping, and rollback documents.
   - Route all governance-authority changes to `context-engineering-governance`.
   - Route all implementation/workflow changes to `context-engineering-implementation`.
2. Validate split dependency chain
   - Governance contract exists in governance repo.
   - Implementation lock file pins governance contract version/source commit.
   - Implementation pre-sync validation checks are enabled in role sync workflow.
3. Validate operational path
   - Verify latest implementation `sync-role-repos` run succeeded across all role matrix entries.
   - Verify resulting role-repo sync PRs pass governance checks.
4. Publish cutover status artifacts in legacy repo
   - Update `REPOSITORY_SOURCE_OF_TRUTH_MAP.md`.
   - Update `MIXED_LAYOUT_DEPRECATION_NOTICE.md`.
   - Update `README.md` and `index.md` split status sections.
5. Record evidence
   - Post cutover evidence links in issue #63 (workflow runs, PRs, and docs updates).

## Verification Checklist

- [ ] Governance repository is authoritative for policy and ADR artifacts.
- [ ] Implementation repository is authoritative for scripts/workflows/generators.
- [ ] Legacy mixed-layout repo includes deprecation notice and source-of-truth mapping.
- [ ] Role sync executes from implementation repo without fallback to mixed-layout assumptions.

## Rollback Triggers

Initiate rollback if any of the following occur post-cutover:

- Split-repo boundary/contract CI regressions block required policy or implementation releases.
- Role sync from implementation repo repeatedly fails and prevents required governed updates.
- Critical governance publication path becomes unavailable due to split dependencies.

## Rollback Procedure

1. Declare rollback incident
   - Open incident issue in `Context-Engineering` with trigger, impact, and timestamp.
   - Freeze merges to split repos until rollback decision is approved.
2. Activate temporary legacy execution path
   - Re-enable mixed-layout execution updates in `Context-Engineering` only for impacted flows.
   - Use legacy `.github/workflows/sync-role-repos.yml` as temporary operational control point.
3. Stabilize and validate
   - Confirm role sync can complete using temporary legacy path.
   - Confirm no conflicting governance authority edits are introduced in rollback window.
4. Recover split path
   - Fix root cause in split repos under issue-first governance.
   - Re-run split CI and role sync validations.
5. Exit rollback
   - Reapply mixed-layout deprecation restrictions.
   - Post closure evidence and lessons learned in the rollback incident issue.

## Rollback Validation

Validation mode: tabletop + control-point verification (2026-02-26)

- Legacy and split sync workflow control points confirmed present.
- Trigger criteria and owner/approval escalation path documented.
- Evidence capture requirements defined for incident and closure.

