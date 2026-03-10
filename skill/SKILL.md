---
name: anchors
description: >
  Requirements-driven development framework. Use when scaffolding product/engineering
  requirements documents, auditing traceability between requirements and code, or
  checking document consistency.
---

# anchors

A skill for managing ANCHORS requirements-driven development documents.

ANCHORS keeps product requirements, engineering requirements, testing strategy,
dependency constraints, and implementation in a consistent, traceable hierarchy.

---

## The ANCHORS Framework

### Documents

A module's ANCHORS document set consists of up to four documents plus a marker file:

| Document | Purpose | Requirement IDs |
|----------|---------|-----------------|
| **ANCHORS.md** | Module marker. YAML frontmatter with `prefix` field. | — |
| **PRODUCT.md** | Product requirements — user-facing behavior, workflows, experience. Source of truth. | `P-*` |
| **ERD.md** | Engineering requirements — technical design, interfaces, constraints. Derived from PRODUCT.md. | `E-*` |
| **TESTING.md** | Testing strategy — pyramid, coverage invariants, requirement-to-test-layer mapping. Defines how requirements are verified. | — |
| **DEPENDENCIES.md** | External dependencies — what the environment must provide because the system cannot supply it. | `D-DEP-*` |

All four documents are part of the framework. TESTING.md and DEPENDENCIES.md participate in the truth hierarchy and have defined disagreement rules.

### Truth Hierarchy

```
PRODUCT.md (source of truth — defines correct behavior)
    ↓ derives
ERD.md (technical requirements — must fully satisfy the PRD)
    ↓ constrains
DEPENDENCIES.md (external prerequisites — what the environment must provide)

TESTING.md (testing strategy — covers both PRODUCT.md and ERD.md)
    ↓ executed as
Tests (executable specification — truthier than implementation)
    ↓ validated against
Implementation (must satisfy all of the above)
```

### Disagreement Rules

- Implementation vs tests → implementation is probably wrong
- Tests vs PRD/ERD → tests are wrong (fix the tests, or update the documents first if the requirement changed)
- TESTING.md vs PRD/ERD → TESTING.md is wrong (update the testing strategy to match the requirements)
- ERD vs PRD → ERD is wrong (PRD is authoritative)
- DEPENDENCIES.md vs ERD → check which is correct (ERD may include requirements for the system to manage something that DEPENDENCIES.md lists as external — resolve which is current)

### Rules

1. **PRODUCT.md is authoritative.** If there is a conflict between documents, PRODUCT.md wins.
2. **ERD.md must fully satisfy PRODUCT.md.** Every product requirement should have corresponding engineering requirements that cover it.
3. **All implementation must meet both PRD and ERD requirements.** Do not implement against only one document.
4. **Keep documents consistent.** When changing a requirement, update PRODUCT.md first, then ERD.md to reflect it (and link back).
5. **Do not add requirements to ERD.md that contradict or extend PRODUCT.md without updating PRODUCT.md first.** The PRD drives the ERD, not the other way around.
6. **Tests are truthier than implementation, but documents are truthier than tests.** If the implementation diverges from the tests, the implementation is assumed buggy. If the tests diverge from the PRD or ERD, the tests are wrong. Fix the code to match the tests; fix the tests to match the documents; update the documents first if the requirement has genuinely changed.
7. **Every P-\* and E-\* requirement must have test coverage.** See TESTING.md for coverage invariants and the requirement-to-test-layer mapping. A requirement without a corresponding test is a coverage gap that must be addressed.

### Requirement ID Conventions

**PRODUCT.md** — `P-` prefix with section-scoped slugs:
```markdown
- <a id="P-AUTH-LOGIN"></a>**P-AUTH-LOGIN**: Users can log in with email and password.
```

**ERD.md** — `E-` prefix with backlink to the product requirement it satisfies:
```markdown
- <a id="E-AUTH-SESSION"></a>**E-AUTH-SESSION**: Sessions use signed JWTs with 24-hour expiry.
  ← [P-AUTH-LOGIN](PRODUCT.md#P-AUTH-LOGIN)
```

Every `E-*` requirement must have a `←` backlink. This is how the audit tracks coverage.

**DEPENDENCIES.md** — `D-DEP-` prefix:
```markdown
### D-DEP-POSTGRES: PostgreSQL
- **Used by:** API server
- **Where it runs:** All environments
- **Why external:** Stateful service, cannot be bundled
```

### Coverage Invariants

TESTING.md defines the project-specific test strategy. These invariants apply universally:

1. **Every requirement has a test.** Every P-* and E-* must be covered by at least one test.
2. **Contract boundaries are tested from both sides.** Parsers (reading) and builders (writing) are both tested.
3. **Trust boundaries are tested end-to-end.** Human-approval vs. automatic actions each need an E2E test.
4. **Every public API surface has a test.** Happy path and error path.
5. **Recovery paths are tested.** At integration layer or above.
6. **Every interface has its production implementation verified.** Test doubles don't mask missing real implementations.

### Code Traceability

