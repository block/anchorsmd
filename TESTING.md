---
scope: Automated testing strategy — test pyramid, tooling, and coverage targets.
see-also:
  - PRODUCT.md — product requirements that define acceptance criteria.
  - ERD.md — technical requirements and interfaces under test.
---

# ANCHORS: Testing Strategy

## Source of Truth Hierarchy

- **The CLI and SKILL.md are the implementation.** The `anchors` CLI handles deterministic operations (scaffolding, structural linting). The LLM interprets `SKILL.md` at runtime for research, population, and semantic analysis.
- **PRODUCT.md and ERD.md are truthier than observed behavior.** If the CLI or skill does something that contradicts the documents, the implementation needs fixing.
- **The check is self-testing.** The check workflow verifies document consistency — running `anchors check` and `/anchors check` on the ANCHORS repo itself is a form of integration test.

---

## How We Test

ANCHORS has two testable components:

1. **The `anchors` CLI** — a bash script with subcommands (`setup`, `check`, `upgrade`). This is deterministic and can be tested with standard shell test techniques: invoke the command, check output and exit codes, verify created files.

2. **SKILL.md** — a markdown file that an LLM interprets at runtime. We can't invoke the skill in tests without spinning up a Claude session, so we verify that the instructions are complete and consistent with the requirements.

We test what we *can* verify:

1. **Does the CLI work correctly?** We invoke `anchors setup`, `anchors check`, and `anchors upgrade` against temp directories and fixture repos, verifying outputs, exit codes, and file creation.

2. **Are the skill instructions complete?** We grep SKILL.md for every algorithm, rule, and format the ERD requires. If the ERD says "5 disagreement rules," we verify SKILL.md contains all 5.

3. **Do the document formats work?** We build fixture repos with known states — complete modules, deliberate gaps, broken cross-refs — and run `anchors check` against them.

4. **Is the repo self-consistent?** We run structural checks against the ANCHORS repo's own documents: backlinks resolve, PRD coverage is complete, frontmatter is valid.

---

## Coverage Invariants

### Invariant 1: Every product and engineering requirement has a test

Every P-* and E-* requirement must be verifiable. For the CLI, this means automated tests. For the skill, this means static verification of SKILL.md completeness plus manual E2E testing.

### Invariant 2: Contract boundaries are tested from both sides

ANCHORS has two contract boundaries:

| Boundary | Reading side | Writing side |
|----------|-------------|-------------|
| **Document format** (YAML frontmatter, anchor IDs, backlinks) | `anchors check` parses documents | `anchors setup` creates document skeletons; skill populates content |
| **File system** (directory structure, ANCHORS.md discovery) | `anchors check` globs and reads | `anchors setup` creates files in target directories |

### Invariant 3: Trust boundaries are tested end-to-end

ANCHORS has one trust boundary: it modifies the user's file system (creating files, appending to `AGENTS.md`/`CLAUDE.md`). CLI operations are invoked explicitly. Skill write operations are gated by `AskUserQuestion` confirmation.

### Invariant 4: Every public API surface has a test

The public API has two layers: the CLI (`anchors setup`, `anchors check`, `anchors upgrade`) and the skill (`/anchors setup`, `/anchors check`, `/anchors embed`). CLI subcommands are tested automatically. Skill modes are tested manually.

### Invariant 5: Recovery paths are tested

If setup encounters existing files or check encounters malformed documents, both the CLI and skill must degrade gracefully. These paths are tested via fixtures and temp directories.

### Invariant 6: Every interface has its production implementation verified

The production implementation is the `anchors` CLI script and `SKILL.md` executed by Claude Code. Template files in `templates/` are the other production artifact. All are verified by the test suite.

---

## Pyramid Shape

ANCHORS has both a CLI (testable deterministically) and a skill (requires LLM). The pyramid reflects this dual nature — CLI tests are automated, skill tests are static verification plus manual E2E.

```
                    ┌─────────┐
                    │  E2E    │   Full /anchors invocations (manual, LLM-driven)
                    │         │
                ┌───┴─────────┴───┐
                │  Integration    │   CLI subcommand tests, fixture-based checks
                │  (primary)      │   Self-check, code traceability
        ┌───────┴─────────────────┴───────┐
        │         Unit / Static           │   Template syntax checks
        │  (frontmatter, placeholder IDs) │   SKILL.md completeness
        └─────────────────────────────────┘
```

---

## Layer 1: Unit / Static Validation

### 1.1 SKILL.md Consistency (`test_skill_consistency.sh`)

