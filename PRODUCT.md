---
scope: Product requirements — user-facing behavior, workflows, and experience.
see-also:
  - ERD.md — technical requirements derived from this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies the system cannot supply itself.
---

# ANCHORS: Product Requirements

## Overview

ANCHORS is a requirements-driven development framework distributed as a Claude Code skill. It keeps product requirements, engineering requirements, testing strategy, dependency constraints, and implementation in a consistent, traceable hierarchy.

**Users** are developers using Claude Code who want structured requirements traceability in their projects.

**Problem** — Requirements drift from implementation over time. Without a defined truth hierarchy and audit tooling, teams lose track of which requirements are covered, which are stale, and where tests are missing.

**Design principles:**
- PRODUCT.md is always the source of truth
- Documents form a strict truth hierarchy that resolves disagreements deterministically
- Every requirement must be traceable from document → code → test
- The framework is lightweight — plain markdown files, no build tooling required

**Deployment model:** Installed as a Claude Code skill via symlink. Invoked interactively through `/anchors`.

---

## 1. Document Framework

- <a id="P-ANCHORS-DOC-SET"></a>**P-ANCHORS-DOC-SET**: A module's document set consists of a marker file (`ANCHORS.md`) plus up to four documents: `PRODUCT.md`, `ERD.md`, `TESTING.md`, and `DEPENDENCIES.md`. Not every module requires all four.

- <a id="P-ANCHORS-TRUTH-HIERARCHY"></a>**P-ANCHORS-TRUTH-HIERARCHY**: Documents form a strict truth hierarchy: PRODUCT.md → ERD.md → DEPENDENCIES.md, with TESTING.md covering both PRODUCT.md and ERD.md. Tests are truthier than implementation; documents are truthier than tests.

- <a id="P-ANCHORS-DISAGREEMENT"></a>**P-ANCHORS-DISAGREEMENT**: When artifacts disagree, the framework defines deterministic resolution rules: implementation yields to tests, tests yield to documents, ERD yields to PRD, and TESTING.md yields to PRD/ERD.

- <a id="P-ANCHORS-REQ-IDS"></a>**P-ANCHORS-REQ-IDS**: Requirements use stable anchor IDs with prefixes: `P-*` for product requirements, `E-*` for engineering requirements, `D-DEP-*` for dependencies. Every `E-*` must backlink to a `P-*` via `←`.

- <a id="P-ANCHORS-TRACEABILITY"></a>**P-ANCHORS-TRACEABILITY**: Requirement IDs can be tagged in source code and test files to create traceable links from documents through implementation to verification.

- <a id="P-ANCHORS-PREFIX"></a>**P-ANCHORS-PREFIX**: Each module declares a unique prefix in `ANCHORS.md` frontmatter. Requirement IDs are scoped by this prefix (e.g., prefix `AUTH` → `P-AUTH-LOGIN`).

---

## 2. Init Workflow

- <a id="P-ANCHORS-INIT-SCAFFOLD"></a>**P-ANCHORS-INIT-SCAFFOLD**: Users can scaffold a new ANCHORS module in any directory. The skill creates `ANCHORS.md` and the four document templates populated with the chosen project name.

- <a id="P-ANCHORS-INIT-PATH"></a>**P-ANCHORS-INIT-PATH**: If no path is given and the current directory already has `ANCHORS.md`, the skill asks the user where to initialize. If the current directory is clean, it initializes there.

- <a id="P-ANCHORS-INIT-PREFIX"></a>**P-ANCHORS-INIT-PREFIX**: During init, the skill asks the user for a project name and requirement ID prefix, offering sensible defaults derived from the directory name.

- <a id="P-ANCHORS-INIT-EXISTING"></a>**P-ANCHORS-INIT-EXISTING**: If ANCHORS documents already exist in the target directory, the skill asks the user whether to skip existing files or overwrite all.

