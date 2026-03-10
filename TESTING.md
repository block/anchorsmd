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
| **Document format** (P-ANCHORS-DOC-SET, E-ANCHORS-*-FORMAT) | Unit (template validation) | Integration (init + audit round-trip) |
| **Truth hierarchy** (P-ANCHORS-TRUTH-HIERARCHY, P-ANCHORS-DISAGREEMENT) | Specification (documented in SKILL.md) | Self-audit (audit the ANCHORS repo itself) |
| **Init workflow** (P-ANCHORS-INIT-*) | Integration (run init on fixture dirs) | E2E (full init in empty repo) |
| **Audit workflow** (P-ANCHORS-AUDIT-*) | Integration (run audit on fixture repos) | E2E (audit a real multi-module repo) |
| **Monorepo support** (P-ANCHORS-MONO-*) | Integration (multi-module fixture repo) | E2E (audit with cross-module refs) |
| **Routing** (P-ANCHORS-ROUTE-*) | Unit (argument parsing) | Integration (interactive prompts) |

---

## Pyramid Shape

ANCHORS is unusual: it's a skill definition (instructions) plus templates, not compiled code. The test pyramid is inverted from typical software — integration tests carry most of the weight because the "unit" under test is an LLM following instructions.

```
                    ┌─────────┐
                    │  E2E    │   Full /anchors invocations in real repos
                    │         │
                ┌───┴─────────┴───┐
                │  Integration    │   Init/audit on fixture repos
                │  (primary)      │   Template validation
        ┌───────┴─────────────────┴───────┐
        │         Unit / Static           │   Template syntax checks
        │  (frontmatter, placeholder IDs) │   SKILL.md consistency
        └─────────────────────────────────┘
```

---

## Layer 1: Unit / Static Validation

### 1.1 Template Integrity

| Test Area | What to Test |
|-----------|-------------|
| **Frontmatter** | Every template has valid YAML frontmatter with `scope` and `see-also` fields |
| **Placeholders** | Every template contains `[Project Name]` placeholder and no other unresolved placeholders |
| **Anchor examples** | Example anchors in templates use the documented format (`<a id="..."></a>**...**:`) |
| **No stale IDs** | Templates don't contain requirement IDs that look real (only example/placeholder IDs) |

### 1.2 SKILL.md Consistency

| Test Area | What to Test |
|-----------|-------------|
| **Mode table** | The routing table in SKILL.md matches the documented modes in PRODUCT.md |
| **Template paths** | Template paths referenced in SKILL.md match actual files in `templates/` |
| **Report format** | The example audit report in SKILL.md includes all gap categories from E-ANCHORS-AUDIT-REPORT-FORMAT |

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

### 2.2 Init with Existing Files

**Setup:** Directory with some ANCHORS files already present.

| Test Area | What to Test |
|-----------|-------------|
| **Skip existing** | Only missing files created, existing files untouched |
| **Overwrite all** | All files replaced with fresh templates |
| **Prefix collision** | Duplicate prefix across modules is rejected |

### 2.3 Audit on Well-Formed Repo

**Setup:** Fixture repo with complete ANCHORS module(s), code files with traceability tags, test files with requirement refs.

| Test Area | What to Test |
|-----------|-------------|
| **Module discovery** | All modules found, prefixes extracted |
| **Backlink coverage** | 100% E-* → P-* backlinks detected |
| **PRD coverage** | All P-* covered by E-* detected |
| **Code traceability** | Requirement refs in code and tests correctly classified |
| **Report completeness** | Report includes all sections with correct counts |

### 2.4 Audit on Repo with Gaps

**Setup:** Fixture repo with deliberate gaps — missing backlinks, orphan P-* requirements, stale code refs, missing test refs, open questions, prefix collisions.

| Test Area | What to Test |
|-----------|-------------|
| **Missing backlinks** | E-* without ← reported |
| **Uncovered PRD** | P-* with no E-* coverage reported |
| **Stale refs** | Code refs to nonexistent IDs reported |
| **Test gaps** | Requirements in code but not in tests reported |
| **Open questions** | OPEN-* items listed |
| **Prefix collision** | Duplicate prefixes flagged as error |

### 2.5 Cross-Module References

**Setup:** Multi-module fixture repo with cross-module backlinks, some valid and some broken.

| Test Area | What to Test |
|-----------|-------------|
| **Valid cross-ref** | Relative path resolves, anchor exists — no error |
| **Broken path** | Relative path to nonexistent file — reported |
| **Broken anchor** | File exists but anchor ID missing — reported |

---

## Layer 3: E2E Tests

| Test | Scenario |
|------|----------|
| **Fresh repo init** | `/anchors init` in a new repo → documents created, `AGENTS.md` created with ANCHORS section, `/anchors audit` passes with informational gaps only |
| **Self-audit** | `/anchors audit` run on the anchors-md repo itself → report generated, gaps match known state |
| **Multi-module lifecycle** | Init module A, init module B, add cross-refs, audit → both modules discovered, cross-refs validated |

---

## Test Infrastructure

### Fixture Repos

```
testdata/
  fixtures/
    clean-repo/              # Empty repo for init tests
    complete-module/          # Well-formed single module
    gaps-module/              # Module with deliberate traceability gaps
    multi-module/             # Two modules with cross-references
    broken-cross-refs/        # Multi-module with broken relative paths
    existing-files/           # Module with some ANCHORS files pre-existing
```

Each fixture is a minimal directory tree with ANCHORS documents and optional source/test files containing traceability tags.

### Self-Audit as Smoke Test

Running `/anchors audit` on this repository is the primary smoke test. The audit report should be reviewed after any change to SKILL.md, templates, or the ANCHORS documents themselves.

---

## Tooling

| Tool | Purpose |
|------|---------|
| `/anchors audit` | Self-audit — the skill audits its own repo |
| Manual review | Verify SKILL.md instructions match PRODUCT.md and ERD.md |
| Fixture-based walkthroughs | Step through init/audit on fixture repos to verify behavior |

---

## Coverage Targets

| Layer | Target | Rationale |
|-------|--------|-----------|
| Unit/Static | 100% of templates | Templates are the only static artifacts; all must be well-formed |
| Integration | 100% of audit gap categories | Every type of gap the audit can report must have a fixture that triggers it |
| E2E | All 3 modes exercised | Interactive, init, and audit must each be run at least once |

---

## What We Deliberately Don't Test

- **LLM instruction-following fidelity:** We test that the instructions are correct and complete, not that the LLM follows them perfectly every time. That's a property of the runtime, not the skill.
- **Claude Code internals:** We don't test `AskUserQuestion`, `Write`, `Glob`, or other Claude Code tools. We assume they work as documented.
- **Markdown rendering:** We don't test how documents render in various viewers. We test that the markdown structure is correct.
- **Performance:** ANCHORS operates on small document sets. There are no performance-sensitive paths.
