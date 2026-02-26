# Role Creation Work Order (Template)

Use this template in the **body of a GitHub Issue** when the Issue is intended to execute a full, governed role rollout from definition through role-repo and container validation.

**Rule:** Section headings in this template are **normative**. Do not rename them.

---

## Implementation Specialist Work Order (Authoritative)

## Objective
Describe the single role-creation outcome (1-3 sentences). Keep it measurable.

## Scope (Allowed Changes)
List the **only** files/folders the Implementation Specialist may modify for this role rollout.

- The Implementation Specialist may ONLY modify:
  - `00-os/role-charters/<role-slug>.md`
  - `00-os/role-registry.yml`
  - `10-templates/agent-instructions/roles/<role-slug>.md`
  - `10-templates/job-description-spec/roles/<role-slug>.json`
  - `.devcontainer-workstation/codex/role-profiles/<role-slug>.env`
  - Generated outputs from `00-os/scripts/generate-role-wiring.py`:
    - `.devcontainer-workstation/docker-compose.yml` (generated sections only)
    - `.devcontainer-workstation/docker-compose.ghcr.yml` (generated sections only)
    - `.devcontainer-workstation/scripts/start-role-workstation.sh` (generated sections only)
    - `.github/workflows/sync-role-repos.yml` (generated sections only)
    - `.github/workflows/publish-role-workstation-images.yml` (generated sections only)
  - `10-templates/repo-starters/role-repo-template/**` (only if template source changes are explicitly required)
  - `.devcontainer-workstation/README.md` (only if role lists/examples require update)
  - Any additional files explicitly listed below for this role

State whether new files may be created (default: **Yes**, only those implied by the listed paths and role slug).

The Implementation Specialist must not infer additional scope beyond what is explicitly listed here.

## Out of Scope
List explicit exclusions so scope does not expand.

- Any file not listed in Scope
- Protected artifacts unless explicitly included:
  - `governance.md`
  - `context-flow.md`
- Manual edits inside generated marker blocks without running the role wiring generator
- Unrelated refactors or formatting-only edits
- Runtime behavior changes unrelated to adding the new role
- Merging PRs

The Implementation Specialist must not modify any file/path not explicitly listed in Scope.

## Required Inputs
Fill in all placeholders before execution.

- Role title: `<Role Title>`
- Role slug (kebab-case): `<role-slug>`
- Role shorthand/menu label: `<role-menu-label>`
- Role repo owner: `<github-owner>`
- Role repo name (default): `context-engineering-role-<role-slug>`
- Role workstation service name (default): `<role-slug>-workstation`
- Role env prefix (uppercase snake case): `<ROLE_ENV_PREFIX>`
- Role app ID secret name: `<ROLE_ENV_PREFIX>_APP_ID`
- Role app private key secret name: `<ROLE_ENV_PREFIX>_APP_PRIVATE_KEY`

## Implementation Requirements
Provide deterministic edits and execution steps.

### 1) Create role charter (governed role definition)
- File: `00-os/role-charters/<role-slug>.md`
- Source scaffold: `10-templates/role-charters/_template-role-charter.md`
- Ensure the charter explicitly defines:
  - Role purpose
  - Core responsibilities
  - Explicit non-responsibilities
  - Decision rights
  - Escalation triggers
  - Required inputs/references
  - Success measures

### 2) Create role instruction source
- File: `10-templates/agent-instructions/roles/<role-slug>.md`
- Align with `10-templates/agent-instructions/base.md`
- Include role-specific operating boundaries and escalation rules derived from charter/governance.

### 3) Create role job-description spec
- File: `10-templates/job-description-spec/roles/<role-slug>.json`
- Must satisfy required schema/sections used by:
  - `10-templates/repo-starters/role-repo-template/scripts/build-agent-job-description.py`
- Ensure generated `AGENTS.md` can be assembled without manual edits.

### 4) Add role profile env
- File: `.devcontainer-workstation/codex/role-profiles/<role-slug>.env`
- Set role profile defaults needed by the workstation runtime.

### 5) Register role in canonical role registry
- File: `00-os/role-registry.yml`
- Add a new role entry with required fields:
  - `slug`, `display_name`, `shorthand`
  - `repo_name`
  - `github_app.app_id_secret`, `github_app.private_key_secret`, `github_app.env_prefix`
  - `github_app.app_id_value`, `github_app.installation_id_value` (if known)
  - `compose.service_name`, `compose.profile`, `compose.image_suffix`, `compose.volume_prefix`
  - `menu_order`, `menu_label`

