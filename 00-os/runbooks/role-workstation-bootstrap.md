# Role Workstation Bootstrap Runbook

## Overview

This runbook documents the automated bootstrap behavior for role-scoped workstation containers and common troubleshooting procedures.

## Purpose

Role workstations use a shared bootstrap script (`.devcontainer-workstation/scripts/init-workstation.sh`) that runs at container startup to:
- Apply role-specific configuration overlays
- Seed VS Code machine settings for command auto-approval
- Generate runtime instruction adapters
- Configure role GitHub App authentication when available
- Auto-clone the role workspace repository

## When to Use

- **New workstation startup**: Understanding what happens at first boot
- **VS Code command approval issues**: Why users see repeated approval prompts
- **Role auth troubleshooting**: When role GitHub App identity is not applied
- **Configuration drift**: Container behavior differs from expected defaults
- **Issue/PR safety preflight**: Before creating issues or PRs from role containers

## Bootstrap Sequence

### 1. Codex Role Profile Application

**Location**: `apply_role_profile()` in `init-workstation.sh`

**Actions**:
- Loads role-specific profile from `.devcontainer-workstation/codex/role-profiles/${ROLE_PROFILE}.env`
- Forces container-appropriate overrides:
  - `approval_policy = "never"`
  - `sandbox_mode = "danger-full-access"`
  - `writable_roots = ["/"]`
- Applies role personality and reasoning effort settings

**Why forced overrides exist**: Role workstations intentionally run with full in-container access because isolation is provided at the container boundary, not within the container.

### 2. VS Code Machine Settings Seeding

**Location**: `ensure_vscode_machine_settings()` in `init-workstation.sh`

**Target file**: `/root/.vscode-server/data/Machine/settings.json`

**Settings applied**:
```json
{
  "chat.tools.global.autoApprove": true,
  "chat.tools.terminal.enableAutoApprove": true,
  "chat.tools.terminal.autoApprove": {
    "/.*/": true
  }
}
```

**Why machine-scoped**: These are VS Code Remote machine settings that persist across all workspaces opened in the container, not repo-scoped settings.

**Override mechanism**: Set `RUNTIME_VSCODE_MACHINE_SETTINGS_FILE` environment variable before container startup to change the target path.

**Common issue**: If users still see command approval prompts after clicking "Allow all commands in this session", it indicates:
- The machine settings file was not written (check container logs)
- VS Code server data directory path changed (verify with `ls -la /root/.vscode-server/data/Machine/`)
- Settings were overridden by user-scoped or workspace-scoped settings (check precedence)

### 3. Role GitHub App Auth Setup

**Location**: `setup-role-github-app-auth.sh` (called when `ROLE_GITHUB_AUTH_MODE=app`)

**Requirements**:
- `ROLE_GITHUB_APP_ID`
- `ROLE_GITHUB_APP_INSTALLATION_ID`
- `ROLE_GITHUB_APP_PRIVATE_KEY_PATH` (PEM file mount)

**Actions**:
- Generates GitHub installation token from JWT
- Configures `gh` CLI with role app identity
- Writes auth metadata to `/workspace/instructions/role-github-app-auth.env`

**Validation**:
```bash
# Inside container
gh auth status --hostname github.com
gh api graphql -f query='{viewer{login}}' --jq '.data.viewer.login'
```

**Expected output**: App slug (e.g., `a-systemsarchitect[bot]`), not a user login.

**Common issue**: `401 Bad credentials` after ~1 hour → Installation tokens expire; prefer `gh-role` (auto-preflights API auth freshness and re-mints when stale), or run `/usr/local/bin/remint-role-github-app-auth.sh` manually.

### 3.5 Fork-First Repo Preflight (Required)

**Location**: `00-os/scripts/ensure-role-repo-fork-first.sh`

**Required before issue/PR operations**:
- Run this in the role repository before any `gh issue ...`, `gh pr ...`, or push operation.
- This enforces deterministic repo-local push targeting and validates owner context.

**Command**:
```bash
./00-os/scripts/ensure-role-repo-fork-first.sh
```

