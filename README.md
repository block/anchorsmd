# ANCHORS

Requirements-driven development for AI agents.

ANCHORS keeps product requirements, engineering requirements, testing strategy, and implementation in a consistent, traceable hierarchy — plain markdown files, no build tooling. It gives agents a structured context for understanding what to build, how to build it, and how to verify it.

The framework is agent-agnostic: the documents are plain markdown that any agent can read. The `/anchors` skill automates scaffolding and auditing for agents with skills support (Claude Code, Amp, Codex, etc.), but the documents work without it.

## Install

```bash
./install.sh
```

The installer prompts for which agent (Claude Code, Amp, or Codex) and whether to install user-level or project-level. It copies the skill to the appropriate location:

| Agent | User-level | Project-level |
|-------|-----------|---------------|
| Claude Code | `~/.claude/skills/anchors/` | `.claude/skills/anchors/` |
| Amp | `~/.config/agents/skills/anchors/` | `.agents/skills/anchors/` |
| Codex | `~/.codex/skills/anchors/` | `.agents/skills/anchors/` |

## Usage

With the skill installed:

```
/anchors init           # Scaffold ANCHORS documents in a directory
/anchors init path/to   # Scaffold in a specific directory
/anchors audit          # Audit traceability across all modules
/anchors                # Interactive — choose init or audit
```

Without the skill, create the documents manually — see the templates in `skill/templates/`.

### Init

Creates five files in the target directory:

| File | Purpose |
|------|---------|
| `ANCHORS.md` | Module marker with `prefix` in frontmatter |
| `PRODUCT.md` | Product requirements (source of truth) |
| `ERD.md` | Engineering requirements (derived from PRD) |
| `TESTING.md` | Testing strategy and coverage mapping |
| `DEPENDENCIES.md` | External dependencies |

### Audit

Checks traceability across all modules in the repo:

- Every `E-*` requirement has a `←` backlink to a `P-*` requirement
- Every `P-*` requirement is covered by at least one `E-*`
- Requirement IDs in code and tests are tracked
- Stale code references to removed requirements are flagged
- Cross-module references resolve to real files and anchors
- Unresolved `OPEN-*` questions are listed

## How it works

ANCHORS defines a truth hierarchy:

```
PRODUCT.md        ← source of truth (what)
  → ERD.md        ← technical design (how), must satisfy PRD
    → Tests       ← executable spec, truthier than implementation
      → Code      ← must satisfy everything above
```

When things disagree, higher-authority documents win. Every `E-*` requirement links back to the `P-*` it satisfies. The audit verifies these links are complete and consistent.

## Monorepo support

Any directory with an `ANCHORS.md` file is a module. Modules can nest arbitrarily and cross-reference each other with relative paths. Each module declares a unique prefix (e.g., `AUTH`, `PAY`) that scopes its requirement IDs.