### 6) Regenerate role wiring (do not hand-edit generated sections)
Run:
```bash
python3 00-os/scripts/generate-role-wiring.py
```
This updates generated markers in:
- `.devcontainer-workstation/docker-compose.yml`
- `.devcontainer-workstation/docker-compose.ghcr.yml`
- `.devcontainer-workstation/scripts/start-role-workstation.sh`
- `.github/workflows/sync-role-repos.yml`
- `.github/workflows/publish-role-workstation-images.yml`

### 7) Validate generated wiring and onboarding touchpoints
Run:
```bash
python3 00-os/scripts/generate-role-wiring.py --check

10-templates/repo-starters/role-repo-template/scripts/validate-role-onboarding.sh \
  --role-slug <role-slug>
```
Address any validation failures before continuing.

### 8) Validate GitHub App bootstrap conventions
Run:
```bash
00-os/scripts/validate-github-app-setup.sh \
  --role-slug <role-slug> \
  --org <github-owner>
```
Fix missing org secrets/app installation warnings before publish validation.

### 9) Create public role repo and initial scaffold
Run:
```bash
10-templates/repo-starters/role-repo-template/scripts/create-public-role-repo.sh \
  --role-slug <role-slug> \
  --owner <github-owner>
```

### 10) Verify sync automation and role-repo PR
Run sync workflow (manual or push-triggered) and verify:
- Role sync job succeeds
- Sync PR exists in role repo from `sync/role-repo/<role-slug>` to `main`
- Managed artifacts updated:
  - `AGENTS.md`
  - `.github/copilot-instructions.md`
  - `.vscode/settings.json`
  - `README.md`

### 11) Verify image publish and container usability
Run publish workflow and verify role job succeeds.
Validate published image pull/run for the new role profile and confirm instruction files resolve in runtime.

### 12) Capture evidence in PR
Include run URLs and verification notes for:
- Role repo creation
- Sync workflow
- Publish workflow
- Container smoke check
- Role wiring validation runs

## Acceptance Criteria
Use checkboxes. Keep these binary.

- [ ] Role charter exists at `00-os/role-charters/<role-slug>.md`
- [ ] Role instruction source exists at `10-templates/agent-instructions/roles/<role-slug>.md`
- [ ] Role job spec exists at `10-templates/job-description-spec/roles/<role-slug>.json`
- [ ] Role profile env exists at `.devcontainer-workstation/codex/role-profiles/<role-slug>.env`
- [ ] Role registry entry exists in `00-os/role-registry.yml`
- [ ] Role wiring was generated via `00-os/scripts/generate-role-wiring.py`
- [ ] `python3 00-os/scripts/generate-role-wiring.py --check` passes
- [ ] Role onboarding validator passes for `<role-slug>`
- [ ] Public role repo exists at `<github-owner>/context-engineering-role-<role-slug>`
- [ ] Sync workflow role job succeeded and produced/updated role-repo PR
- [ ] Publish workflow role job succeeded for the new role
- [ ] No manual edits were made inside generated marker blocks
- [ ] Only files listed in Scope were modified
- [ ] No secrets, tokens, internal hostnames, IPs, or personal data introduced

## PR Instructions
- Open a PR titled: `Implementation Specialist: Add <role-slug> role end-to-end`
- Include a summary mapped to Acceptance Criteria
- Include machine-readable metadata:
  - `Primary-Role: Implementation Specialist`
  - `Reviewed-By-Role: Compliance Officer`
  - `Executive-Sponsor-Approval: Required` if protected artifacts are touched, otherwise `Not-Required`
- Link and close the Issue in the PR description (example: `Closes #<ISSUE_NUMBER>`)
- Apply labels:
  - `role:implementation-specialist`
  - exactly one `status:*` label
- Do not merge the PR

### Branching (Required)
Create a fresh branch for the Issue using GitHub CLI default naming.
Manual `git checkout -b` is not allowed for Issue-driven work.

Required commands (example):
```bash
gh issue develop <ISSUE_NUMBER> --checkout
# In role workstations:
# gh-role issue develop <ISSUE_NUMBER> --checkout
git branch --show-current
```

Stop Condition:
- If not on a fresh Issue branch, stop and request human input.

## Stop Conditions
Stop execution immediately and request human input if:
- The role slug/title conflicts with existing role artifacts
- Required scope expansion is needed beyond this Issue
- Workflow permissions/secrets prevent deterministic validation
- Any instruction is ambiguous

---

## Context (Non-executable) (Optional)
Add rationale, links, or discussion here. This section is non-executable and must not expand scope.