Tag functions and tests with requirement IDs. Augment comments, never replace them.

```go
// BuildStartCommand builds the argument list for starting the process.
// E-CLI-START: construct CLI start invocation with config flags.
func BuildStartCommand(req StartRequest) []string {
```

```go
// TestSessionExpiry verifies that expired sessions are rejected.
// E-AUTH-SESSION: sessions expire after the configured TTL.
func TestSessionExpiry(t *testing.T) {
```

Rules:
- One tag per function, not per line
- Keep existing descriptive comments — the tag is an addition
- Natural prose is fine: `// Per E-AUTH-SESSION, tokens expire after 24 hours`
- Skip self-explanatory code, boilerplate, and standard library calls

### Monorepo Support

ANCHORS supports arbitrary module nesting. A directory is an ANCHORS module if it contains an `ANCHORS.md` file with a `prefix` frontmatter field:

```yaml
---
prefix: PAY-CHECKOUT
---
```

Prefixes must be unique across the repo. Within a module, PRODUCT.md/ERD.md links are relative. Cross-module references use relative paths:

```markdown
← [P-PAY-CHECKOUT-CART](../checkout/PRODUCT.md#P-PAY-CHECKOUT-CART)
```

Not every module needs all four documents. Pure infrastructure modules might only have ERD.md tracing to another module's PRODUCT.md. TESTING.md can be per-module or shared.

---

## Routing

This skill is invoked as `/anchors` with optional arguments.

**Parse the args to determine the mode:**

| User types | Mode |
|------------|------|
| `/anchors` (no args) | **Interactive** — use `AskUserQuestion` to ask "Init or audit?" (see below) |
| `/anchors init` | **Init** — determine target path (see below) |
| `/anchors init path/to/dir` | **Init** — use the given path |
| `/anchors audit` | **Audit** |

Any other args → tell the user the available modes (init, audit).

**Interactive mode prompt:** When invoked with no args, first check whether any `ANCHORS.md` files exist in the repo (glob for `**/ANCHORS.md` excluding `node_modules`, `vendor`, `.git`, build output). Then use `AskUserQuestion`:
- Question: "What would you like to do?"
- Header: "Mode"
- If ANCHORS modules already exist, present **Audit** first (recommended):
  - **Audit** — "Check traceability and consistency across modules (Recommended)"
  - **Init** — "Scaffold ANCHORS documents in a new directory"
- If no ANCHORS modules exist, present **Init** first (recommended):
  - **Init** — "Scaffold ANCHORS documents in a directory (Recommended)"
  - **Audit** — "Check traceability and consistency across modules"

---

## Init Mode

Scaffold the ANCHORS document set in a directory.

### Determine the target path

1. If a path was given as an argument, use it.
2. If no path was given, check whether the current working directory already has an `ANCHORS.md`.
   - **No** → use the current working directory.
   - **Yes** → use `AskUserQuestion` to ask for a path:
     - Question: "This directory already has ANCHORS.md. Where should the new module be initialized?"
     - Header: "Path"
     - Options: suggest 2-3 likely subdirectories based on the repo structure (e.g., `src/`, `services/`, `packages/`). The user can always pick "Other" to type a custom path.

### Steps

1. Check if any ANCHORS documents already exist in the target directory (`ANCHORS.md`, `PRODUCT.md`, `ERD.md`, `TESTING.md`, `DEPENDENCIES.md`). If any exist, use `AskUserQuestion` to confirm:
   - Question: "These ANCHORS documents already exist: [list]. Overwrite them?"
   - Header: "Overwrite"
   - Options: **Skip existing** ("Only create missing documents"), **Overwrite all** ("Replace all documents with fresh templates")

2. Read the templates from the skill's installed location:
   - `~/.claude/skills/anchors/templates/PRODUCT.md`
   - `~/.claude/skills/anchors/templates/ERD.md`
   - `~/.claude/skills/anchors/templates/TESTING.md`
   - `~/.claude/skills/anchors/templates/DEPENDENCIES.md`

3. Use `AskUserQuestion` to ask the user for project details (both in a single call):
   - Question 1: "What is the project/module name?" — Header: "Name" — Options: offer the target directory name as the recommended default, plus 1-2 alternatives derived from parent directories or repo name.
   - Question 2: "What requirement ID prefix should be used?" — Header: "Prefix" — Options: offer an uppercase abbreviation of the name as the recommended default, plus 1-2 alternatives (e.g., shorter/longer forms).

4. Create `ANCHORS.md` in the target directory with the prefix in frontmatter.

5. Copy the four templates into the target directory, replacing `[Project Name]` with the project name.

