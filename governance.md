# Governance (Authoritative)

This document is the authoritative, enforceable operating model for Context-Engineering.

For exploratory ideas, options, and future-looking notes, see `canvas.md`.

---

## Organizational Model

### Executive Sponsor — Josh (current assignment)

- Sets vision, priorities, and constraints
- Decides what becomes public vs private
- Approves publishable artifacts

### AI Governance Manager — ChatGPT (current assignment)

- Helps design and maintain the context system
- Produces prompts, reviews agent output, and enforces standards
- Maintains private operational knowledge
- Prepares sanitized artifacts for publication

### Compliance Officer — Codex (current assignment)

- Reviews implementation output for alignment with this operating model
- Checks for security leaks, scope creep, and Plane A vs Plane B violations
- Uses deterministic checklists (not “looks good” intuition)
- Recommends approve / request changes; does not merge protected changes without Executive Sponsor sign-off
- Posts the PR Review Report as a comment on every PR it reviews (required artifact)

### Implementation Specialist — Copilot / Codex / Continue / Others (current assignments)

- Execute tasks using provided context
- Operate primarily on repo-local, public-safe context
- Do not retain long-term memory; context must be supplied

### Systems Architect (systems planning and architecture role)

- Designs system-level architecture and implementation paths
- Translates objectives into architecture options, trade-offs, and sequencing
- Defines integration boundaries and interface expectations
- Recommends solutions without approval or merge authority

### Business Analyst (proposal and analysis role)

- Performs exploratory analysis and planning
- Proposes changes and drafts work orders
- Does not approve protected changes

### Role assignment principle

- Roles define responsibility, authority, and escalation
- Tools and humans are assignment metadata, not role identity
- Canonical role charters live in `00-os/role-charters/`

### Canonical role terminology

The canonical role vocabulary for this repo is:

- Executive Sponsor
- AI Governance Manager
- Compliance Officer
- Implementation Specialist
- Systems Architect
- Business Analyst
- HR and AI Agent Specialist

Use canonical role names in PR metadata, labels, approvals, and documentation.
Legacy role terms are deprecated and must not be introduced in new artifacts.

### Legacy role mapping (for reference)

| Legacy reference | Canonical role | Notes |
|---|---|---|
| CEO (Josh) | Executive Sponsor | Final approval responsibility for protected changes |
| Director of AI Context (ChatGPT) | AI Governance Manager | Context-system ownership and curation |
| Reviewer / Merge Agent — Codex | Compliance Officer | Deterministic compliance review function |
| Agents (Copilot/Codex/Continue/Others) | Implementation Specialist | Execution role, tool-agnostic |
| Exploratory analysis / proposal | Business Analyst | Proposal and planning role |

---

## Two-Plane Context Model

### Plane A — Public / Portable Context

**Lives with the code. Safe for public repos.**

Includes:

- Repo-specific Copilot instructions
- Architecture and workflow documentation
- Public-safe prompts and runbooks
- Sanitized decision logs
- Agent working agreements

Purpose:

- Make repos self-contained
- Enable tool/LLM portability
- Allow public sharing without redaction anxiety

### Plane B — Private / Operational Context

**Lives in private operational systems (outside this repo).**

Includes:

- Executive Sponsor / AI Governance Manager / Implementation Specialist operating system
- Prompt templates with internal assumptions
- Unredacted session canvases
- Tool behavior notes and quirks
- Security and redaction rules

Purpose:

- Act as the durable system of record
- Allow fast, unsanitized thinking
- Feed curated context into Plane A

---

## Canvas Lifecycle

### 1. Session Canvas (Private)

- Created during active ChatGPT sessions
- May include sensitive data, internal URLs, raw ideas
- Updated continuously during a working thread

### 2. Publishable Extract (Curated)

- Subset of the session canvas
- Explicitly marked as safe for repo inclusion
- Reviewed by Executive Sponsor before publication

### 3. Repo Canvas (Public-Safe)

- Added to the target repo under `docs/ai/`
- Becomes durable context for agents
- Used by Implementation Specialists (Copilot / Codex / Continue) going forward

**Rule:** Chat history is ephemeral. Canvases are durable.

---

## Canvas to Governance Promotion (Formal Process)

Use this process when promoting an idea from `canvas.md` into authoritative policy.

### 1. Promotion eligibility

