# Devcontainer Workstation Setup

This workflow builds the container from scratch outside VS Code, then attaches VS Code to the running container.
It supports role-scoped startup for:

- `implementation-workstation` (default `Implementation Specialist` profile)
- `compliance-workstation` (`Compliance Officer` profile)
- `systems-architect-workstation` (`Systems Architect` profile)
- `hr-ai-agent-specialist-workstation` (`HR and AI Agent Specialist` profile)

## 0) Recommended launcher (prompted role/auth/PEM)

Use the host-side launcher script to avoid manual compose/env wiring:

```bash
cd /path/to/Context-Engineering/.devcontainer-workstation
./scripts/start-role-workstation.sh
```

The launcher prompts for:

- Image source (`ghcr` or `local`)
- Role
- Auth mode (`app` or `user`)
- PEM path (required for `app` mode)
- Optional clone of `Context-Engineering` to `/workspace/Projects/Context-Engineering`

After startup, the launcher checks `codex login status` in-container.
If unauthenticated, it prompts whether to run `codex login --device-auth`.

For `app` mode, it automatically:

- mounts the host PEM into the container as a compose secret
- sets in-container key path to `/run/secrets/role_github_app_private_key`
- clears `GH_TOKEN`/`GITHUB_TOKEN` for startup so role app identity is not overridden

Non-interactive example:

```bash
./scripts/start-role-workstation.sh \
  --source ghcr \
  --role compliance \
  --auth-mode app \
  --pem-path /Users/<you>/Downloads/a-complianceofficer.private-key.pem \
  --clone-context-engineering
```

## 1) Build and start from host

Run these from your host machine terminal (not inside a container):

```bash
cd /path/to/Context-Engineering/.devcontainer-workstation

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  COMPOSE_CMD="docker-compose"
fi

# Optional: set this before startup when ROLE_GITHUB_AUTH_MODE=user and
# the workspace repo is private or you want non-interactive first-boot auth.
export GH_BOOTSTRAP_TOKEN="<your_pat>"
export WORKSTATION_DEBUG="true" # optional: verbose init-workstation logging

# Optional: role GitHub App auth (preferred for role-attributable actions)
# Role app IDs and installation IDs are preconfigured per workstation service
# in docker-compose files. Set only the private key path for the role you start.
# Keep GH_TOKEN/GITHUB_TOKEN unset in app mode; those env vars override
# role-app identity for gh/MCP calls when present in container env.
# The private key path must be mounted into the container (file path only).
# export IMPLEMENTATION_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="/run/secrets/role_github_app_private_key"
# export COMPLIANCE_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="/run/secrets/role_github_app_private_key"
# export SYSTEMS_ARCHITECT_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="/run/secrets/role_github_app_private_key"
# export HR_AI_AGENT_SPECIALIST_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="/run/secrets/role_github_app_private_key"
# Optional override when needed:
# export COMPLIANCE_ROLE_GITHUB_AUTH_MODE="user"

# Default role-scoped startup (Implementation Specialist)
$COMPOSE_CMD down
$COMPOSE_CMD up -d --build implementation-workstation

# Optional: Compliance Officer role-scoped container
# $COMPOSE_CMD --profile compliance-officer up -d --build compliance-workstation

# Optional: Systems Architect role-scoped container
# $COMPOSE_CMD --profile systems-architect up -d --build systems-architect-workstation

# Optional: HR and AI Agent Specialist role-scoped container
# $COMPOSE_CMD --profile hr-ai-agent-specialist up -d --build hr-ai-agent-specialist-workstation
```

## 1a) Start from published GHCR role packages

Role packages are published by `.github/workflows/publish-role-workstation-images.yml` and can be consumed without local image builds.

