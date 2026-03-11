---
scope: Automated testing strategy — test pyramid, tooling, and coverage targets.
see-also:
  - PRODUCT.md — product requirements that define acceptance criteria.
  - ERD.md — technical requirements and interfaces under test.
---

# ANCHORS: Testing Strategy

## Source of Truth Hierarchy

- **SKILL.md is the implementation.** ANCHORS has no compiled code — the LLM interprets `SKILL.md` at runtime. This means "the implementation" is the skill definition, and "tests" are audits of its behavior applied to sample repos.
- **PRODUCT.md and ERD.md are truthier than observed behavior.** If the skill does something that contradicts the documents, the skill instructions need fixing.
- **The audit is self-testing.** The audit workflow verifies document consistency — running `/anchors audit` on the ANCHORS repo itself is a form of integration test.

---

## How We Test an LLM Skill

ANCHORS can't be tested like normal software. The "implementation" is a markdown file that an LLM interprets at runtime — there's no function to call, no binary to execute. We can't invoke the skill in tests without spinning up a Claude session, which would be slow, expensive, and non-deterministic.

Instead, we test what we *can* verify statically:

1. **Are the instructions complete?** We grep SKILL.md for every algorithm, rule, and format the ERD requires. If the ERD says "5 disagreement rules," we verify SKILL.md contains all 5. This catches drift between requirements and instructions.

2. **Do the document formats work?** We build fixture repos with known states — complete modules, deliberate gaps, broken cross-refs — and run the audit *logic* (as shell scripts) against them. This validates that the formats are parseable and the audit rules are coherent.

3. **Is the repo self-consistent?** We run structural checks against the ANCHORS repo's own documents: backlinks resolve, PRD coverage is complete, frontmatter is valid.

The shell tests validate properties of the documents and instructions. They don't replace the full `/anchors audit` (which requires an LLM to execute), but they catch the bugs that matter most: missing rules, stale instructions, format mismatches, and fixture correctness.

---

## Coverage Invariants

### Invariant 1: Every product and engineering requirement has a test

Every P-* and E-* requirement must be verifiable. For a skill with no compiled code, "test" means: a scenario that can be manually or automatically exercised to confirm the behavior.

### Invariant 2: Contract boundaries are tested from both sides

ANCHORS has two contract boundaries:

| Boundary | Reading side | Writing side |
|----------|-------------|-------------|
| **Document format** (YAML frontmatter, anchor IDs, backlinks) | Audit parses documents | Init writes documents from templates |
| **File system** (directory structure, ANCHORS.md discovery) | Audit globs and reads | Init creates files in target directories |

### Invariant 3: Trust boundaries are tested end-to-end

ANCHORS has one trust boundary: it modifies the user's file system (creating files, appending to `AGENTS.md`/`CLAUDE.md`). Every write operation is gated by `AskUserQuestion` confirmation. Both the "confirmed" and "declined" paths must be exercisable.

### Invariant 4: Every public API surface has a test

The public API is the `/anchors` command with its three modes: interactive, init, audit. Each mode has happy-path and error-path scenarios.

### Invariant 5: Recovery paths are tested

If init encounters existing files or audit encounters malformed documents, the skill must degrade gracefully (report issues, not crash). These paths are tested via malformed fixture repos.

### Invariant 6: Every interface has its production implementation verified

The production implementation is `SKILL.md` executed by Claude Code. Template files in `templates/` are the other production artifact. Both are verified by running the skill against fixture repos.

---

## Coverage Mapping: Requirements to Test Layers

| Functional Area | Primary Layer | Secondary Layer |
|-----------------|---------------|-----------------|
| **Document format** (P-ANCHORS-DOC-SET, E-ANCHORS-*-FORMAT) | Unit (template validation) | Integration (fixture format checks) |
| **Truth hierarchy** (P-ANCHORS-TRUTH-HIERARCHY, P-ANCHORS-DISAGREEMENT) | Static (verify SKILL.md contains all rules) | Self-audit (audit the ANCHORS repo itself) |
| **Init workflow** (P-ANCHORS-INIT-*) | Static (verify SKILL.md describes all steps) | E2E (full init in empty repo, manual) |
| **Audit workflow** (P-ANCHORS-AUDIT-*) | Integration (audit logic on fixtures) | E2E (full `/anchors audit`, manual) |
| **Monorepo support** (P-ANCHORS-MONO-*) | Integration (multi-module fixture repo) | E2E (audit with cross-module refs) |
| **Routing** (P-ANCHORS-ROUTE-*) | Static (verify SKILL.md routing table) | E2E (interactive prompts, manual) |
| **Installer** (P-ANCHORS-INSTALL-*) | Unit (install.sh syntax, structure) | Integration (target dir resolution, ai-rules prereq checks) |