An idea is eligible for promotion only when:

- Scope and language are stable
- Governance impact is clear
- Ownership and approval boundaries are explicit
- Required supporting artifacts are identified (templates, charters, checklists) where applicable

### 2. Required Issue content

Promotion work is issue-first and the Issue must define:

- Objective (what policy change is being proposed)
- Source context (link to relevant `canvas.md` section or heading)
- Scope and constraints
- Definition of done
- Required supporting artifact updates (if any)

### 3. Required implementation and PR flow

1. Create the Issue
2. Establish deterministic Issue/PR linkage for the primary tracked Issue (recommended: `gh issue develop <ISSUE_NUMBER> --checkout`)
3. Implement the governance change with minimal scope
4. Remove or reduce the promoted idea in `canvas.md` so only unresolved exploratory content remains
5. Open a PR that links/closes the Issue and includes required role attribution metadata and labels
6. Complete Compliance Officer review, including the required PR Review Report comment

### 4. Approval and merge requirements

- Changes to `governance.md` are protected changes
- Executive Sponsor approval is required before merge
- Merge only after required review and approval signals are present

### 5. Post-merge hygiene

- Ensure `canvas.md` no longer contains ratified policy language that now lives in `governance.md`
- If only part of an idea was promoted, keep only the remaining open questions in `canvas.md`
- Update related references (for example, glossary, templates, or role charters) only when required by the promoted change

---

## Change Management: Issue / PR Process (reviewable edits)

All meaningful changes in this repo should be **reviewable**. The default workflow is **Issue → Branch → Pull Request → Review → Merge**.

### Goals

- Make edits auditable and reversible
- Reduce “random walk” documentation
- Provide a clear contract between agents and reviewers

For architecture-level decisions, use ADR artifacts under `00-os/adr/` and the authoring guide at `00-os/adr/AUTHORING.md`.

### Default workflow
1. **Create an Issue** (Executive Sponsor, AI Governance Manager, Business Analyst, or Implementation Specialist) defining: objective, scope, constraints, and definition of done
2. **Create a branch and link it to the primary Issue** using any valid GitHub path that preserves deterministic linkage (recommended: `gh issue develop <ISSUE_NUMBER> --checkout`) (role occupant)
3. **Implement on the branch** with focused commits and role-attributed commit messages
4. **Open a Pull Request** using templates and checklists, including machine-readable PR metadata (see Role Attribution). PR description must link the primary Issue. Use `Closes #<ISSUE_NUMBER>` when the PR fully resolves the Issue; use `Refs #<ISSUE_NUMBER>` for related but non-closing linkage. For architecture/protected changes, include ADR linkage fields (`ADR-Required`, `Primary-ADR`, `ADR-Status-At-Merge`, `ADR-Supersession-Traceability`).
5. **Apply PR labels** (role occupant) immediately after PR creation using GitHub UI, API/automation, or `gh` to self-identify role and set initial status
6. **Review**

   - Compliance Officer reviews for compliance (structure, security, scope, Plane A/B boundaries)
   - Compliance Officer verifies ADR linkage fields for architecture/protected changes (`Primary-ADR`, `ADR-Status-At-Merge`, and supersession traceability when applicable)
   - Compliance Officer posts the PR Review Report as a PR comment on the PR (required)
   - Reviewer updates PR labels to reflect outcome (approved / changes requested)
   - AI Governance Manager / Executive Sponsor makes final call for sensitive changes

7. **Merge** (human merge for protected changes; update status labels)

**Rules (Required):**
- Issue-first: every PR maps to an existing Issue.
- Every PR must declare one primary tracked Issue in the PR description using either `Closes #<ISSUE_NUMBER>` or `Refs #<ISSUE_NUMBER>`.
- The primary tracked Issue must show PR linkage in GitHub Development before merge; if platform behavior prevents this, record a documented exception with compensating evidence in the PR.
- `gh issue develop <ISSUE_NUMBER> --checkout` is the recommended branch-linking path, but not the exclusive allowed path.
- Issues must define objective, scope, constraints, and definition of done.
- PRs that introduce or modify architecture/protected decisions must declare ADR linkage in PR metadata:
  - `ADR-Required: Yes`
  - `Primary-ADR: <ADR filename or ADR-ID>`
  - `ADR-Status-At-Merge: Accepted|Exception`
  - `ADR-Exception-Evidence: <required when status is Exception>`
