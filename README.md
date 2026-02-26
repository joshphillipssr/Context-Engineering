

# Context-Engineering

## Split Status (ADR 0002)

Effective **2026-02-26**, this repository is a **legacy mixed-layout coordination repo** during deprecation.

Canonical source-of-truth repositories are now:

- Governance policy authority: [`Josh-Phillips-LLC/context-engineering-governance`](https://github.com/Josh-Phillips-LLC/context-engineering-governance)
- Implementation/tooling authority: [`Josh-Phillips-LLC/context-engineering-implementation`](https://github.com/Josh-Phillips-LLC/context-engineering-implementation)

Use these cutover references before making changes:

- [`REPOSITORY_SOURCE_OF_TRUTH_MAP.md`](./REPOSITORY_SOURCE_OF_TRUTH_MAP.md)
- [`MIXED_LAYOUT_DEPRECATION_NOTICE.md`](./MIXED_LAYOUT_DEPRECATION_NOTICE.md)
- [`00-os/runbooks/split-repository-cutover-and-rollback.md`](./00-os/runbooks/split-repository-cutover-and-rollback.md)

---

This repository defines how AI context is designed, curated, reviewed, and published across Josh's projects.

It defines **how humans and AI collaborate**, not just what tools are used. Tools are replaceable; **context structure is not**.

---

## What this repo is (and is not)

### This repo **is**
- A legacy transition workspace for mixed-layout artifacts that are being deprecated per ADR 0002
- A historical reference for:
  - prior AI operating model artifacts
  - context design patterns
  - prompt and review templates
  - session canvases and publication records
- A public-safe governance repository that documents both Plane A and Plane B practices
- Designed to be durable across:
  - VS Code Copilot
  - Codex
  - Continue
  - ChatGPT
  - Future LLMs and agents

### This repo **is not**
- A codebase
- A place to store secrets or credentials
- A dumping ground for ad-hoc notes
- A public-facing documentation site

---

## Core documents

These files define the foundation of the system and should change slowly.

- **`index.md`**  
  Repository map (link-first entry point).

- **`governance.md`**  
  The authoritative AI Context & Workspace Operating Model  
  Defines roles, context planes, canvas lifecycle, security model, and persistence strategy.

- **`canvas.md`**  
  Exploratory canvas (ideas, rationale, options, roadmap, experiments).

- **`context-flow.md`**  
  A visual map of how context, prompts, and artifacts flow between:
  - Executive Sponsor (Josh)
  - AI Governance Manager (ChatGPT)
  - Implementation Specialists
  Including how private context becomes public-safe repo context.

---

## Mental model: Context planes

This system is built around **two explicit planes of context**:

### Plane A — Public / Portable Context
- Lives *with code repositories*
- Safe for public repos
- Includes repo canvases, Copilot instructions, architecture docs, and sanitized prompts
- This is what agents consume by default

### Plane B — Private / Operational Context
- Lives in private operational systems (not this repo)
- May contain sensitive assumptions, internal workflows, and unredacted canvases
- Feeds curated, sanitized artifacts into Plane A
- This repo defines the Plane B policy and guardrails

**Rule:** Nothing moves from Plane B to Plane A without intentional curation.

---

## Canvas lifecycle (durable memory)

Chat history is ephemeral. **Canvases are durable.**

1. **Session Canvas (private)**  
   Created during active thinking or ChatGPT sessions. May contain raw ideas and sensitive data.

2. **Publishable Extract (curated)**  
   A clearly marked subset of a session canvas that is safe to share.

3. **Repo Canvas (public-safe)**  
   Published into a code repository (usually under `docs/ai/`) and becomes durable agent context.

---

## Expected repository structure (high level)

This repo is intentionally structured to separate **operating system**, **templates**, **canvases**, and **tool-specific knowledge**.

You will see folders such as:
- `00-os/` — operating model, workflows, security rules
- `10-templates/` — repo starters, prompt templates, review checklists
- `20-canvases/` — session canvases and publication logs
- `30-vendor-notes/` — tool-specific behaviors and quirks
- `40-private/` — policy boundary marker for non-public content

Exact contents may evolve, but the separation of concerns should remain.

---

## Security posture

This repository is designed to be public-safe, but still follows strict rules:

- **No secrets or credentials** are stored here
- Sensitivity is explicitly tiered: **Public, Internal, Secret**
- Only Public artifacts are allowed to leave this repo
- Secret (credentials, tokens, PII) is never committed
- Assume anything copied into a code repo may become public
- Truly private operational material belongs outside this repo

---

## How this repo is used in practice

- The Executive Sponsor (Josh) defines goals and constraints
- The AI Governance Manager (ChatGPT) helps:
  - design context
  - generate prompts
  - review agent output
- Implementation Specialists (Copilot / Codex / Continue) execute using **repo-local, public-safe context**
- Durable knowledge always lands in files, not chat logs

---

## Contribution rules (especially for AI agents)

If you are an AI agent operating in this repo:

- Treat `governance.md` and `context-flow.md` as authoritative
- Prefer **templates, checklists, and structure** over long prose
- Do not invent new top-level folders without explicit instruction
- Do not include secrets or environment-specific data
- When in doubt, add TODOs instead of guessing

---

## Guiding principle

> **Stability comes from files, not sessions.**  
> Context is infrastructure.

This repository exists to make that principle real.