---

## Pyramid Shape

ANCHORS is unusual: it's a skill definition (instructions) plus templates, not compiled code. The test pyramid is inverted from typical software — integration tests carry most of the weight because the "unit" under test is an LLM following instructions.

```
                    ┌─────────┐
                    │  E2E    │   Full /anchors invocations (manual, LLM-driven)
                    │         │
                ┌───┴─────────┴───┐
                │  Integration    │   Fixture-based structural checks
                │  (primary)      │   Self-audit, code traceability
        ┌───────┴─────────────────┴───────┐
        │         Unit / Static           │   Template syntax checks
        │  (frontmatter, placeholder IDs) │   SKILL.md completeness
        └─────────────────────────────────┘
```

---

## Layer 1: Unit / Static Validation

### 1.1 Template Integrity (`test_template_integrity.sh`)

| Test Area | What to Test |
|-----------|-------------|
| **Frontmatter** | Every template has valid YAML frontmatter with `scope` and `see-also` fields |
| **Placeholders** | Every template contains `[Project Name]` placeholder and no other unresolved placeholders |
| **Anchor examples** | Example anchors in templates use the documented format (`<a id="..."></a>**...**:`) |
| **No stale IDs** | Templates don't contain requirement IDs that look real (only example/placeholder IDs) |

### 1.2 SKILL.md Consistency (`test_skill_consistency.sh`)

| Test Area | What to Test |
|-----------|-------------|
| **Mode table** | The routing table in SKILL.md matches the documented modes in PRODUCT.md |
| **Template paths** | Template paths referenced in SKILL.md match actual files in `templates/` |
| **Report format** | The example audit report in SKILL.md includes all gap categories from E-ANCHORS-AUDIT-REPORT-FORMAT |

### 1.3 SKILL.md Algorithm Completeness (`test_skill_algorithms.sh`)

| Test Area | What to Test |
|-----------|-------------|
| **Truth hierarchy** | SKILL.md documents the full hierarchy order (E-ANCHORS-HIERARCHY-ORDER) |
| **Disagreement rules** | All 5 disagreement resolution rules present (E-ANCHORS-DISAGREE-RULES) |
| **Code tag format** | Tag format, one-per-function rule, augment-not-replace (E-ANCHORS-CODE-TAG-FORMAT) |
| **Init path resolution** | 3-step algorithm: explicit path, clean CWD, occupied CWD (E-ANCHORS-INIT-PATH-RESOLUTION) |
| **Init conflict check** | Skip/overwrite options for existing files (E-ANCHORS-INIT-CONFLICT-CHECK) |
| **Init agent instructions** | AGENTS.md/CLAUDE.md logic with symlink handling (E-ANCHORS-INIT-CLAUDE-MD-APPEND) |
| **Init defaults** | Directory name as default project name and prefix (E-ANCHORS-INIT-DEFAULTS) |
| **Audit glob exclusions** | node_modules, vendor, .git excluded from discovery (E-ANCHORS-AUDIT-GLOB) |
| **Route recommendation** | Audit recommended when modules exist, init when none (E-ANCHORS-ROUTE-RECOMMEND) |

### 1.4 Document Format Validation (`test_document_format.sh`)

| Test Area | What to Test |
|-----------|-------------|
| **Document locations** | Documents are siblings of ANCHORS.md in fixture (E-ANCHORS-DOC-LOCATIONS) |
| **P-ID format** | `<a id="P-..."></a>**P-...**:` pattern in fixtures and templates (E-ANCHORS-P-ID-FORMAT) |
| **E-ID format** | Same anchor pattern plus ← backlink within 2 lines (E-ANCHORS-E-ID-FORMAT) |
| **D-DEP format** | Section header `### D-DEP-*` with Used by/Where/Why fields (E-ANCHORS-DEP-ID-FORMAT) |

