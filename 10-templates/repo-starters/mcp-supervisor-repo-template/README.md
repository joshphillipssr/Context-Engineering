# MCP Supervisor Repo Template (Proposed)

This starter scaffolds a dedicated, containerized MCP supervisor repository governed by Context-Engineering.

## Purpose

- Provide a reusable repo scaffold for `ask_codex_supervisor` escalation.
- Keep tool contract schemas canonical and synced from Context-Engineering.
- Establish a baseline container package layout for local and CI publishing.
- Default generated runtime to long-lived network transport for container use.
- Default generated backend to local Codex CLI with API mode optional.
- Include explicit provider/auth/runtime controls while retaining fail-safe behavior.

## Output Shape

The renderer writes this minimum file set to the target repository:

- `README.md`
- `Dockerfile`
- `docker-compose.yml`
- `.env.example`
- `requirements.txt`
- `src/supervisor_mcp_server.py`
- `contracts/ask-codex-supervisor.request.schema.json`
- `contracts/ask-codex-supervisor.response.schema.json`
- `contracts/ask-codex-supervisor.tool.json`

## Source Inputs

Canonical contracts are sourced from:

- `10-templates/mcp-contracts/`

## Renderer

Script:

- `scripts/render-mcp-supervisor-repo-template.sh`

Required args:

- `--repo-name`
- `--output-dir`

Optional args:

- `--source-ref` (defaults to current `git rev-parse --short HEAD`)
- `--force` (allow writing into non-empty output directories)

## Example

```bash
10-templates/repo-starters/mcp-supervisor-repo-template/scripts/render-mcp-supervisor-repo-template.sh \
  --repo-name codex-supervisor-mcp \
  --output-dir /tmp/codex-supervisor-mcp
```

## Generated Runtime Notes

- Generated `.env.example` includes:
  - `SUPERVISOR_BIND_HOST` / `SUPERVISOR_BIND_PORT`
  - `SUPERVISOR_TRANSPORT` (default `streamable-http`)
  - `SUPERVISOR_ENABLE_CODEX_PROXY`
  - `SUPERVISOR_CODEX_PROVIDER` (default `cli`)
  - `SUPERVISOR_CODEX_CLI_BIN` / `SUPERVISOR_CODEX_CLI_TIMEOUT_SECONDS`
  - `CODEX_API_KEY` / `CODEX_MODEL`
  - `CODEX_API_BASE_URL` / `CODEX_API_RESPONSES_PATH`
  - `CODEX_API_TIMEOUT_SECONDS` / `CODEX_MAX_OUTPUT_TOKENS`
- Generated image installs `codex` CLI and persists auth state at `/root/.codex` via compose volume.
- Generated starter calls Codex CLI by default when proxy mode is enabled.
- API mode remains optional behind explicit provider selection.
- Any provider/parsing/validation failure returns schema-valid fail-safe `pause_for_human`.