| Test Area | What to Test |
|-----------|-------------|
| **Mode table** | The routing table in SKILL.md matches the documented modes in PRODUCT.md |
| **Report format** | The example check report in SKILL.md includes all gap categories from E-ANCHORS-CHECK-REPORT-FORMAT |

### 1.2 SKILL.md Algorithm Completeness (`test_skill_algorithms.sh`)

| Test Area | What to Test |
|-----------|-------------|
| **Truth hierarchy** | SKILL.md documents the full hierarchy order (E-ANCHORS-HIERARCHY-ORDER) |
| **Disagreement rules** | All 5 disagreement resolution rules present (E-ANCHORS-DISAGREE-RULES) |
| **Code tag format** | Tag format, one-per-function rule, augment-not-replace (E-ANCHORS-CODE-TAG-FORMAT) |
| **Setup path resolution** | 3-step algorithm: explicit path, clean CWD, occupied CWD (E-ANCHORS-SETUP-PATH-RESOLUTION) |
| **Setup conflict check** | Skip/overwrite options for existing files (E-ANCHORS-SETUP-CONFLICT-CHECK) |
| **Setup agent instructions** | AGENTS.md/CLAUDE.md logic with symlink handling (E-ANCHORS-SETUP-AGENT-INSTRUCTIONS) |
| **Setup defaults** | Directory name as default project name and prefix (E-ANCHORS-SETUP-DEFAULTS) |
| **Check glob exclusions** | node_modules, vendor, .git excluded from discovery (E-ANCHORS-CHECK-GLOB) |
| **Route recommendation** | Check recommended when modules exist, setup when none (E-ANCHORS-ROUTE-RECOMMEND) |

### 1.3 Document Format Validation (`test_document_format.sh`)

| Test Area | What to Test |
|-----------|-------------|
| **Document locations** | Documents are siblings of ANCHORS.md in fixture (E-ANCHORS-DOC-LOCATIONS) |
| **P-ID format** | `<a id="P-..."></a>**P-...**:` pattern in fixtures and templates (E-ANCHORS-P-ID-FORMAT) |
| **E-ID format** | Same anchor pattern plus ← backlink within 2 lines (E-ANCHORS-E-ID-FORMAT) |
| **D-DEP format** | Section header `### D-DEP-*` with Used by/Where/Why fields (E-ANCHORS-DEP-ID-FORMAT) |

---

## Layer 2: Integration Tests (Fixture Repos)

### 2.1 CLI Setup (`test_cli.sh`)

**Setup:** Temp directories for testing CLI subcommands.

| Test Area | What to Test |
|-----------|-------------|
| **Script syntax** | `anchors` passes `bash -n` syntax check |
| **Setup creates files** | `anchors setup` creates all 5 skeleton files |
| **Prefix in frontmatter** | Created ANCHORS.md contains the --prefix value |
| **Detached mode frontmatter** | `--mode detached` produces correct frontmatter fields |
| **Skip existing** | `--skip-existing` preserves existing files |
| **Prefix collision** | Duplicate prefix rejected with error |
| **Agent detection** | Correct skill target dirs for claude, amp, codex, airules |
| **Agent instructions** | ANCHORS section appended to AGENTS.md/CLAUDE.md with symlink handling |
| **ai-rules checks** | ai-rules prerequisites validated (command, directory) |
| **Check subcommand** | `anchors check` outputs structured report |
| **Check exit codes** | Clean module → 0, errors → 1 |
| **Upgrade subcommand** | `anchors upgrade` replaces skill files |
| **Usage** | No args or unknown command prints usage |

### 2.2 Setup with Existing Files

**Setup:** Directory with some ANCHORS files already present.

| Test Area | What to Test |
|-----------|-------------|
| **Skip existing** | Only missing files created, existing files untouched |
| **Overwrite all** | All files replaced with fresh skeletons |
| **Prefix collision** | Duplicate prefix across modules is rejected |

### 2.3 Check on Well-Formed Repo (`test_fixture_complete.sh`)

**Setup:** `testdata/fixtures/complete-module/` — a module with all 4 documents, 3 P-* requirements, 3 E-* requirements with full backlinks, D-DEP entries, plus source and test files with traceability tags.

| Test Area | What to Test |
|-----------|-------------|
| **Module discovery** | All modules found, prefixes extracted |
| **Backlink coverage** | 100% E-* → P-* backlinks detected |
| **PRD coverage** | All P-* covered by E-* detected |
| **Code traceability** | Requirement refs in code and tests correctly classified |
| **Report completeness** | Report includes all sections with correct counts |

### 2.4 Check on Repo with Gaps (`test_fixture_gaps.sh`)