---

## Layer 2: Integration Tests (Fixture Repos)

### 2.1 Init on Clean Directory

**Setup:** Empty temp directory, no existing ANCHORS files.

| Test Area | What to Test |
|-----------|-------------|
| **File creation** | All 5 files created (ANCHORS.md + 4 documents) |
| **Prefix in frontmatter** | ANCHORS.md contains the chosen prefix |
| **Name substitution** | `[Project Name]` replaced in all templates |
| **Agent instructions append** | ANCHORS section appended to repo-root `AGENTS.md`/`CLAUDE.md` (handles symlinks, both files, or creates `AGENTS.md`) |

*Note: Init tests describe expected behavior but cannot be run automatically — they require an LLM session to execute `/anchors init`.*

### 2.2 Init with Existing Files

**Setup:** Directory with some ANCHORS files already present.

| Test Area | What to Test |
|-----------|-------------|
| **Skip existing** | Only missing files created, existing files untouched |
| **Overwrite all** | All files replaced with fresh templates |
| **Prefix collision** | Duplicate prefix across modules is rejected |

### 2.3 Audit on Well-Formed Repo (`test_fixture_complete.sh`)

**Setup:** `testdata/fixtures/complete-module/` — a module with all 4 documents, 3 P-* requirements, 3 E-* requirements with full backlinks, D-DEP entries, plus source and test files with traceability tags.

| Test Area | What to Test |
|-----------|-------------|
| **Module discovery** | All modules found, prefixes extracted |
| **Backlink coverage** | 100% E-* → P-* backlinks detected |
| **PRD coverage** | All P-* covered by E-* detected |
| **Code traceability** | Requirement refs in code and tests correctly classified |
| **Report completeness** | Report includes all sections with correct counts |

### 2.4 Audit on Repo with Gaps (`test_fixture_gaps.sh`)

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
| **Valid cross-ref** | Relative path resolves, anchor exists — no error (E-ANCHORS-AUDIT-CROSS-RESOLVE) |
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
| **Code search** | Requirement IDs found in source files (E-ANCHORS-AUDIT-CODE-SEARCH) |
| **File classification** | Source vs test files distinguished by path convention |
| **Stale refs** | Code refs to IDs not in any document detected (E-ANCHORS-AUDIT-STALE-REFS) |
| **Test gaps** | Requirements in source but not test files detected (E-ANCHORS-AUDIT-TEST-GAP) |

### 2.8 Self-Audit (`test_self_audit.sh`)

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

### 2.9 Installer (`test_installer.sh`)

**Setup:** The `install.sh` script.

| Test Area | What to Test |
|-----------|-------------|
| **Script syntax** | `install.sh` passes `bash -n` syntax check |
| **Agent menu** | All four agent options present: Claude Code, Amp, Codex, ai-rules (E-ANCHORS-INSTALL-AGENT-MENU) |
| **Scope menu** | User-level and project-level options present (E-ANCHORS-INSTALL-SCOPE-MENU) |
| **Target directories** | All six agent-scope combinations resolve to documented paths (E-ANCHORS-INSTALL-TARGET-DIRS) |
| **ai-rules target** | ai-rules path is `ai-rules/skills/anchors/` (E-ANCHORS-INSTALL-AIRULES-PATH) |
| **ai-rules CLI check** | Installer checks for `ai-rules` command via `command -v` (E-ANCHORS-INSTALL-AIRULES-CHECKS) |
| **ai-rules dir check** | Installer checks for `ai-rules/` directory existence (E-ANCHORS-INSTALL-AIRULES-CHECKS) |
| **ai-rules generate** | Installer runs `ai-rules generate` after copying skill (E-ANCHORS-INSTALL-AIRULES-PATH) |
| **Agent instructions (direct)** | Project-level installs append ANCHORS section to `AGENTS.md`/`CLAUDE.md` with symlink handling, skip if already present (E-ANCHORS-INSTALL-INSTRUCTIONS-DIRECT) |
| **Agent instructions (ai-rules)** | ai-rules installs create `ai-rules/anchors.md` rule file, skip if already exists (E-ANCHORS-INSTALL-INSTRUCTIONS-AIRULES) |
| **Idempotent append** | Re-running installer does not duplicate the ANCHORS section |

