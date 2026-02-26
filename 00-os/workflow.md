# Workflow

## Default Workflow (Reviewable Changes)
1. **Issue**: Objective, scope, constraints, definition of done
2. **Branch (required)**: Create from the Issue via `gh issue develop <ISSUE_NUMBER> --checkout`
3. **Implementation**: Focused edits with minimal scope and role-attributed commit messages
4. **Pull Request**: Use templates + include machine-readable PR metadata (`Primary-Role` / `Reviewed-By-Role` / `Executive-Sponsor-Approval`) and link/close the Issue (example: `Closes #<ISSUE_NUMBER>`)
5. **Labels**: Apply required PR labels (at least one `role:*` label + exactly one `status:*` label) using GitHub UI, API/automation, or `gh` immediately after PR creation
6. **Review**: Compliance Officer review + human decision where required; Compliance Officer posts PR Review Report comment; reviewer updates status labels after verdict; AI Governance Manager / Executive Sponsor makes final call for sensitive changes
7. **Merge**: Human merge for protected changes; update status labels

## Required Rules
- Every PR must map to an existing Issue.
- Branch creation for Issue work must use `gh issue develop <ISSUE_NUMBER> --checkout` (no manual `git checkout -b`).
- Issues must define objective, scope, constraints, and definition of done.

## Issue/PR Triage
- **Blocker**: must be resolved in the current PR before approval/merge.
- **Follow-up**: create a linked Issue; keep the current PR scoped.
- **Note**: keep as a note/checklist/comment; no new Issue required unless promoted to follow-up.

## Protected Changes (Require Executive Sponsor Approval)
- `governance.md` and `context-flow.md`
- Anything under `00-os/`
- Any change that affects Plane A vs Plane B boundaries

## Low-Risk Fast-Track (If Review Gate Passes)
- New templates under `10-templates/`
- Placeholder vendor notes under `30-vendor-notes/`
- New session canvas instances under `20-canvases/`

## Default Behaviors
- Prefer templates and checklists over prose.
- Add TODOs when judgment is required.
- Keep Plane A/Plane B separation intact.

## Artifact Flow
- Session Canvas → Publishable Extract → Repo Canvas

## Role Creation Workflow
- Canonical execution template: `10-templates/agent-work-orders/role-creation-work-order.md`
- GitHub issue launcher: `.github/ISSUE_TEMPLATE/role-creation-request.md`
- Use this pair for end-to-end role rollout work (charter and source definitions through role-repo sync and container publish verification).
- Ensure role creation work includes workstation launcher touchpoints when introducing new roles.

## TODO
- Add release cadence (weekly/monthly) if needed.
- Define acceptance criteria for each artifact type.
