# ANCHORS

Requirements-driven development for AI agents.

ANCHORS keeps product requirements, engineering requirements, testing strategy, and implementation in a consistent, traceable hierarchy — plain markdown files, no build tooling. It gives agents a structured context for understanding what to build, how to build it, and how to verify it.

The framework is agent-agnostic: the documents are plain markdown that any agent can read. The `/anchors` skill automates setup and checking for agents with skills support (Claude Code, Amp, Codex, etc.), but the documents work without it.

## Install

```bash
brew install anchors    # or npm, cargo, etc.
```

The `anchors` CLI handles deterministic operations — scaffolding, structural linting, skill management. The `/anchors` skill handles LLM-powered operations — codebase research, content population, semantic analysis.

## Quick start

Set up ANCHORS in a module using the skill:

```
/anchors setup
```

The skill asks for a name, prefix, and mode, then invokes the CLI to scaffold documents and install the skill in your repo, then researches your codebase and populates the documents with real requirements.

Or use the CLI directly:

```bash
anchors install --agent claude              # one-time: install skill in repo
anchors setup ./payments --prefix PAY       # per-module: scaffold doc skeletons
```

## Usage

### With the skill (LLM-powered)

```
/anchors setup           # Scaffold + research + populate documents
/anchors setup path/to   # Set up in a specific directory
/anchors check           # Structural lint + semantic analysis
/anchors embed           # Convert detached module to embedded
/anchors                 # Interactive — choose setup, check, or embed
```

### With the CLI (deterministic, CI-friendly)

```bash
anchors install                       # One-time: install skill + agent instructions
anchors setup ./dir --prefix PREFIX   # Per-module: scaffold doc skeletons
anchors check                         # Structural lint across all modules
anchors upgrade                       # Update skill files to latest version
```

### Setup

Creates five files in the target directory:

| File | Purpose |
|------|---------|
| `ANCHORS.md` | Module marker with `prefix` in frontmatter |
| `PRODUCT.md` | Product requirements (source of truth) |
| `ERD.md` | Engineering requirements (derived from PRD) |
| `TESTING.md` | Testing strategy — pyramid, invariants, tooling |
| `DEPENDENCIES.md` | External dependencies |

The CLI creates the skeleton. The skill populates it with real content.

### Check

Checks traceability across all modules in the repo:

- Every `E-*` requirement has a `←` backlink to a `P-*` requirement
- Every `P-*` requirement is covered by at least one `E-*`
- Requirement IDs in code and tests are tracked
- Stale code references to removed requirements are flagged
- Cross-module references resolve to real files and anchors
- Unresolved `OPEN-*` questions are listed

The CLI performs structural checks (deterministic). The skill adds semantic analysis on top.

## How it works

ANCHORS defines a truth hierarchy:

```
PRODUCT.md        ← source of truth (what)
  → ERD.md        ← technical design (how), must satisfy PRD
    → Tests       ← executable spec, truthier than implementation
      → Code      ← must satisfy everything above
```

When things disagree, higher-authority documents win. Every `E-*` requirement links back to the `P-*` it satisfies. The check verifies these links are complete and consistent.

## Embedded vs detached mode

ANCHORS operates in two modes:

**Embedded** (default) — docs live in the same repo as the code. Requirement IDs are tagged inline in source and test files. Setup researches the local codebase. Check searches local code for traceability. This is what you use when you own the repo.

**Detached** — docs live separately from the code they describe. `ANCHORS.md` frontmatter includes `mode: detached`, and ERD.md uses `→` forward references to trace requirements to code locations in the target. The target code is never modified. Detached mode works both within the same repo (in-repo) and across repos (external).

### When to use detached mode

- **Keeping requirements separate from code in a monorepo.** Put anchors docs in a dedicated subdirectory (e.g., `apps/penpal/anchors/`) pointing at sibling code. You get structured traceability without littering the codebase with inline tags.
- **Understanding a codebase you don't own.** Create a docs repo, run `/anchors setup`, point it at the target. You get structured requirements docs with `→` refs to specific files and symbols — a navigable map organized by functional area.
- **Developing against code you can't modify.** Your docs describe the contract you depend on, pinned to a specific ref. Bump the ref and re-check to detect breaking changes.
- **Documenting a third-party service or library.** Track what you depend on and where, without forking or modifying anything.

### Detached mode setup

During `/anchors setup`, if the target directory has no code, the skill asks whether you're describing code elsewhere in the repo or in an external repo.

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

Check resolves the target (locally for in-repo, clone/fetch for external) and verifies each `→` ref — the file exists and the symbol is findable. Broken refs show up in the check report.

### Converting to embedded mode

If you find detached docs useful and want to fully adopt ANCHORS in the codebase, run `/anchors embed`. This:

1. Reads the `→` forward references from ERD.md
2. Adds inline requirement tags to the source files at each referenced location
3. Removes the `→` lines from ERD.md
4. Removes `mode`/`repo`/`ref`/`path` from ANCHORS.md, switching to embedded mode

The code must be locally accessible (already local for in-repo; for external, you must have a local clone). After embedding, `/anchors check` searches local code for inline tags like any embedded module.

## Monorepo support

Any directory with an `ANCHORS.md` file is a module. Modules can nest arbitrarily and cross-reference each other with relative paths. Each module declares a unique prefix (e.g., `AUTH`, `PAY`) that scopes its requirement IDs.

## Agent support

The CLI installs the skill to the appropriate project-level location:

| Agent | Skill location |
|-------|---------------|
| Claude Code | `.claude/skills/anchors/` |
| [Goose](https://github.com/block/goose) | `.goose/skills/anchors/` |
| Amp | `.agents/skills/anchors/` |
| Codex | `.agents/skills/anchors/` |
| [ai-rules](https://github.com/block/ai-rules) | `ai-rules/skills/anchors/` |

For **ai-rules**, the CLI also creates a rule file and runs `ai-rules generate`. This requires the `ai-rules` CLI and an existing `ai-rules/` directory in your project (`ai-rules init`).