```bash
cd /path/to/Context-Engineering/.devcontainer-workstation

if docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  COMPOSE_CMD="docker-compose"
fi

# Optional overrides:
# export GHCR_OWNER="<github-org-or-user>"
# export GHCR_IMAGE_TAG="latest"
# export WORKSPACE_REPO_OWNER="Josh-Phillips-LLC"
# Role app IDs and installation IDs are preconfigured per workstation service.
# Set only the private key path for the role you start.
# export IMPLEMENTATION_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="/run/secrets/role_github_app_private_key"
# export COMPLIANCE_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="/run/secrets/role_github_app_private_key"
# export SYSTEMS_ARCHITECT_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="/run/secrets/role_github_app_private_key"
# export HR_AI_AGENT_SPECIALIST_ROLE_GITHUB_APP_PRIVATE_KEY_PATH="/run/secrets/role_github_app_private_key"

$COMPOSE_CMD -f docker-compose.ghcr.yml down
$COMPOSE_CMD -f docker-compose.ghcr.yml up -d implementation-workstation
# Optional:
# $COMPOSE_CMD -f docker-compose.ghcr.yml --profile compliance-officer up -d compliance-workstation
# $COMPOSE_CMD -f docker-compose.ghcr.yml --profile systems-architect up -d systems-architect-workstation
# $COMPOSE_CMD -f docker-compose.ghcr.yml --profile hr-ai-agent-specialist up -d hr-ai-agent-specialist-workstation
```

Default package names:

- `ghcr.io/josh-phillips-llc/context-engineering-workstation-implementation-specialist:latest`
- `ghcr.io/josh-phillips-llc/context-engineering-workstation-compliance-officer:latest`
- `ghcr.io/josh-phillips-llc/context-engineering-workstation-systems-architect:latest`
- `ghcr.io/josh-phillips-llc/context-engineering-workstation-hr-ai-agent-specialist:latest`

Release naming and versioning conventions:

- Role repo names: `context-engineering-role-<role-slug>`
- Image names: `ghcr.io/<owner>/context-engineering-workstation-<role-slug>`
- Image tags:
  - `latest`
  - `<role-slug>-latest`
  - `<role-slug>-<short-sha>`

Verify the published platforms include both `linux/amd64` and `linux/arm64`:

```bash
docker buildx imagetools inspect ghcr.io/josh-phillips-llc/context-engineering-workstation-implementation-specialist:latest
docker buildx imagetools inspect ghcr.io/josh-phillips-llc/context-engineering-workstation-compliance-officer:latest
docker buildx imagetools inspect ghcr.io/josh-phillips-llc/context-engineering-workstation-systems-architect:latest
docker buildx imagetools inspect ghcr.io/josh-phillips-llc/context-engineering-workstation-hr-ai-agent-specialist:latest
```

If you exported `GH_BOOTSTRAP_TOKEN` for startup bootstrap, clear it after the container is running:

```bash
unset GH_BOOTSTRAP_TOKEN
```

If role GitHub App auth is configured, verify the role identity inside the container:

```bash
gh auth status --hostname github.com
gh api graphql -f query='{viewer{login}}' --jq '.data.viewer.login'
```

Note: `gh api /user` is not a valid role-identity check for GitHub App auth and can return `403 Resource not accessible by integration`.

If App auth variables are missing, startup logs a warning and continues without App auth.

When `gh` starts failing later with `401 Bad credentials` (expired installation token), run the deterministic re-mint helper before issue/branch/PR flows:

```bash
/usr/local/bin/remint-role-github-app-auth.sh
gh auth status --hostname github.com
```

For self-healing CLI usage, prefer the role-safe wrapper:

```bash
gh-role issue list
gh-role pr list
```

`gh-role` runs `gh` with `GH_TOKEN`/`GITHUB_TOKEN` unset and auto-runs `/usr/local/bin/remint-role-github-app-auth.sh` in app mode when auth is stale.

The helper resolves role app metadata from runtime startup output at `/workspace/instructions/role-github-app-auth.env`.
It defaults the key path to `/run/secrets/role_github_app_private_key` when not explicitly set.