6. Check whether a parent directory (up to the repo root) already contains an `ANCHORS.md`. If not, this is the first module in the repo — append the ANCHORS section to `CLAUDE.md` at the repo root (create if it doesn't exist):

   ```markdown
   ## Requirements-Driven Development (ANCHORS)

   This repo uses ANCHORS. Modules are marked by `ANCHORS.md` files with a `prefix` declaration.

   ### Document hierarchy (highest to lowest authority)
   1. PRODUCT.md — defines correct behavior (source of truth)
   2. ERD.md — technical requirements (must satisfy PRD, links back via ← P-*)
   3. TESTING.md — testing strategy (covers PRD and ERD, defines how requirements are verified)
   4. DEPENDENCIES.md — external prerequisites (what the environment must provide)
   5. Tests — executable specification (truthier than implementation)
   6. Implementation — must satisfy all of the above

   ### When things disagree
   - Implementation vs tests → fix implementation
   - Tests vs documents → fix tests (or update documents first if the requirement changed)
   - TESTING.md vs PRD/ERD → fix TESTING.md
   - ERD vs PRD → fix ERD
   - DEPENDENCIES.md vs ERD → check which is correct

   ### When changing requirements
   - Update PRODUCT.md first, then ERD.md, then TESTING.md, then tests, then implementation
   - Never add ERD requirements that contradict the PRD without updating the PRD first

   ### Code traceability
   - Tag functions implementing requirements: `// E-AUTH-SESSION: description`
   - Tag test functions with the requirements they verify
   - One tag per function, not per line. Augment comments, never replace.

   ### Auditing
   Use `/anchors audit` to check traceability across documents, code, and tests.
   ```

7. If there is an existing `ANCHORS.md` in a parent, verify the new prefix is unique across all `**/ANCHORS.md` files in the repo.

8. Print a summary of what was created and suggest next steps:
   - Fill in PRODUCT.md first (it's the source of truth)
   - Derive ERD.md from the product requirements
   - Write TESTING.md to define coverage strategy
   - Add DEPENDENCIES.md if the system has external dependencies

---

## Audit Mode

Audit traceability and consistency across all ANCHORS modules in the repo.

**Steps:**

1. **Discover modules.** Glob for `**/ANCHORS.md` (excluding `node_modules`, `vendor`, `.git`, build output). Read frontmatter to get each module's prefix. Check for prefix collisions.

2. **For each module:**

   a. **Read documents.** Read `PRODUCT.md`, `ERD.md`, `TESTING.md`, and `DEPENDENCIES.md` relative to the module's `ANCHORS.md`. Report which exist and which are missing.

   b. **Extract requirement IDs.** Scan for all `P-*` IDs in PRODUCT.md, `E-*` IDs in ERD.md, and `D-DEP-*` IDs in DEPENDENCIES.md.

   c. **Check ERD backlinks.** Every `E-*` requirement should have a `← [P-*](...#P-*)` backlink. Report missing backlinks.

   d. **Check PRD coverage.** Every `P-*` requirement should be referenced by at least one `E-*` requirement. Report uncovered product requirements.

   e. **Check TESTING.md.** Verify TESTING.md exists. Check that the coverage mapping table references requirement areas that correspond to actual P-* and E-* requirements.

   f. **Check DEPENDENCIES.md boundary.** Verify that nothing listed as an external dependency in DEPENDENCIES.md is contradicted by ERD.md requirements showing the system manages it internally (a stale dependency that was since internalized).

3. **Check code traceability.** Search the codebase (excluding `node_modules`, `vendor`, `.git`, build output) for references to `P-*`, `E-*`, and `D-DEP-*` requirement IDs. Report:
   - Requirements referenced in code (good)
   - Requirements with no code references (potential coverage gaps)
   - Code references to IDs that don't exist in any document (stale tags)

4. **Check test coverage tags.** Search test files for requirement ID references. Report requirements that have implementation references but no test references.

5. **Check cross-module references.** Validate that any cross-module `←` backlinks (relative paths to other modules' documents) resolve to actual files and anchors.

6. **Check open questions.** Scan all documents for unresolved `OPEN-*` items.

7. **Print a summary report:**

```
## ANCHORS Audit Report

### Modules
- services/auth (prefix: AUTH) — 4/4 documents
- services/payments (prefix: PAY) — 3/4 documents (no DEPENDENCIES.md)
- platform/shared (prefix: SHLIB) — 1/4 documents (ERD.md only)

### Traceability (all modules)
- ERD → PRD backlinks: 41/43 (2 missing)
- PRD coverage by ERD: 28/28 (100%)
- Requirements in code: 52/71 (73%)
- Requirements in tests: 38/71 (54%)

### Gaps

#### Missing ERD Backlinks
- AUTH: E-AUTH-CACHE-TTL (no ← P-* link)
- PAY: E-PAY-LOG-FORMAT (no ← P-* link)

#### Uncovered Product Requirements (P-* with no E-* coverage)
(none)

#### Untraced Requirements (no code references)
- AUTH: P-AUTH-NOTIFY-SOUND
- SHLIB: E-SHLIB-RECOVERY-RESTART

#### Requirements Without Test References
- PAY: E-PAY-WEBHOOK-RETRY (in code but not in tests)

#### Stale Code References
- src/legacy.go: references E-OLD-THING (not in any document)

#### Open Questions
- services/auth/PRODUCT.md: OPEN-MFA-FLOW (unresolved)

#### DEPENDENCIES.md Boundary Issues
(none)
```
