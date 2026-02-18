# Agent Instructions (Centralized, Tool-Agnostic)

## Purpose

This directory is the canonical source for role-based agent instructions used across runtimes.

Use it for:

- Codex runtime instruction generation
- Copilot role framing references
- Other agent adapters (for example, Ollama-based runtimes)

## Structure

- `base.md`: shared instructions that apply to every role
- `roles/<role>.md`: role-specific overlays

## Consumption Pattern

- Runtime adapters should treat role-repo `AGENTS.md` as canonical whenever available.
- `base.md` + `roles/<role>.md` are fallback composition sources for runtime bootstrap and image build contexts.
- Required role-specific protocol includes remain mandatory (for Compliance Officer: `10-templates/compliance-officer-pr-review-brief.md`).

Codex devcontainer startup currently materializes runtime artifacts as:

- `/workspace/instructions/role-instructions.md` (bootstrap loader that points to role-repo `AGENTS.md`)
- `/workspace/instructions/AGENTS.md`
- `/workspace/instructions/copilot-instructions.md`

Other runtimes should preserve this policy: `AGENTS.md` is canonical, runtime adapter files are loaders.
