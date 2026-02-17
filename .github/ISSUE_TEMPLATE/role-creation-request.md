---
name: Role Creation Request
about: Create a new governed role from charter through role repo and container publication
labels: ["change-request"]
---

## Objective
-

## Required Inputs
- Role title:
- Role slug (kebab-case):
- Role menu label/shorthand:
- Role repo owner (organization/user):
- Role repo name override (optional, default `context-engineering-role-<role-slug>`):
- Role env prefix (uppercase snake case):

## Scope (Allowed Changes)
- In scope:
- Out of scope:

## Implementation Requirements
- [ ] Create role charter at `00-os/role-charters/<role-slug>.md`
- [ ] Create role instruction source at `10-templates/agent-instructions/roles/<role-slug>.md`
- [ ] Create role job-description spec at `10-templates/job-description-spec/roles/<role-slug>.json`
- [ ] Add role profile env at `.devcontainer-workstation/codex/role-profiles/<role-slug>.env`
- [ ] Add role entry to `00-os/role-registry.yml` with GitHub App + compose + menu metadata
- [ ] Run `python3 00-os/scripts/generate-role-wiring.py` to generate role wiring
- [ ] Confirm generated wiring updates are present in compose/workflow/launcher generated sections
- [ ] Run `python3 00-os/scripts/generate-role-wiring.py --check`
- [ ] Run onboarding validator: `10-templates/repo-starters/role-repo-template/scripts/validate-role-onboarding.sh --role-slug <role-slug>`
- [ ] Run app bootstrap validator: `00-os/scripts/validate-github-app-setup.sh --role-slug <role-slug> --org <owner>`
- [ ] Create public role repo scaffold via `create-public-role-repo.sh`
- [ ] Verify sync workflow success for the new role
- [ ] Verify publish workflow success for the new role
- [ ] Capture workflow/container verification evidence in PR

## Definition of Done
-

## Role Attribution
- **Proposed Implementer:** Implementation Specialist
- **Expected Reviewer:** Compliance Officer
- **Executive Sponsor Approval:** (Required / Not-Required)

## Notes
-

## Reference Template
Use: `10-templates/agent-work-orders/role-creation-work-order.md`