**Setup:** `testdata/fixtures/gaps-module/` — a module with deliberate gaps: E-PAY-IDEMPOTENT has no backlink, P-PAY-CART and P-PAY-RECEIPT have no E-* coverage, `OPEN-REFUND-FLOW` is unresolved, TESTING.md and DEPENDENCIES.md are absent.

| Test Area | What to Test |
|-----------|-------------|
| **Missing backlinks** | E-* without ← reported |
| **Uncovered PRD** | P-* with no E-* coverage reported |
| **Open questions** | OPEN-* items listed |
| **Missing documents** | Absent TESTING.md and DEPENDENCIES.md detected |

### 2.5 Cross-Module References (`test_fixture_multi_module.sh`)

**Setup:** `testdata/fixtures/multi-module/` (valid refs) and `testdata/fixtures/broken-cross-refs/` (broken refs). Two modules with cross-module backlinks using relative paths.

| Test Area | What to Test |
|-----------|-------------|
| **Valid cross-ref** | Relative path resolves, anchor exists — no error (E-ANCHORS-CHECK-CROSS-RESOLVE) |
| **Broken path** | Relative path to nonexistent file — reported |
| **Broken anchor** | File exists but anchor ID missing — reported |
| **Relative path format** | Cross-module refs use `← [P-*](../module/PRODUCT.md#P-*)` (E-ANCHORS-MONO-RELATIVE-PATHS) |
| **Partial modules** | Modules without all 4 documents are valid (E-ANCHORS-MONO-PARTIAL-MODULES) |

### 2.6 Prefix Collision (`test_fixture_prefix_collision.sh`)

**Setup:** Temp directory with two modules sharing prefix `DUPE`.

| Test Area | What to Test |
|-----------|-------------|
| **Collision detected** | Duplicate prefixes flagged |
| **Valid fixture clean** | Multi-module fixture has no collisions |

### 2.7 Code Traceability (`test_code_traceability.sh`)

**Setup:** `testdata/fixtures/complete-module/src/` and `test/` — Go source files with requirement ID tags, including a deliberate stale reference (E-AUTH-OLD-THING) and a test gap (E-AUTH-JWT in source but not tests).

| Test Area | What to Test |
|-----------|-------------|
| **Code search** | Requirement IDs found in source files (E-ANCHORS-CHECK-CODE-SEARCH) |
| **File classification** | Source vs test files distinguished by path convention |
| **Stale refs** | Code refs to IDs not in any document detected (E-ANCHORS-CHECK-STALE-REFS) |
| **Test gaps** | Requirements in source but not test files detected (E-ANCHORS-CHECK-TEST-GAP) |

### 2.8 Self-Check (`test_self_audit.sh`)

**Setup:** The ANCHORS repo's own documents.

| Test Area | What to Test |
|-----------|-------------|
| **Marker format** | ANCHORS.md has prefix field |
| **Document presence** | PRODUCT.md, ERD.md, TESTING.md exist |
| **ID extraction** | All P-* and E-* IDs found with HTML anchors |
| **Backlinks** | Every E-* has ← backlink to P-* |
| **PRD coverage** | Every P-* referenced by at least one E-* |
| **Open questions** | No unresolved OPEN-* items |
| **Frontmatter** | All documents have scope and see-also fields |

### 2.9 Detached Mode (`test_detached_mode.sh`)

**Setup:** `testdata/fixtures/detached-module/` — a module with `repo` field in ANCHORS.md frontmatter, ERD.md containing `→` forward references, and a cloned target snapshot under `testdata/fixtures/detached-target/` simulating the target repo.

| Test Area | What to Test |
|-----------|-------------|
| **Mode detection** | ANCHORS.md with `repo` field detected as detached mode; without `repo` detected as embedded (E-ANCHORS-DETACHED-MODE-DETECTION) |
| **Frontmatter schema** | `repo`, `ref`, `path` fields parsed from ANCHORS.md frontmatter (E-ANCHORS-DETACHED-FRONTMATTER) |
| **Forward ref format** | `→` references use backtick-wrapped `file:symbol` format, comma-separated (E-ANCHORS-DETACHED-FORWARD-REF-FORMAT) |
| **Forward ref validation** | Valid refs resolve against target fixture; broken refs (missing file, missing symbol) reported (E-ANCHORS-DETACHED-FORWARD-REF-VALIDATION) |
| **No inline tag search** | Check in detached mode does not search target code for `P-*`/`E-*` inline tags (E-ANCHORS-DETACHED-NO-INLINE-TAGS) |
| **Doc consistency** | Backlinks, PRD coverage, and other doc-internal checks work the same in detached mode |
| **Embed prereq** | Embed action rejected on embedded modules (no `repo` field) (E-ANCHORS-EMBED-PREREQ) |
| **Embed strips forward refs** | After embed, ERD.md has no `→` lines; `←` backlinks preserved (E-ANCHORS-EMBED-STRIP-FORWARD-REFS) |
| **Embed strips frontmatter** | After embed, ANCHORS.md has only `prefix`, no `repo`/`ref`/`path` (E-ANCHORS-EMBED-STRIP-FRONTMATTER) |