- Replacing decisions must include supersession traceability in PR metadata (`ADR-Supersession-Traceability`) and reciprocal ADR metadata (`Supersedes` / `Superseded-By`) before merge.

### Issue/PR triage (blocker vs follow-up vs note)

Use the following triage classes for in-flight findings during Issue/PR work:

- **Blocker:** must be resolved in the current PR before approval/merge.
- **Follow-up:** create a linked Issue; keep the current PR scoped.
- **Note:** keep as a note/checklist/comment; no new Issue required unless promoted to follow-up.

**If no Issue exists (fallback sequence):**
1) `gh issue create ...`
2) create a branch linked to that Issue (recommended: `gh issue develop <ISSUE_NUMBER> --checkout`)
3) implement + PR

### Protected changes (require Executive Sponsor approval)

- `governance.md` and `context-flow.md`
- Anything under `00-os/` (operating system & guardrails)
- Any change that affects Plane A vs Plane B boundaries
- Any architecture/protected process decision without accepted ADR linkage (unless explicit Executive Sponsor-approved exception evidence is present)

### Low-risk changes (can be fast-tracked)

- New templates under `10-templates/`
- Placeholder vendor notes under `30-vendor-notes/`
- New session canvas instances under `20-canvases/`

### Review gate (minimum)

- No secrets / tokens / internal hostnames / personal data
- No new top-level folders without explicit instruction
- Changes are scoped to the Issue
- Templates and checklists preferred over long prose
- TODOs added where human judgment is needed

### Agent process-improvement loop (required)

Agents must not only complete assigned work; they must also identify reusable workflow improvements.

Required behavior after substantive task execution:

1. Perform a brief efficiency reflection: "How could this have been more efficient?"
2. If reusable friction/workaround occurred, create or link an `efficiency-opportunity` issue before handoff.
3. Efficiency reports must include, at minimum: blocker type, severity, impact, workaround used, and suggested fix.
4. Apply labels `efficiency-opportunity` and `agent-feedback` on efficiency issues.
5. If an equivalent open issue exists, link it instead of duplicating; append current evidence/context.

This loop is mandatory for all role-scoped agents and is part of role-performance expectations.

### Role-repo instruction publication gate (required)

Any PR that changes role-instruction generation logic, role-repo templates, or generated `AGENTS.md` contract content must include:

- clear scope tied to an Issue
- explicit mapping to affected role(s)
- deterministic validation evidence (for example, render output checks)
- Compliance Officer review for governance alignment

Until a dedicated HR role is ratified, Compliance Officer is the required reviewer for instruction-contract alignment.

### PR lifecycle: close / supersede / cleanup
PRs are not deleted; they are merged or closed. Prefer `gh` over manual UI.

**Close a PR** when:
- It is stale/abandoned
- It is out of scope and rescoping is not worth it
- It is superseded by another PR

**Prefer rescoping (rewrite/rebase)** when:
- The PR is fundamentally correct but contains extra commits/files

**Closure hygiene (required):**
1) Leave a final comment stating why it is being closed and (if applicable) what replaces it.
2) Apply exactly one status label:
   - `status:closed` (default)
   - `status:superseded` (use instead of `status:closed` when replaced by another PR)
   - Remove any `status:needs-review`, `status:changes-requested`, `status:approved`
3) Delete the remote branch after closing unless intentionally retained.

**Canonical `gh` commands**
Close with comment:

```bash
gh pr close <PR_NUMBER> --comment "Closing PR: <reason>. Superseded by #<NEW_PR_NUMBER> (if applicable)." --delete-branch
```

Set closed labels:

```bash
gh pr edit <PR_NUMBER> --add-label "status:closed" --remove-label "status:superseded" --remove-label "status:needs-review" --remove-label "status:changes-requested" --remove-label "status:approved" --remove-label "status:merged"
```

Add superseded label (optional):

```bash
gh pr edit <PR_NUMBER> --add-label "status:superseded" --remove-label "status:closed" --remove-label "status:needs-review" --remove-label "status:changes-requested" --remove-label "status:approved" --remove-label "status:merged"
```

If the branch should be retained, omit the `--delete-branch` flag.

---

## Repository Governance Adoption Model (Ownership States)

This model defines how repository ownership moves from autonomous operation to fully governed operation under Context-Engineering.

