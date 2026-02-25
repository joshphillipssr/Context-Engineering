# Governance Registries and Generator

## Overview

This directory contains:
- **role-registry.yml**: Canonical source of truth for all role metadata
- **governed-repos.yml**: Canonical source of truth for repository governance state
- **scripts/generate-role-wiring.py**: Generator script that produces role wiring code from the registry

## Purpose

- Eliminates hardcoded role duplication across multiple files by generating role-specific configuration from a single registry.
- Maintains a canonical registry of Context-Engineering-governed repositories and adoption state.

## Usage

After modifying `role-registry.yml`:

```bash
# Generate all role wiring
python3 00-os/scripts/generate-role-wiring.py

# Check if generated files are up to date (CI mode)
python3 00-os/scripts/generate-role-wiring.py --check
```

After modifying governance ownership files:

```bash
# Validate governance ownership artifacts
python3 00-os/scripts/validate-governance-ownership.py
```

This validates:
- `00-os/governed-repos.yml`
- `.context-engineering/governance.yml`

## Generated Targets

The generator updates marked sections in:

1. **`.github/workflows/sync-role-repos.yml`**
   - Role matrix for sync jobs
   - Role choices for workflow_dispatch

2. **`.github/workflows/publish-role-workstation-images.yml`**
   - Role matrix for publish jobs

3. **`.devcontainer-workstation/scripts/start-role-workstation.sh`**
   - Role selection menu
   - Role normalization cases
   - Role-to-variables mapping

4. **`.devcontainer-workstation/docker-compose.yml`** and **`.devcontainer-workstation/docker-compose.ghcr.yml`**
   - Service definitions for each role (local build and GHCR variants)
   - Volume declarations

## Adding a New Role

1. Add entry to `role-registry.yml` with all required fields
2. Run generator: `python3 00-os/scripts/generate-role-wiring.py`
3. Verify changes with: `git diff`
4. Commit both `role-registry.yml` and generated files together

## Registry Schema

See `role-registry.yml` for the canonical schema and inline documentation.
See `governed-repos.yml` for repository governance ownership state.

## Marker Format

Generated sections are marked with comment pairs:
```
# GENERATED:BEGIN:MARKER_NAME
... generated content ...
# GENERATED:END:MARKER_NAME
```

**DO NOT** manually edit content between these markers - modify the registry and regenerate instead.
