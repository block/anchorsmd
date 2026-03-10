# ANCHORS

Requirements-driven development for AI agents.

ANCHORS keeps product requirements, engineering requirements, testing strategy, and implementation in a consistent, traceable hierarchy — plain markdown files, no build tooling. It gives agents a structured context for understanding what to build, how to build it, and how to verify it.

The framework is agent-agnostic: the documents are plain markdown that any agent can read. The `/anchors` skill automates scaffolding and auditing for [Claude Code](https://docs.anthropic.com/en/docs/claude-code), but the documents work without it.

## Install (Claude Code)

```bash
./install.sh
```

This symlinks `skill/` to `~/.claude/skills/anchors/` so the skill stays in sync with the repo.

## Usage

With the Claude Code skill installed:

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

## Repo structure

```
skill/
  SKILL.md              # The skill definition (Claude Code skill)
  templates/            # Document templates used by /anchors init
install.sh              # Symlinks skill/ into ~/.claude/skills/
test/
  run.sh                # Test runner
  helpers.sh            # Assertion library
  test_*.sh             # Test suite (10 files, ~290 assertions)
testdata/
  fixtures/             # Fixture repos for testing
PRODUCT.md              # ANCHORS' own product requirements
ERD.md                  # ANCHORS' own engineering requirements
TESTING.md              # ANCHORS' own testing strategy
```

## Testing

```bash
./test/run.sh
```

The test suite validates that the skill definition is complete and consistent — it checks SKILL.md contains every required algorithm, verifies document formats against fixtures, and runs structural checks on the repo's own ANCHORS documents. See [TESTING.md](TESTING.md) for the full strategy.

## Monorepo support

Any directory with an `ANCHORS.md` file is a module. Modules can nest arbitrarily and cross-reference each other with relative paths. Each module declares a unique prefix (e.g., `AUTH`, `PAY`) that scopes its requirement IDs.