---

## Layer 3: E2E Tests

These require running the actual `/anchors` skill in a Claude Code session. They are manual — the shell test suite cannot invoke the LLM.

| Test | Scenario |
|------|----------|
| **Fresh repo init** | `/anchors init` in a new repo → documents created, `AGENTS.md` created with ANCHORS section, `/anchors audit` passes with informational gaps only |
| **Self-audit** | `/anchors audit` run on the anchors-md repo itself → report generated, gaps match known state |
| **Multi-module lifecycle** | Init module A, init module B, add cross-refs, audit → both modules discovered, cross-refs validated |

---

## Test Infrastructure

### Test Runner

`test/run.sh` — runs all `test/test_*.sh` files, reports pass/fail counts. Each test file sources `test/helpers.sh` for assertion utilities (`assert_grep`, `assert_eq`, `assert_file_exists`, etc.). The full suite runs in under a second.

```
test/run.sh                        # Runner — executes all test_*.sh
test/helpers.sh                    # Assertion library
test/test_template_integrity.sh    # Layer 1: template format
test/test_skill_consistency.sh     # Layer 1: SKILL.md structure
test/test_skill_algorithms.sh      # Layer 1: SKILL.md algorithm completeness
test/test_document_format.sh       # Layer 1/2: ID format validation
test/test_fixture_complete.sh      # Layer 2: well-formed module
test/test_fixture_gaps.sh          # Layer 2: gap detection
test/test_fixture_multi_module.sh  # Layer 2: cross-module refs
test/test_fixture_prefix_collision.sh  # Layer 2: prefix collision
test/test_code_traceability.sh     # Layer 2: code/test tag detection
test/test_self_audit.sh            # Layer 2/3: self-consistency
```

### Fixture Repos

```
testdata/
  fixtures/
    complete-module/          # Well-formed single module (4 docs + src + test)
    gaps-module/              # Module with deliberate traceability gaps
    multi-module/             # Two modules with cross-references
    broken-cross-refs/        # Multi-module with broken relative paths
```

Each fixture is a minimal directory tree with ANCHORS documents and (where needed) source/test files containing traceability tags. Tests are read-only — they never modify fixtures. The one exception (`test_fixture_prefix_collision.sh`) creates a temp dir and cleans it up with a trap.

### Self-Audit as Smoke Test

Running `/anchors audit` on this repository is the primary smoke test. The audit report should be reviewed after any change to SKILL.md, templates, or the ANCHORS documents themselves.

---

## Tooling

| Tool | Purpose |
|------|---------|
| `test/run.sh` | Automated test suite — static checks, fixture validation, self-audit |
| `/anchors audit` | Full LLM-driven audit — the E2E smoke test (manual) |

---

## Coverage Targets

| Layer | Target | Rationale |
|-------|--------|-----------|
| Unit/Static | 100% of templates, 100% of ERD algorithm requirements | Templates are the only static artifacts; SKILL.md must contain every required algorithm |
| Integration | 100% of audit gap categories | Every type of gap the audit can report must have a fixture that triggers it |
| E2E | All 3 modes exercised | Interactive, init, and audit must each be run at least once (manual) |

---

## What We Deliberately Don't Test

- **LLM instruction-following fidelity:** We test that the instructions are correct and complete, not that the LLM follows them perfectly every time. That's a property of the runtime, not the skill.
- **Claude Code internals:** We don't test `AskUserQuestion`, `Write`, `Glob`, or other Claude Code tools. We assume they work as documented.
- **Markdown rendering:** We don't test how documents render in various viewers. We test that the markdown structure is correct.
- **Performance:** ANCHORS operates on small document sets. There are no performance-sensitive paths.
- **Init execution:** The init workflow requires LLM interaction (AskUserQuestion prompts, file writes). We verify SKILL.md describes all init steps correctly but cannot execute them in the automated suite.
