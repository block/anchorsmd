# ANCHORS

Requirements-driven development for AI agents.

ANCHORS keeps product requirements, engineering requirements, testing strategy, and implementation in a consistent, traceable hierarchy — plain markdown files, no build tooling. It gives agents a structured context for understanding what to build, how to build it, and how to verify it.

The framework is agent-agnostic: the documents are plain markdown that any agent can read. The `/anchors` skill automates scaffolding and auditing for agents with skills support (Claude Code, Amp, Codex, etc.), but the documents work without it.

## Install

```bash
./install.sh
```

The installer prompts for which agent and whether to install user-level or project-level. It copies the skill to the appropriate location:

| Agent | User-level | Project-level |
|-------|-----------|---------------|
| Claude Code | `~/.claude/skills/anchors/` | `.claude/skills/anchors/` |
| Amp | `~/.config/agents/skills/anchors/` | `.agents/skills/anchors/` |
| Codex | `~/.codex/skills/anchors/` | `.agents/skills/anchors/` |
| [ai-rules](https://github.com/block/ai-rules) | — | `ai-rules/skills/anchors/` |

For **ai-rules**, the installer copies the skill into `ai-rules/skills/anchors/` and runs `ai-rules generate` to produce agent-specific configuration files. This requires the `ai-rules` CLI and an existing `ai-rules/` directory in your project (`ai-rules init`). ai-rules is always project-level.

## Usage

With the skill installed:

```
/anchors init           # Scaffold ANCHORS documents in a directory
/anchors init path/to   # Scaffold in a specific directory
/anchors audit          # Audit traceability across all modules
/anchors embed          # Convert detached module to embedded
/anchors                # Interactive — choose init, audit, or embed
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

## Embedded vs detached mode

ANCHORS operates in two modes:

**Embedded** (default) — docs live in the same repo as the code. Requirement IDs are tagged inline in source and test files. Init researches the local codebase. Audit searches local code for traceability. This is what you use when you own the repo.

**Detached** — docs live separately from the code they describe. `ANCHORS.md` frontmatter includes `mode: detached`, and ERD.md uses `→` forward references to trace requirements to code locations in the target. The target code is never modified. Detached mode works both within the same repo (in-repo) and across repos (external).

### When to use detached mode

- **Keeping requirements separate from code in a monorepo.** Put anchors docs in a dedicated subdirectory (e.g., `apps/penpal/anchors/`) pointing at sibling code. You get structured traceability without littering the codebase with inline tags.
- **Understanding a codebase you don't own.** Create a docs repo, run `/anchors init`, point it at the target. You get structured requirements docs with `→` refs to specific files and symbols — a navigable map organized by functional area.
- **Developing against code you can't modify.** Your docs describe the contract you depend on, pinned to a specific ref. Bump the ref and re-audit to detect breaking changes.
- **Documenting a third-party service or library.** Track what you depend on and where, without forking or modifying anything.

### Detached mode setup

During `/anchors init`, if the target directory has no code, the skill asks whether you're describing code elsewhere in the repo or in an external repo.

**In-repo detached** — anchors docs in the same repo, pointing at nearby code:

```yaml
# apps/penpal/anchors/ANCHORS.md
---
prefix: PENPAL
mode: detached
path: ..              # relative to this file → apps/penpal/
---
```

**External detached** — anchors docs in a separate repo:

```yaml
# ANCHORS.md
---
prefix: AUTH
mode: detached
repo: github.com/org/auth-service   # target codebase
ref: main                            # branch, tag, or SHA
path: src/auth                       # subdirectory (optional)
---
```

Both produce docs with forward references:

```markdown
- **E-AUTH-SESSION**: Sessions use signed JWTs with 24-hour expiry.
  ← [P-AUTH-LOGIN](PRODUCT.md#P-AUTH-LOGIN)
  → `src/auth/session.go:NewSession`, `src/auth/middleware.go:ValidateToken`
```

Audit resolves the target (locally for in-repo, clone/fetch for external) and verifies each `→` ref — the file exists and the symbol is findable. Broken refs show up in the audit report.

### Converting to embedded mode

If you find detached docs useful and want to fully adopt ANCHORS in the codebase, run `/anchors embed`. This:

1. Reads the `→` forward references from ERD.md
2. Adds inline requirement tags to the source files at each referenced location
3. Removes the `→` lines from ERD.md
4. Removes `mode`/`repo`/`ref`/`path` from ANCHORS.md, switching to embedded mode

The code must be locally accessible (already local for in-repo; for external, you must have a local clone). After embedding, `/anchors audit` searches local code for inline tags like any embedded module.

## Monorepo support

Any directory with an `ANCHORS.md` file is a module. Modules can nest arbitrarily and cross-reference each other with relative paths. Each module declares a unique prefix (e.g., `AUTH`, `PAY`) that scopes its requirement IDs.