If re-mint cannot proceed, it emits explicit errors for:

- missing role app metadata (`ROLE_GITHUB_APP_ID`, `ROLE_GITHUB_APP_INSTALLATION_ID`)
- unreadable/missing PEM secret mount at resolved key path (defaults to `/run/secrets/role_github_app_private_key`)
- non-interactive sessions (no TTY) where prompting is not possible

Typical issue-first usage:

```bash
gh-role issue develop <ISSUE_NUMBER> --checkout
```

If wrapper preflight still encounters auth errors, run the re-mint helper and retry:

```bash
/usr/local/bin/remint-role-github-app-auth.sh
gh-role issue develop <ISSUE_NUMBER> --checkout
```

## Local validation tooling baseline

Role workstation images include:

- `python3`
- `python3 -m pip`
- `python3 -m venv`
- `docker` CLI

Quick checks:

```bash
python3 --version
python3 -m pip --version
python3 -m venv --help >/dev/null
docker --version
```

If `docker` CLI exists but engine/socket access is unavailable in your runtime, use CI validation evidence for container-build checks and include the runtime limitation in your PR validation notes.

## Git Identity Configuration

Role workstations set global Git identity automatically during container startup.
The default identity is role-attributed and uses the role bot account format (for example, `a-implementationspecialist[bot]`).

Source of truth:

- `00-os/role-registry.yml` (`roles[].git_identity`)

Runtime variables used by startup:

- `ROLE_GIT_IDENTITY_NAME`
- `ROLE_GIT_IDENTITY_EMAIL`

Verify current global identity inside the container:

```bash
git config --global user.name
git config --global user.email
```

Optional override for intentional human-authored commits:

```bash
git config --global user.name "<your name>"
git config --global user.email "<your email>"
```

You can restore role-attributed defaults by restarting the role workstation container.

Use this only if you want a full reset of persisted container data:

```bash
$COMPOSE_CMD down -v
$COMPOSE_CMD up -d --build
```

`down -v` removes all role-prefixed named volumes (for example, `implementation_gh_config` and `compliance_gh_config`), so GitHub auth, cloned repos, and other persisted container state are reset.
Codex config is re-seeded from `.devcontainer-workstation/codex/config.toml` when `/root/.codex` is recreated.

Role containers now use role-prefixed named volumes, so running multiple role containers at once does not share `/workspace` or runtime config state between roles.
Each role has isolated volumes for workspace data, GitHub auth config, git config, and codex home.

At container startup, the workstation bootstrap now also seeds VS Code machine settings at:

- `/root/.vscode-server/data/Machine/settings.json`

with:

- `chat.tools.global.autoApprove = true`
- `chat.tools.terminal.enableAutoApprove = true`
- `chat.tools.terminal.autoApprove = {"/.*/": true}`

This applies across all role workstations because they all run the same bootstrap script.
To override the target path, set `RUNTIME_VSCODE_MACHINE_SETTINGS_FILE` in the container environment.

Confirm container is running:

```bash
$COMPOSE_CMD ps
docker ps --filter name=implementation-workstation
docker ps --filter name=compliance-workstation
docker ps --filter name=hr-ai-agent-specialist-workstation
```

If a role container is not `Up`, inspect logs:

```bash
$COMPOSE_CMD logs --tail=200 implementation-workstation
$COMPOSE_CMD logs --tail=200 compliance-workstation
$COMPOSE_CMD logs --tail=200 hr-ai-agent-specialist-workstation
```

## 2) Clone role repos into container-owned storage

The workspace root inside the container is `/workspace` (Docker volume-backed).
On container startup, each role container auto-clones its role repo by default:

- `implementation-workstation`
  - URL: `https://github.com/Josh-Phillips-LLC/context-engineering-role-implementation-specialist.git`
  - Path: `/workspace/Projects/context-engineering-role-implementation-specialist`
