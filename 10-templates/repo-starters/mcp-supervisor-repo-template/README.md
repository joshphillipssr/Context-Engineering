# MCP Supervisor Repo Template (Proposed)

This starter scaffolds a dedicated, containerized MCP supervisor repository governed by Context-Engineering.

## Purpose

- Provide a reusable repo scaffold for `ask_codex_supervisor` escalation.
- Keep tool contract schemas canonical and synced from Context-Engineering.
- Establish a baseline container package layout for local and CI publishing.

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
