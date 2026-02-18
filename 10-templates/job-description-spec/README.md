# Job Description Spec (Proposed)

Structured source inputs for deterministic assembly of role-repo `AGENTS.md` files.

## Purpose

- Keep `AGENTS.md` generation deterministic and reviewable.
- Enforce required section coverage for agent job descriptions.
- Separate global policy requirements from role-specific requirements.

## Files

- `global.json`
  - Global requirements applied to every role (workflow, authority boundaries, escalation, prohibited actions, quality standards)
  - May also include `required_protocol_includes` for protocol content that must appear in all generated role contracts
- `roles/<role-slug>.json`
  - Role-specific requirements and protocol includes

## Current role specs

- `roles/compliance-officer.json`
- `roles/implementation-specialist.json`
- `roles/systems-architect.json`

## Required section keys

Role files must provide or inherit values for these keys:

- `mission`
- `responsibilities`
- `non_responsibilities`
- `authority_boundaries`
- `required_workflow`
- `escalation_triggers`
- `prohibited_actions`
- `output_quality_standards`

Optional key:

- `required_protocol_includes`

All keys must be JSON arrays of strings.

## Assembly

`10-templates/repo-starters/role-repo-template/scripts/build-agent-job-description.py` merges:

1. `global.json`
2. `roles/<role-slug>.json`

and renders a contract-shaped markdown job description with required sections.

Current global protocol include:

- `10-templates/github-app-auth-self-heal-protocol.md`

## Notes

This spec is part of the role-repo migration work and is not yet ratified as stable governance policy.