**What it enforces (repo-local only)**:
- `remote.pushDefault=origin`
- `branch.<current>.pushRemote=origin`
- `remote.origin.gh-resolved=base`
- If `upstream` points to `joshphillipssr/*`, upstream push URL is set to `DISABLED` while fetch remains intact.

**Owner guardrail**:
- Preflight exits non-zero unless `origin` owner is `Josh-Phillips-LLC`.
- Explicit override (for deliberate non-canonical targets):
```bash
./00-os/scripts/ensure-role-repo-fork-first.sh --allow-origin-owner-mismatch
```

**Why required**: Prevents accidental issue/PR/push actions to `joshphillipssr/*` when canonical role-container targets should be `Josh-Phillips-LLC/*`.

### 4. Runtime Instruction Generation

**Location**: `render_runtime_role_instructions()` in `init-workstation.sh`

**Generated files**:
- `/workspace/instructions/role-instructions.md` (bootstrap loader, not canonical instructions)
- `/workspace/instructions/AGENTS.md` (adapter pointing to role-repo canonical file)
- `/workspace/instructions/copilot-instructions.md` (Copilot adapter)
- `/workspace/instructions/continue-instructions.md` (Continue adapter)
- `/workspace/instructions/agent-runtime-policy.md` (full in-container access policy statement)

**Design**: All adapters point to the role-repo `AGENTS.md` as canonical. If `AGENTS.md` is missing, bootstrap mode restricts actions to recovery/clone operations only.

**Break-glass override**: Set `ALLOW_FALLBACK_INSTRUCTIONS=true` to permit operator actions when `AGENTS.md` is unavailable.

### 5. Workspace Repository Auto-Clone

**Location**: End of `init-workstation.sh`

**Trigger**: `AUTO_CLONE_WORKSPACE_REPO=true` (default)

**Target**: `WORKSPACE_REPO_DIR` (defaults to `/workspace/Projects/context-engineering-role-${ROLE_PROFILE}`)

**Behavior**:
- Skips clone if directory exists and is non-empty
- Logs warning if clone fails
- Does not block container startup on clone failure

**Manual recovery**:
```bash
docker exec -it <container-name> bash
cd /workspace/Projects
git clone <role-repo-url>
```

## Troubleshooting

### VS Code still prompts for command approval

**Symptoms**: User clicks "Allow all commands in this session" but gets prompted again in future sessions.

**Root cause**: Machine settings file not seeded or not persisted.

**Resolution**:
1. Check bootstrap logs:
   ```bash
   docker logs <container-name> | grep "Ensured VS Code machine settings"
   ```
2. Verify file exists and has correct content:
   ```bash
   docker exec <container-name> cat /root/.vscode-server/data/Machine/settings.json
   ```
3. If missing, restart container (bootstrap runs on every startup):
   ```bash
   docker compose restart <container-name>
   ```
4. If present but ignored, check VS Code settings precedence (user settings may override machine settings).

### Role GitHub App auth not applied

**Symptoms**: `gh auth status` shows user identity instead of app identity, or `Not logged in`.

**Root cause**: App mode variables missing, PEM mount failed, or `GH_TOKEN`/`GITHUB_TOKEN` env vars override app auth.

**Resolution**:
1. Verify app mode is enabled:
   ```bash
   docker exec <container-name> bash -c 'echo $ROLE_GITHUB_AUTH_MODE'
   ```
   Should output: `app`

2. Check required variables are set:
   ```bash
   docker exec <container-name> bash -c 'cat /workspace/instructions/role-github-app-auth.env'
   ```

3. Verify PEM mount is readable:
   ```bash
   docker exec <container-name> ls -la /run/secrets/role_github_app_private_key
   ```

4. Re-mint token manually (or run the target command through `gh-role` to trigger wrapper preflight):
   ```bash
   docker exec <container-name> /usr/local/bin/remint-role-github-app-auth.sh
   ```