### Canonical ownership declarations

Governance ownership is declared in two places:

- Central registry (authoritative): `00-os/governed-repos.yml`
- Local marker (in governed repo): `.context-engineering/governance.yml`

If the local marker and central registry disagree, the central registry is authoritative.

### Repository governance states

- `autonomous`
  - Repository is not yet governed by Context-Engineering controls.
  - May consume templates voluntarily.
- `transition`
  - Repository is formally onboarded for governance adoption and has an active rollout plan.
  - Required controls are being implemented and evidenced.
- `governed`
  - Repository is fully governed under this policy and must satisfy governed controls continuously.

### Required controls by state

| Control Family | autonomous | transition | governed |
| --- | --- | --- | --- |
| Central registry entry (`00-os/governed-repos.yml`) | Required | Required | Required |
| Local ownership marker (`.context-engineering/governance.yml`) | Optional | Required | Required |
| Issue-first PR workflow (`Issue -> Branch -> PR -> Review -> Merge`) | Recommended | Required | Required |
| Role/status labels + PR metadata fields | Recommended | Required | Required |
| Review policy | Repo-local | Compliance Officer required for governance-affecting changes | Compliance Officer required; Executive Sponsor required for protected paths |
| Branch protection and required checks | Repo-local | Baseline branch protection and CI checks defined with gap list | Enforced branch protection and required checks aligned to governance policy |
| Role-instruction contract (where role agents are present) | Optional | Required plan and migration issue | Required and enforced (`AGENTS.md` contract chain) |

### Onboarding workflow (`autonomous -> transition -> governed`)

1. Open governance adoption issue in `Context-Engineering` with objective, scope, constraints, and definition of done.
2. Add or update registry entry in `00-os/governed-repos.yml` and set target state.
3. Commit local marker file in target repo (`.context-engineering/governance.yml`).
4. Implement required controls for transition/governed state.
5. Record evidence and approvals before state promotion in registry.

Initial rollout tracking issues (created under this policy):

- Role repo rollout: #17
- JoshGPT repo rollout: #18
- mcp-auth-broker rollout: #20

#### Transition gate (enter `transition`)

Required evidence:

- Linked adoption issue in `Context-Engineering`
- Named owner role and target window
- Control gap list with follow-up implementation issues
- Local governance marker added to target repo

#### Governed gate (enter `governed`)

Required evidence:

- Transition controls implemented and verified
- Required branch protection/check policy active
- Compliance Officer review completed
- Executive Sponsor approval recorded for protected-path adoption changes
- Role-instruction contract verified for role repos (if applicable)

### Offboarding / de-governance workflow (`governed -> transition|autonomous`)

1. Open protected de-governance issue in `Context-Engineering` with rationale, risk impact, and rollback plan.
2. Require Compliance Officer review and Executive Sponsor approval.
3. Update central registry state and local marker state in same change window.
4. Capture explicit follow-up issue(s) for any control removals.
5. Preserve audit links (issue, PR, approval comments) in the offboarding record.

### Escalation and exception handling

- Any unmet required control in `transition` or `governed` state must be tracked as a linked exception issue with owner and expiry date.
- Exceptions are time-bound and must include compensating controls.
- Expired exceptions without renewal approval require immediate state downgrade to `transition` until remediated.

---

## Role Attribution & Auditability (Humans vs Tools)

Because all GitHub actions are authenticated under the same human identity (`joshphillipssr`), **explicit role attribution is required** to preserve auditability and intent.

The goal is to make it immediately clear:

- Which role performed the work
- Which role reviewed it
- Which role approved protected changes

### Required attribution mechanisms

At least **two** of the following must be used on every Pull Request (and at least one on every Issue). Using more is encouraged for clarity.

**Required for PRs:**

- Machine-readable PR metadata (below)
- GitHub labels (below)

#### 1. Commit message prefixes (preferred)

Use a clear prefix in commit messages:

- `[Implementation Specialist]` — work generated or scaffolded for execution
- `[Compliance Officer]` — review-driven or corrective changes based on compliance analysis
- `[AI Governance Manager]` — context-system ownership and curation changes
- `[Business Analyst]` — proposal or planning artifacts
- `[Systems Architect]` — system architecture and implementation path design
- `[Executive Sponsor]` — approval decisions or direct edits by the sponsor

