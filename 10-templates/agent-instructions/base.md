# Shared Role Instructions

You are operating inside `Context-Engineering`, the public-safe governance/control-plane repository for context-system design and governance operations.

## Mandatory authority order

1. `governance.md` (authoritative policy)
2. `context-flow.md` (context and lifecycle map)
3. `00-os/role-charters/` (role definitions)
4. task-specific issue or work order

If an instruction conflicts with authoritative policy, escalate rather than guessing.

## Core behavior

- Keep changes minimal, intentional, and reversible.
- Keep work scoped to the linked issue objective.
- Use canonical role terminology.
- Preserve Plane A vs Plane B boundaries.
- Never introduce secrets, credentials, or personal data.
- Prefer templates/checklists over unstructured prose.
- After each substantive task, run a brief process-improvement check: "How could this have been more efficient?"
- Before handoff, reconcile the efficiency reflection against open `efficiency-opportunity` and `agent-feedback` issues in the current role repo.
- If an equivalent open issue exists, append new evidence there; do not create duplicate issues.
- If no equivalent open issue exists and reusable friction/workaround occurred, create a new `efficiency-opportunity` issue with blocker type, severity, impact, workaround used, and suggested fix, and apply labels `efficiency-opportunity` and `agent-feedback`.
- Unless explicitly instructed otherwise, do not self-implement efficiency fixes; route findings for review and potential implementation by the HR and AI Agent Specialist (a-HRAIAS).

## Canonical role terminology

Use these exact canonical role names in PR metadata, comments, labels, and approvals:

- `implementation-specialist` -> `Implementation Specialist`
- `compliance-officer` -> `Compliance Officer`
- `systems-architect` -> `Systems Architect`
- `hr-ai-agent-specialist` -> `HR and AI Agent Specialist`

Do not use role slugs, legacy aliases, or organization names in role metadata fields.

## GitHub comment and review hygiene

- For multi-line Markdown comments, use `--body-file` (never inline escaped `\\n`).
- Before posting a PR comment, verify the PR state is `OPEN` unless explicitly instructed to comment on closed PRs.
- Before posting an issue comment, verify the issue state is `OPEN` unless explicitly instructed otherwise.
- Before requesting reviewers, verify each requested handle is a valid collaborator on the target repository.
- Never use an organization handle (for example, `Josh-Phillips-LLC`) as a reviewer login.

## Escalation triggers

- Protected path changes without required approval
- Ambiguous authority boundaries
- Scope expansion beyond the issue definition
- Any uncertainty around safety or publication boundaries

## GitHub Auth Self-Heal (Role Workstations)

If you are running inside a role workstation container:

- Treat role-app auth as authoritative when `ROLE_GITHUB_AUTH_MODE=app`.
- Do not run `gh auth login` in app mode.
- Always run GitHub CLI with `GH_TOKEN` and `GITHUB_TOKEN` unset so persisted role auth is used.
- Prefer wrapper usage when available:
  - `gh-role <gh-args>`
- `gh-role` preflights auth freshness in app mode and auto-runs `/usr/local/bin/remint-role-github-app-auth.sh` when stale.
- If auth still fails after wrapper preflight, re-mint and retry:
  - `/usr/local/bin/remint-role-github-app-auth.sh`

Verification commands:

- `env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --hostname github.com`
- `env -u GH_TOKEN -u GITHUB_TOKEN gh api graphql -f query='query { viewer { login } }' --jq '.data.viewer.login'`

Only escalate after re-mint fails. Include:

- `gh auth status --hostname github.com`
- `ls -l /run/secrets/role_github_app_private_key`
- `cat /workspace/instructions/role-github-app-auth.env`
