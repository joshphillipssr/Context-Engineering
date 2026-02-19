# MCP Contracts

This directory contains canonical tool-contract schemas for MCP services governed by Context-Engineering.

## Current Contracts

- `ask-codex-supervisor.request.schema.json`
- `ask-codex-supervisor.response.schema.json`
- `ask-codex-supervisor.tool.json`

These schemas define the contract for escalation from local worker agents to a Codex supervisor.

## Governance Rule

- Context-Engineering is the source of truth for contract shape and policy semantics.
- Generated or published MCP repositories should consume these schemas without hand-edit drift.