Example:

```text
[Implementation Specialist] scaffold Context-Engineering templates
[Compliance Officer] fix tier naming inconsistencies
[Executive Sponsor] approve protected-path changes
```

#### 2. Machine-readable PR metadata (required)

Every PR description must include the following fields (exact keys), so humans and automation can parse intent reliably:

- `Primary-Role: Executive Sponsor|AI Governance Manager|Compliance Officer|Business Analyst|Implementation Specialist|Systems Architect`
- `Reviewed-By-Role: Compliance Officer|Executive Sponsor|N/A`
- `Executive-Sponsor-Approval: Required|Not-Required|Provided`

These fields do not replace narrative description; they make attribution auditable.

For architecture/protected decisions, PR descriptions must also include:

- `ADR-Required: Yes|No`
- `Primary-ADR: <ADR filename>|ADR-<ID>|N/A`
- `ADR-Status-At-Merge: Accepted|Exception|N/A`
- `ADR-Exception-Evidence: <required when ADR-Status-At-Merge is Exception>|N/A`
- `ADR-Supersession-Traceability: Supersedes:<ADR-ID>|Superseded-By:<ADR-ID>|N/A`

Rules:

- Use `ADR-Required: Yes` when the PR introduces or modifies architecture decisions, operating-model structure, or protected-path policy/process decisions.
- If `ADR-Required: Yes`, `Primary-ADR` must resolve to an ADR artifact and `ADR-Status-At-Merge` must be `Accepted` unless an Executive Sponsor-approved exception is documented.
- If `ADR-Status-At-Merge: Exception`, `ADR-Exception-Evidence` is mandatory and must include the compensating control/approval path.
- If the decision replaces a prior decision, `ADR-Supersession-Traceability` must be non-`N/A` and match reciprocal ADR metadata updates.

#### 3. GitHub labels (required for PRs)

Labels make role and status visible at a glance and must be applied on every PR.

**Role labels (pick all that apply):**

- `role:executive-sponsor`
- `role:ai-governance-manager`
- `role:compliance-officer`
- `role:business-analyst`
- `role:implementation-specialist`
- `role:systems-architect`

**Optional:**

- `role:executive-sponsor-approved` — use when a protected-path approval comment exists (redundant but sometimes convenient)

**Status labels (pick one current status):**

- `status:needs-review`
- `status:changes-requested`
- `status:approved`
- `status:merged`
- `status:closed`
- `status:superseded`

**Rule:** Labels must be applied/updated by the actor (Implementation Specialist / Compliance Officer / Executive Sponsor) using GitHub UI, API/automation, or `gh` as part of the workflow.

#### Legacy terminology treatment (deprecated)

Legacy role terms are allowed only as historical references (for example, in the legacy mapping table). They are **not** valid for PR metadata or labels.

If a PR description, comment, or label uses legacy role terms (for example: `CEO`, `Director of AI Context`, `role:CEO`, `CEO-Approval`), reviewers must request changes and require replacement with canonical role terminology.

#### 4. Label application methods (UI/API/`gh`) with canonical `gh` examples

The allowed methods are GitHub UI, GitHub API/automation, or `gh`. The commands below are optional examples, not exclusive requirements.

Agents may have access to a shell with `gh` configured under the Executive Sponsor identity. When labeling is required, use these canonical commands:

