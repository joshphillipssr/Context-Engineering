# Role Profiles

This directory is **Codex-specific**.
These `.env` files only control Codex runtime configuration overlays in workstation containers (via `/root/.codex/config.toml`).
They do not define tool-agnostic role responsibilities or governance policy.

Canonical role responsibilities and instruction content live in repository-governed sources (for example, `10-templates/agent-instructions/**`).

Role profiles are lightweight overlays applied by `init-workstation.sh` at container startup.

Each role profile is an `.env` file named `<role>.env` and may set:

- `ROLE_APPROVAL_POLICY`
- `ROLE_MODEL_REASONING_EFFORT`
- `ROLE_MODEL_PERSONALITY`
- `ROLE_WRITABLE_ROOTS` (JSON array string)
- `ROLE_PROJECT_DOC_FALLBACK_FILENAMES` (JSON array string)

Optional GitHub role auth values:

- `ROLE_GITHUB_AUTH_MODE` (`app` or `user`, default `app`)
- `ROLE_GITHUB_APP_ID`
- `ROLE_GITHUB_APP_INSTALLATION_ID`
- `ROLE_GITHUB_APP_PRIVATE_KEY_PATH` (path to a mounted private key file)

In workstation compose files, role-specific defaults for `ROLE_GITHUB_APP_ID` and
`ROLE_GITHUB_APP_INSTALLATION_ID` may be provided per service so only the private key path
needs runtime input for app-mode auth.

Startup behavior:

- Base config is seeded from `/etc/codex/config.toml` when `/root/.codex/config.toml` does not exist.
- Role overlays then replace supported keys in `/root/.codex/config.toml`.
- If `ROLE_GITHUB_AUTH_MODE=app` and all `ROLE_GITHUB_APP_*` values are set, startup runs the role GitHub App auth helper to mint a short-lived installation token and configure `gh`.
- If any required `ROLE_GITHUB_APP_*` values are missing, startup prints a warning and continues without App auth.
- `ROLE_PROFILE` defaults to image-baked `IMAGE_ROLE_PROFILE` when not explicitly set at runtime.
- Runtime role instructions are generated at `/workspace/instructions/role-instructions.md` as a bootstrap loader that points to role-repo `AGENTS.md` as canonical.
- If role-repo `AGENTS.md` is missing, runtime remains bootstrap-only (clone/sync/auth recovery actions) until AGENTS is restored.
- Image-baked compiled instructions are break-glass/operator fallback only; they do not supersede role-repo `AGENTS.md`.
- Default runtime clone targets are role repos by role:
  - `context-engineering-role-implementation-specialist`
  - `context-engineering-role-compliance-officer`
  - `context-engineering-role-systems-architect`
  - `context-engineering-role-hr-ai-agent-specialist`
- Runtime adapter instruction files are generated at `/workspace/instructions/AGENTS.md` and `/workspace/instructions/copilot-instructions.md`.
- VS Code chat defaults are ensured at `/workspace/settings/vscode/settings.json`.
- Compliance Officer runtime instructions include `10-templates/compliance-officer-pr-review-brief.md` (or image fallback) as a required protocol include.
- If a role profile is missing, startup falls back to existing config values.