---

## Layer 3: E2E Tests

These require running the actual `/anchors` skill in a Claude Code session. They are manual — the shell test suite cannot invoke the LLM.

| Test | Scenario |
|------|----------|
| **Fresh repo setup** | `/anchors setup` in a new repo → documents created and populated, `AGENTS.md` created with ANCHORS section, `/anchors check` passes with informational gaps only |
| **Self-check** | `/anchors check` run on the anchors-md repo itself → report generated, gaps match known state |
| **Multi-module lifecycle** | Setup module A, setup module B, add cross-refs, check → both modules discovered, cross-refs validated |

---

## Test Infrastructure

### Test Runner

`test/run.sh` — runs all `test/test_*.sh` files, reports pass/fail counts. Each test file sources `test/helpers.sh` for assertion utilities (`assert_grep`, `assert_eq`, `assert_file_exists`, etc.). The full suite runs in under a second.

```
test/run.sh                        # Runner — executes all test_*.sh
test/helpers.sh                    # Assertion library
test/test_skill_consistency.sh     # Layer 1: SKILL.md structure
test/test_skill_algorithms.sh      # Layer 1: SKILL.md algorithm completeness
test/test_document_format.sh       # Layer 1/2: ID format validation
test/test_fixture_complete.sh      # Layer 2: well-formed module
test/test_fixture_gaps.sh          # Layer 2: gap detection
test/test_fixture_multi_module.sh  # Layer 2: cross-module refs
test/test_fixture_prefix_collision.sh  # Layer 2: prefix collision
test/test_code_traceability.sh     # Layer 2: code/test tag detection
test/test_detached_mode.sh         # Layer 2: detached mode detection, forward refs
test/test_self_audit.sh            # Layer 2/3: self-consistency
test/test_cli.sh                   # Layer 2: CLI subcommand tests
```

### Fixture Repos

```
testdata/
  fixtures/
    complete-module/          # Well-formed single module (4 docs + src + test)
    gaps-module/              # Module with deliberate traceability gaps
    multi-module/             # Two modules with cross-references
    broken-cross-refs/        # Multi-module with broken relative paths
    detached-module/          # Detached mode module with forward refs
    detached-target/          # Simulated target repo for detached mode tests
```

Each fixture is a minimal directory tree with ANCHORS documents and (where needed) source/test files containing traceability tags. Tests are read-only — they never modify fixtures. The one exception (`test_fixture_prefix_collision.sh`) creates a temp dir and cleans it up with a trap.

### Self-Check as Smoke Test

Running `anchors check` on this repository is the primary structural smoke test. Running `/anchors check` adds semantic analysis on top. Both should be reviewed after any change to the CLI, SKILL.md, templates, or the ANCHORS documents themselves.

---

## Tooling

| Tool | Purpose |
|------|---------|
| `test/run.sh` | Automated test suite — static checks, fixture validation, CLI tests, self-check |
| `anchors check` | CLI structural lint — runs without LLM, suitable for CI |
| `/anchors check` | Full LLM-driven check — structural + semantic analysis (manual) |

---

## Coverage Targets

| Layer | Target | Rationale |
|-------|--------|-----------|
| Unit/Static | 100% of ERD algorithm requirements | SKILL.md must contain every required algorithm |
| Integration | 100% of check gap categories, 100% of CLI subcommands | Every gap type must have a fixture; every CLI path must be exercised |
| E2E | All 3 modes exercised | Interactive, setup, and check must each be run at least once (manual) |

---

## What We Deliberately Don't Test

- **LLM instruction-following fidelity:** We test that the instructions are correct and complete, not that the LLM follows them perfectly every time. That's a property of the runtime, not the skill.
- **Claude Code internals:** We don't test `AskUserQuestion`, `Write`, `Glob`, or other Claude Code tools. We assume they work as documented.
- **Markdown rendering:** We don't test how documents render in various viewers. We test that the markdown structure is correct.
- **Performance:** ANCHORS operates on small document sets. There are no performance-sensitive paths.
- **Skill population quality:** The setup workflow's research and population steps require LLM interaction. We verify SKILL.md describes all steps correctly but cannot execute them in the automated suite.