Apply initial labels after PR creation (example PR #3):

```bash
gh pr edit 3 --add-label "role:implementation-specialist" --add-label "status:needs-review" --remove-label "status:changes-requested" --remove-label "status:approved" --remove-label "status:merged" --remove-label "status:closed" --remove-label "status:superseded"
```

Update labels after Compliance Officer review (REQUEST CHANGES):

```bash
gh pr edit 3 --add-label "role:compliance-officer" --add-label "status:changes-requested" --remove-label "status:needs-review" --remove-label "status:approved" --remove-label "status:merged" --remove-label "status:closed" --remove-label "status:superseded"
```

Update labels after Compliance Officer review (APPROVE):

```bash
gh pr edit 3 --add-label "role:compliance-officer" --add-label "status:approved" --remove-label "status:needs-review" --remove-label "status:changes-requested" --remove-label "status:merged" --remove-label "status:closed" --remove-label "status:superseded"
```

Post PR Review Report comment (required):
```bash
gh pr comment <PR_NUMBER> --body-file <PATH_TO_PR_REVIEW_REPORT_MD>
```

On merge:

```bash
gh pr edit 3 --add-label "status:merged" --remove-label "status:approved" --remove-label "status:needs-review" --remove-label "status:changes-requested" --remove-label "status:closed" --remove-label "status:superseded"
```

#### 5. Explicit PR comments for protected approval

Protected-path changes **must** include an explicit PR comment from the Executive Sponsor.

Example:
> **Executive Sponsor approval:**  
> I approve this pull request, including changes under protected paths (`00-os/`), per the Change Management rules defined in `governance.md`.

### Non-goals

- GitHub author identity is **not** used to infer role
- Automated bot identities are optional and not required
- Attribution must be human-readable and reviewable in the PR timeline
- Long-term, prefer least-privilege tokens or GitHub automation for agent actions (labeling/commenting) even if they run under the Executive Sponsor identity today

**Rule:** If an auditor cannot tell *who did what and why* from the PR alone, attribution is insufficient.

---

## Instruction Layering

### Global (Governance)

- Stored in Context-Engineering as public-safe governance
- Principles, standards, prompt patterns

### Repo-Specific (Public-Safe)

- `.github/copilot-instructions.md`
- Focused, minimal, repo-scoped

### Tool Adapters

- Copilot, Continue, Codex each consume context differently
- Repo context is the shared baseline

### Agent Job Description Contract (required)

`AGENT INSTRUCTIONS = ROLE-BASED JOB DESCRIPTION`

For role repositories, the canonical instruction artifact is:

- `AGENTS.md` at repository root

`AGENTS.md` must be generated from repository-governed role sources and treated as a role contract, not free-form prompt text.

Required source chain (authoritative order):

1. `governance.md`
2. `00-os/role-charters/`
3. approved role-instruction templates (for example, `10-templates/agent-instructions/`)
4. generated role-repo `AGENTS.md`

If any lower layer conflicts with a higher layer, the higher layer is authoritative.

#### Required AGENTS.md structure

Each generated role-repo `AGENTS.md` must define, at minimum:

1. Role mission and purpose
2. Responsibilities
3. Explicit non-responsibilities
4. Authority boundaries and approval limits
5. Required operating workflow
6. Escalation triggers
7. Prohibited actions
8. Output and quality standards
9. Source metadata (generation source/ref/time)

#### Ambiguity control

`AGENTS.md` must use deterministic language (`must`, `must not`, `should`) and avoid ambiguous authority boundaries.
If an instruction cannot be interpreted deterministically, the assigned agent must escalate.

#### Tool adapter policy

Tool-specific instruction files are adapters, not alternate policy sources.

- `AGENTS.md` is canonical.
- `.github/copilot-instructions.md` must point to `AGENTS.md` and must not redefine role authority.
- Other adapters (Codex, Ollama, etc.) may reformat but must preserve role meaning and boundaries.
- Runtime `/workspace/instructions/role-instructions.md` must act as a bootstrap loader to role-repo `AGENTS.md`, not a second role-policy source.
- If role-repo `AGENTS.md` is unavailable, runtime instructions must limit behavior to bootstrap/recovery actions (clone/sync/auth restore) until AGENTS is restored.

#### Role repo self-sufficiency (Agent Handbook)

Role repos must be self-sufficient for daily agent work; `Context-Engineering` should only be required to change governance or templates.

Each role repo must include an Agent Handbook under `handbook/` with at least:

- SOPs (`handbook/sops/`)
- Runbooks (`handbook/runbooks/`)
- Templates (`handbook/templates/`)
- References (`handbook/references/`)

The handbook complements `AGENTS.md` by providing the practical, role-specific materials needed to execute work without pulling Context-Engineering.

---

## Security Model

### Sensitivity Tiers

1. **Public** — safe for public repos
2. **Internal** — private systems only (not public repos)
3. **Secret** — never committed (keys, tokens)

### Practices

- Secrets scanning on public repos
- Publishable Extract section required for promotion
- Assume Plane A is always world-readable
- Before any visibility change to public, run a full git-history secret scan and resolve findings (tool-agnostic).

---

## Persistence Strategy

- No critical knowledge lives only in chat history
- Every meaningful session updates a canvas
- Repo canvases are the only inputs agents can rely on long-term