5. If still failing, check if `GH_TOKEN` or `GITHUB_TOKEN` is set (these override app auth):
   ```bash
   docker exec <container-name> bash -c 'env | grep -E "^(GH_TOKEN|GITHUB_TOKEN)="'
   ```
   Should be empty. If set, unset in compose environment or use `gh-role` wrapper.

### AGENTS.md bootstrap-only mode

**Symptoms**: Agent reports it can only perform bootstrap/recovery actions.

**Root cause**: Role-repo `AGENTS.md` is missing or unreadable.

**Expected scenarios**:
- First-time role setup (repo not cloned yet)
- Clone failed during bootstrap
- Permissions issue on workspace volume

**Resolution**:
1. Verify role repo clone status:
   ```bash
   docker exec <container-name> ls -la /workspace/Projects/context-engineering-role-<role-slug>/AGENTS.md
   ```

2. If missing, clone manually (see auto-clone recovery above).

3. If present but reported as unreadable, check file permissions:
   ```bash
   docker exec <container-name> ls -l /workspace/Projects/context-engineering-role-<role-slug>/AGENTS.md
   ```

4. After fixing, restart IDE/agent session (no container restart needed).

### Container fails to start

**Symptoms**: `docker compose up` exits with error, or container stops immediately after starting.

**Common causes**:
1. Invalid compose environment variables (e.g., malformed PEM path)
2. Volume mount conflicts
3. Bootstrap script syntax errors (rare; caught by CI)

**Resolution**:
1. Check compose logs:
   ```bash
   docker compose logs --tail=50 <container-name>
   ```

2. Verify environment variables:
   ```bash
   docker compose config | grep -A 10 <container-name>
   ```

3. Test bootstrap script directly:
   ```bash
   docker run --rm -it --entrypoint bash <image-name>
   bash -n /usr/local/bin/init-workstation.sh
   ```

## Override Mechanisms

### Environment Variables

Set these before `docker compose up` to customize bootstrap behavior:

| Variable | Default | Purpose |
|----------|---------|---------|
| `WORKSTATION_DEBUG` | `false` | Verbose bootstrap logging |
| `ROLE_PROFILE` | (from image build arg) | Override role profile |
| `ALLOW_FALLBACK_INSTRUCTIONS` | `false` | Break-glass AGENTS.md bypass |
| `AUTO_CLONE_WORKSPACE_REPO` | `true` | Skip auto-clone |
| `RUNTIME_VSCODE_MACHINE_SETTINGS_FILE` | `/root/.vscode-server/data/Machine/settings.json` | Change VS Code settings path |

### Example: Debug mode startup

```bash
export WORKSTATION_DEBUG="true"
docker compose up -d implementation-workstation
docker compose logs -f implementation-workstation
```

## Integration with Published Images

### GHCR Packages

Published role workstation images at `ghcr.io/josh-phillips-llc/context-engineering-workstation-<role-slug>:latest` include:
- Identical bootstrap script to local builds
- Role-specific baked instructions (fallback only)
- Same override mechanisms
- All bootstrap behaviors documented here

**No differences** in runtime behavior between local builds and GHCR images for the bootstrap sequence.

### Startup Command

Both local and GHCR deploys use:
```dockerfile
ENTRYPOINT ["/usr/local/bin/init-workstation.sh"]
CMD ["sleep", "infinity"]
```

Bootstrap runs before `sleep infinity`, so all seeding completes during container startup.

## Related Documentation

- **Setup Guide**: `.devcontainer-workstation/README.md`
- **Fork-First Preflight Script**: `00-os/scripts/ensure-role-repo-fork-first.sh`
- **Auth Validation**: `00-os/runbooks/github-app-bootstrap-validation.md`
- **Permission Escalation**: `00-os/runbooks/github-app-permission-escalation.md`
- **Bootstrap Script Source**: `.devcontainer-workstation/scripts/init-workstation.sh`

## Maintenance

This runbook should be updated when:
- Bootstrap script behavior changes
- New seeded settings are added
- Override mechanisms change
- New role workstation images are published with breaking changes

**Review cadence**: After each bootstrap script change or when troubleshooting patterns emerge.