- <a id="P-ANCHORS-INIT-CLAUDE-MD"></a>**P-ANCHORS-INIT-CLAUDE-MD**: When initializing the first module in a repo (no parent `ANCHORS.md`), the skill appends a short ANCHORS section to the repo's agent instructions file (`AGENTS.md` and/or `CLAUDE.md`). If both exist and are separate files, both are updated. If one is a symlink to the other, only the real file is updated. If neither exists, `AGENTS.md` is created. The section instructs Claude to load the anchors skill — it should not duplicate the framework rules already in the skill.

- <a id="P-ANCHORS-INIT-UNIQUE-PREFIX"></a>**P-ANCHORS-INIT-UNIQUE-PREFIX**: The skill verifies that the chosen prefix is unique across all `ANCHORS.md` files in the repo.

---

## 3. Audit Workflow

- <a id="P-ANCHORS-AUDIT-DISCOVER"></a>**P-ANCHORS-AUDIT-DISCOVER**: The audit discovers all ANCHORS modules in the repo by globbing for `ANCHORS.md` files and reading their prefixes. It detects prefix collisions.

- <a id="P-ANCHORS-AUDIT-DOCS"></a>**P-ANCHORS-AUDIT-DOCS**: For each module, the audit reports which of the four documents exist and which are missing.

- <a id="P-ANCHORS-AUDIT-BACKLINKS"></a>**P-ANCHORS-AUDIT-BACKLINKS**: The audit checks that every `E-*` requirement has a `← [P-*]` backlink and reports any missing.

- <a id="P-ANCHORS-AUDIT-COVERAGE"></a>**P-ANCHORS-AUDIT-COVERAGE**: The audit checks that every `P-*` requirement is referenced by at least one `E-*` requirement and reports uncovered product requirements.

- <a id="P-ANCHORS-AUDIT-CODE-TRACE"></a>**P-ANCHORS-AUDIT-CODE-TRACE**: The audit searches the codebase for requirement ID references and reports: requirements referenced in code, requirements with no code references, and stale code references to IDs that don't exist in any document.

- <a id="P-ANCHORS-AUDIT-TEST-TRACE"></a>**P-ANCHORS-AUDIT-TEST-TRACE**: The audit searches test files for requirement ID references and reports requirements that have implementation references but no test references.

- <a id="P-ANCHORS-AUDIT-CROSS-MODULE"></a>**P-ANCHORS-AUDIT-CROSS-MODULE**: The audit validates cross-module backlinks resolve to actual files and anchors.

- <a id="P-ANCHORS-AUDIT-OPEN"></a>**P-ANCHORS-AUDIT-OPEN**: The audit scans all documents for unresolved `OPEN-*` items and includes them in the report.

- <a id="P-ANCHORS-AUDIT-REPORT"></a>**P-ANCHORS-AUDIT-REPORT**: The audit produces a structured summary report showing module status, traceability statistics, and categorized gaps.

---

## 4. Monorepo Support

- <a id="P-ANCHORS-MONO-NESTING"></a>**P-ANCHORS-MONO-NESTING**: ANCHORS supports arbitrary module nesting. Any directory with an `ANCHORS.md` containing a `prefix` field is a module.

- <a id="P-ANCHORS-MONO-CROSS-REF"></a>**P-ANCHORS-MONO-CROSS-REF**: Modules can reference requirements in other modules using relative paths (e.g., `← [P-PAY-CART](../checkout/PRODUCT.md#P-PAY-CART)`).

- <a id="P-ANCHORS-MONO-PARTIAL"></a>**P-ANCHORS-MONO-PARTIAL**: Not every module needs all four documents. Infrastructure modules may have only ERD.md tracing to another module's PRODUCT.md.

---

## 5. Interactive Routing

- <a id="P-ANCHORS-ROUTE-INTERACTIVE"></a>**P-ANCHORS-ROUTE-INTERACTIVE**: When invoked with no arguments, the skill asks the user whether to init or audit, recommending audit if modules already exist and init if none exist.

- <a id="P-ANCHORS-ROUTE-ARGS"></a>**P-ANCHORS-ROUTE-ARGS**: The skill accepts `init`, `init <path>`, and `audit` as arguments to skip the interactive prompt.

---

## Open Questions

(none)

## Resolved Questions
