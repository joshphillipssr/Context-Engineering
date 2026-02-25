# GitHub App Auth Self-Heal Protocol (Role Workstations)

Apply this protocol when running inside role-scoped workstation containers.

## Mode and authority

- Treat role app auth as authoritative when `ROLE_GITHUB_AUTH_MODE=app`.
- Do not run `gh auth login` in app mode.
- Run `gh` with `GH_TOKEN` and `GITHUB_TOKEN` unset so persisted role-app auth is used.

## Deterministic self-heal sequence

1. Prefer wrapper usage for normal GitHub CLI operations:
   - `gh-role <gh-args>`
2. `gh-role` preflights auth freshness in app mode and auto-runs re-mint when stale.
   - Preflight check: `env -u GH_TOKEN -u GITHUB_TOKEN gh api graphql -f query='query { viewer { login } }' --jq '.data.viewer.login'`
3. If auth still fails after wrapper preflight:
   - `env -u GH_TOKEN -u GITHUB_TOKEN /usr/local/bin/remint-role-github-app-auth.sh`
4. Retry the original command via `gh-role`.

## Verification commands

- `env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --hostname github.com`
- `env -u GH_TOKEN -u GITHUB_TOKEN gh api graphql -f query='query { viewer { login } }' --jq '.data.viewer.login'`

## Escalation package (only after re-mint fails)

Include command output for:

- `env -u GH_TOKEN -u GITHUB_TOKEN gh auth status --hostname github.com`
- `ls -l /run/secrets/role_github_app_private_key`
- `cat /workspace/instructions/role-github-app-auth.env`
- `env -u GH_TOKEN -u GITHUB_TOKEN /usr/local/bin/remint-role-github-app-auth.sh`
