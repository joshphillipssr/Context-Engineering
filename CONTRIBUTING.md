# Contributing

Thanks for helping improve Context-Engineering. Please keep changes scoped and reviewable.

## How to Contribute

1. Open or reference an Issue that defines objective, scope, and definition of done.
2. Create a branch linked to the primary Issue using any valid GitHub path (recommended: `gh issue develop <ISSUE_NUMBER> --checkout`).
3. Make focused edits and avoid unrelated refactors.
4. Open a PR that declares the primary Issue with `Closes #<ISSUE_NUMBER>` or `Refs #<ISSUE_NUMBER>` and includes required role metadata.
5. For architecture/protected changes, include ADR linkage fields in the PR body (`ADR-Required`, `Primary-ADR`, `ADR-Status-At-Merge`, and supersession traceability when applicable).
6. Ensure the primary Issue shows PR linkage in GitHub Development before merge (or document an explicit exception with compensating evidence in the PR).

## Architecture Decisions (ADR)

- Author architecture-level decisions under `00-os/adr/`.
- Use the ADR template at `00-os/adr/0000-template.md`.
- Follow authoring guidance at `00-os/adr/AUTHORING.md`.

## Safety and Scope

- Do not include secrets, tokens, credentials, PII, or internal hostnames.
- Keep changes within the scope of the Issue and repo governance.
- When unsure, add a TODO and request clarification.

## Review Expectations

- Protected paths require Executive Sponsor approval.
- Compliance Officer posts the PR Review Report on reviewed PRs.
- CI validates machine-readable PR metadata keys and canonical enum values for:
  - `Primary-Role`
  - `Reviewed-By-Role`
  - `Executive-Sponsor-Approval`
- Compliance review enforces ADR linkage fields for architecture/protected decisions:
  - `ADR-Required`
  - `Primary-ADR`
  - `ADR-Status-At-Merge`
  - `ADR-Supersession-Traceability` (when replacing decisions)

## Agent Efficiency Feedback Workflow

Agent-scoped workflows are designed to discover and surface friction points for continuous improvement.

### For AI Agents: Filing Efficiency Reports

When you encounter workflow friction—missing tools, permission gaps, timing issues, knowledge gaps—capture it as structured feedback:

1. **Log the issue** in your role-scoped repo using the `efficiency-opportunity` template.
2. **Detail the blocker**: type, severity, impact, workaround used.
3. **Label it**: Apply `efficiency-opportunity` and `agent-feedback` labels.
4. **Suggest a fix**: Be concrete about the proposed solution.

Use the template at `.github/ISSUE_TEMPLATE/efficiency-opportunity.md`.

#### Severity Scale
- **Blocker**: Blocks task completion without workaround; requires manual intervention or high effort.
- **High**: Requires significant workaround or slows workflow noticeably.
- **Medium**: Causes friction or extra steps; has simple workaround.
- **Low**: Minor friction; no functional impact.

### For HR AI Agent Specialist: Triage and Implementation

The HR role owns the cross-role efficiency feedback lifecycle:

1. **Scan weekly** (or per-sprint): Review `efficiency-opportunity` issues across all role-repos.
2. **Triage**: Identify patterns, severity, and cross-role impact.
3. **Implement**: Create Context-Engineering issues/PRs for high-impact improvements.
4. **Communicate**: Notify agents when feedback results in fixes (comment on the original efficiency issue).

Example workflow:
- Agent files: "Efficiency: Check PR state before posting comments" in their role repo
- a-HRAIAS sees the pattern, determines it's agent-wide, creates a Context-Engineering issue
- Fix is implemented in agent-instructions/base.md
- a-HRAIAS posts: "Implemented in PR #XYZ; new guidance added to base agent instructions"

### Label Registry

| Label | Description | Use When |
|-------|-------------|----------|
| `efficiency-opportunity` | Agent-identified workflow friction or improvement | Filing or tracking efficiency feedback |
| `agent-feedback` | Operational feedback from agents | Any agent-generated issue about their workflow |

All role-scoped repos have these labels pre-created for consistency.
