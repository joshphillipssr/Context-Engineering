# Codex Supervisor MCP Governance Runbook

## Overview

This runbook defines governance boundaries and operational expectations for a dedicated `ask_codex_supervisor` MCP service repository that is governed by Context-Engineering.

## Purpose

- Separate worker execution from supervisor steering.
- Keep escalation policy deterministic and auditable.
- Maintain canonical tool contracts in Context-Engineering while enabling independent MCP runtime deployment.

## Architecture Boundary

### Worker vs Supervisor

- **Worker agent (local LLM)** executes local tools and task steps.
- **Supervisor (Codex via MCP)** provides guidance when worker is blocked.
- Worker escalation to supervisor uses `ask_codex_supervisor` contract only.

### Governance Source of Truth

Canonical contract and policy inputs live in Context-Engineering:

- `10-templates/mcp-contracts/`
- `00-os/runbooks/codex-supervisor-mcp-governance.md`
- `governance.md`

The standalone MCP repository should treat these as upstream-governed artifacts.

## Escalation Policy Baseline

Worker agents should call `ask_codex_supervisor` when any of the following occur:

1. Repeated failure on the same objective.
2. Tool output is ambiguous or contradictory.
3. Scope/policy boundary is unclear.
4. Requested action appears outside authorized scope.

Worker agents should stop execution when supervisor response decision is:

- `pause_for_human`
- `stop`

## Contract Lifecycle

### Authoring

- Update canonical schemas under `10-templates/mcp-contracts/`.
- Keep request/response contracts backward-compatible where possible.

### Promotion

- Use Issue -> Branch -> PR workflow in Context-Engineering.
- Include Compliance Officer review for governance alignment.
- For protected-path changes, obtain Executive Sponsor approval per governance.

### Distribution

- Render/scaffold MCP repository via template starter:
  - `10-templates/repo-starters/mcp-supervisor-repo-template/`
- Publish and deploy MCP container from the dedicated repo.

## Audit Requirements

MCP supervisor deployments should retain:

- Request envelope (`mission_id`, `blocked_reason`, `authorized_scope`)
- Supervisor decision payload (`decision`, `rationale`, `next_actions`)
- Timestamp and execution identity of caller role

Audit records should be immutable and retained according to agency policy.

## Security Controls

- Enforce explicit authorized scope fields before supervisor guidance is acted on.
- Default to `pause_for_human` when required evidence is missing.
- Do not embed secrets in contracts or generated templates.
- Bind local dev service to loopback unless explicitly approved for broader exposure.

## Operational Checklist

1. Confirm contracts in MCP repo match Context-Engineering canonical schemas.
2. Validate MCP service starts and registers `ask_codex_supervisor`.
3. Validate request/response schema enforcement.
4. Validate fallback behavior for missing/invalid payloads.
5. Confirm logs capture required audit fields.

## Related Artifacts

- `10-templates/mcp-contracts/README.md`
- `10-templates/repo-starters/mcp-supervisor-repo-template/README.md`
- `00-os/workflow.md`
- `governance.md`