- `compliance-workstation`
  - URL: `https://github.com/Josh-Phillips-LLC/context-engineering-role-compliance-officer.git`
  - Path: `/workspace/Projects/context-engineering-role-compliance-officer`
- `systems-architect-workstation`
  - URL: `https://github.com/Josh-Phillips-LLC/context-engineering-role-systems-architect.git`
  - Path: `/workspace/Projects/context-engineering-role-systems-architect`
- `hr-ai-agent-specialist-workstation`
  - URL: `https://github.com/Josh-Phillips-LLC/context-engineering-role-hr-ai-agent-specialist.git`
  - Path: `/workspace/Projects/context-engineering-role-hr-ai-agent-specialist`

Verify clone status:

```bash
docker exec -it implementation-workstation bash -lc 'ls -la /workspace/Projects/context-engineering-role-implementation-specialist'
docker exec -it compliance-workstation bash -lc 'ls -la /workspace/Projects/context-engineering-role-compliance-officer'
docker exec -it systems-architect-workstation bash -lc 'ls -la /workspace/Projects/context-engineering-role-systems-architect'
docker exec -it hr-ai-agent-specialist-workstation bash -lc 'ls -la /workspace/Projects/context-engineering-role-hr-ai-agent-specialist'
```

If auto-clone failed, run manual PAT auth and clone inside the container:

```bash
docker exec -it implementation-workstation bash

# One-time fallback auth inside container (HTTPS + PAT)
read -s -p "GitHub PAT: " GH_PAT; echo
printf '%s' "$GH_PAT" | env -u GH_TOKEN -u GITHUB_TOKEN gh auth login --hostname github.com --git-protocol https --with-token
gh auth setup-git
gh auth status
unset GH_PAT

cd /workspace/Projects
git clone https://github.com/Josh-Phillips-LLC/context-engineering-role-implementation-specialist.git
exit
```

`gh` auth is persisted in each role's role-prefixed gh config volume, so this login should not be required every time for that role.
If needed, you can override default role repo targets with:

- `IMPLEMENTATION_WORKSPACE_REPO_URL`
- `COMPLIANCE_WORKSPACE_REPO_URL`
- `SYSTEMS_ARCHITECT_WORKSPACE_REPO_URL`
- `HR_AI_AGENT_SPECIALIST_WORKSPACE_REPO_URL`
- `IMPLEMENTATION_WORKSPACE_REPO_DIR_NAME`
- `COMPLIANCE_WORKSPACE_REPO_DIR_NAME`
- `SYSTEMS_ARCHITECT_WORKSPACE_REPO_DIR_NAME`
- `HR_AI_AGENT_SPECIALIST_WORKSPACE_REPO_DIR_NAME`

## 3) Attach VS Code to running container

In local (non-containerized) VS Code:

1. Open Command Palette
2. Run `Dev Containers: Attach to Running Container...`
3. Select `implementation-workstation`, `compliance-workstation`, `systems-architect-workstation`, or `hr-ai-agent-specialist-workstation`
4. Open folder matching the role container:
   - `/workspace/Projects/context-engineering-role-implementation-specialist`
   - `/workspace/Projects/context-engineering-role-compliance-officer`
   - `/workspace/Projects/context-engineering-role-systems-architect`
   - `/workspace/Projects/context-engineering-role-hr-ai-agent-specialist`

## 4) Codex config defaults

The container seeds `/root/.codex/config.toml` from `.devcontainer-workstation/codex/config.toml` when the target file is missing.
Then `init-workstation.sh` applies role overlays from `.devcontainer-workstation/codex/role-profiles/` based on `ROLE_PROFILE`.
If `ROLE_PROFILE` is not set at runtime, it defaults to the image-baked `IMAGE_ROLE_PROFILE` value.
It also generates a runtime instruction file at `/workspace/instructions/role-instructions.md`.
In addition, it generates adapter files at:

- `/workspace/instructions/AGENTS.md`
- `/workspace/instructions/copilot-instructions.md`
- `/workspace/instructions/continue-instructions.md`
- `/workspace/instructions/agent-runtime-policy.md`
- `/workspace/instructions/role-github-app-auth.env` (role app metadata for deterministic re-mint helper)

Default runtime behavior is AGENTS-canonical with bootstrap gating:

- Runtime `role-instructions.md` is a bootstrap loader, not a second policy source.
- Canonical role contract remains role-repo `AGENTS.md`: `<workspace-role-repo>/AGENTS.md`.
- If `AGENTS.md` is missing/unreadable, runtime instructions stay in bootstrap-only mode (clone/sync/auth recovery actions only) until restored.

Break-glass override:

- Set `ALLOW_FALLBACK_INSTRUCTIONS=true` to permit operator break-glass operation while AGENTS is unavailable.
- Even with break-glass enabled, role-repo `AGENTS.md` remains canonical and should be restored before normal role execution.

Example break-glass startup:

```bash
export ALLOW_FALLBACK_INSTRUCTIONS=true
bash .devcontainer-workstation/scripts/start-role-workstation.sh --role hraias --source ghcr --auth-mode app --pem-path ~/Downloads/a-hraiagentspecialist.2026-02-17.private-key.pem
```

Role-specific images still bake `/etc/codex/runtime-role-instructions/<role>.md` from role-repo artifacts when available at build time (operator fallback, not canonical runtime contract).

For `Compliance Officer`, the runtime file includes the PR review protocol from `10-templates/compliance-officer-pr-review-brief.md` (or the image fallback copy when the workspace file is not present).

The init script also ensures VS Code chat defaults at `/workspace/settings/vscode/settings.json`:

- `"github.copilot.chat.codeGeneration.useInstructionFiles": true`
- `"chat.useAgentsMdFile": true`
- `"chat.includeApplyingInstructions": true`
- `"chat.includeReferencedInstructions": true`

### Full in-container access policy

Role workstations intentionally run all in-container agent runtimes with full container-local access.
This policy applies to Codex, Copilot, Continue, and future in-container integrations.
For Codex, defaults are enforced as `approval_policy = "never"`, `sandbox_mode = "danger-full-access"`, and writable roots fallback `writable_roots = ["/"]`.
This is safe in this architecture because each role runs in an isolated, role-scoped container with role attribution and separated runtime state.
Expected behavior: commands that use temp paths (for example `/tmp` and `mktemp`) run without approval prompts.

## 5) Source-of-truth model (multi-agent)

Canonical role-based instruction sources live in:

- `10-templates/agent-instructions/base.md`
- `10-templates/agent-instructions/roles/implementation-specialist.md`
- `10-templates/agent-instructions/roles/compliance-officer.md`
- `10-templates/agent-instructions/roles/hr-ai-agent-specialist.md`
- `10-templates/compliance-officer-pr-review-brief.md` (required protocol include for Compliance Officer)

These files are tool-agnostic and should be reused by non-Codex runtimes (for example, Copilot or Ollama adapters) rather than duplicating role logic in vendor-specific locations.

Published GHCR role packages are role-repo driven:

- Build pipeline fetches each role repo and uses role-repo `AGENTS.md` as runtime instruction source for that role image.
- If role-repo source is unavailable in build context, image build falls back to repository-governed instruction sources in `Context-Engineering`.
- Publish fails when the role-repo `AGENTS.md` `Source ref` does not match the current `Context-Engineering` commit; rerun sync and publish after the sync PR merges.
- Governance remains authoritative in `Context-Engineering`; role repos are generated/synced distribution artifacts.

To update the default Codex settings for this workstation config:

1. Edit `.devcontainer-workstation/codex/config.toml` (base defaults) and/or `.devcontainer-workstation/codex/role-profiles/*.env` (role overlay values)
2. Rebuild/restart:

```bash
$COMPOSE_CMD up -d --build implementation-workstation
```
