---
scope: Product requirements — user-facing behavior, workflows, and experience.
see-also:
  - ERD.md — technical requirements derived from this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies the system cannot supply itself.
---

# ANCHORS: Product Requirements

## Overview

ANCHORS is a requirements-driven development framework distributed as an AI agent skill. It keeps product requirements, engineering requirements, testing strategy, dependency constraints, and implementation in a consistent, traceable hierarchy.

**Users** are developers using AI coding agents who want structured requirements traceability in their projects.

**Problem** — Requirements drift from implementation over time. Without a defined truth hierarchy and audit tooling, teams lose track of which requirements are covered, which are stale, and where tests are missing.

**Design principles:**
- PRODUCT.md is always the source of truth
- Documents form a strict truth hierarchy that resolves disagreements deterministically
- Every requirement must be traceable from document → code → test
- The framework is lightweight — plain markdown files, no build tooling required
- The framework is agent-agnostic — documents are plain markdown, the skill works across agents

**Deployment model:** Installed as a skill for AI coding agents (Claude Code, Amp, Codex) via the installer, or distributed through ai-rules for multi-agent projects. Invoked interactively through `/anchors`.

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

- <a id="P-ANCHORS-INIT-SCAFFOLD"></a>**P-ANCHORS-INIT-SCAFFOLD**: Users can initialize a new ANCHORS module in any directory. The skill researches the project (exhaustively for existing codebases, from user description for greenfield) and generates fully populated documents — real requirements, real engineering specs, a real testing strategy. A full init (not "Skip existing") should produce a document set that passes an immediate audit.

- <a id="P-ANCHORS-INIT-PATH"></a>**P-ANCHORS-INIT-PATH**: If no path is given and the current directory already has `ANCHORS.md`, the skill asks the user where to initialize. If the current directory is clean, it initializes there.

- <a id="P-ANCHORS-INIT-PREFIX"></a>**P-ANCHORS-INIT-PREFIX**: During init, the skill asks the user for a project name and requirement ID prefix, offering sensible defaults derived from the directory name.

- <a id="P-ANCHORS-INIT-EXISTING"></a>**P-ANCHORS-INIT-EXISTING**: If ANCHORS documents already exist in the target directory, the skill asks the user whether to skip existing files or overwrite all.

- <a id="P-ANCHORS-INIT-CLAUDE-MD"></a>**P-ANCHORS-INIT-CLAUDE-MD**: When initializing the first module in a repo (no parent `ANCHORS.md`), the skill appends a short ANCHORS section to the repo's agent instructions file (`AGENTS.md` and/or `CLAUDE.md`). If both exist and are separate files, both are updated. If one is a symlink to the other, only the real file is updated. If neither exists, `AGENTS.md` is created. The section instructs the agent to load the anchors skill — it should not duplicate the framework rules already in the skill. If the project uses ai-rules (has an `ai-rules/` directory), the skill skips this step since ai-rules manages agent instruction files.

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

## 6. Installation

- <a id="P-ANCHORS-INSTALL-AGENTS"></a>**P-ANCHORS-INSTALL-AGENTS**: The installer supports multiple AI coding agents: Claude Code, Amp, Codex, and ai-rules. Users select their agent from a menu.

- <a id="P-ANCHORS-INSTALL-SCOPE"></a>**P-ANCHORS-INSTALL-SCOPE**: For direct agent installs (Claude Code, Amp, Codex), users choose between user-level (available in all projects) and project-level (available in one repo) installation.

- <a id="P-ANCHORS-INSTALL-COPY"></a>**P-ANCHORS-INSTALL-COPY**: The installer copies the skill directory to the agent-appropriate location, replacing any existing installation at that path.

- <a id="P-ANCHORS-INSTALL-AIRULES"></a>**P-ANCHORS-INSTALL-AIRULES**: When ai-rules is selected, the installer copies the skill into the project's `ai-rules/skills/` directory and runs `ai-rules generate` to produce agent-specific configuration files. This requires the `ai-rules` CLI to be installed and an `ai-rules/` directory to exist in the project.

- <a id="P-ANCHORS-INSTALL-AIRULES-PREREQS"></a>**P-ANCHORS-INSTALL-AIRULES-PREREQS**: The installer validates ai-rules prerequisites before proceeding: the `ai-rules` CLI must be on PATH, and the project must have an `ai-rules/` directory (created by `ai-rules init`). Clear error messages guide the user to resolve missing prerequisites.

- <a id="P-ANCHORS-INSTALL-AGENT-INSTRUCTIONS"></a>**P-ANCHORS-INSTALL-AGENT-INSTRUCTIONS**: For project-level installs, the installer ensures the agent knows to load the ANCHORS skill. For direct agent installs (Claude Code, Amp, Codex), it appends an ANCHORS section to the repo's agent instructions file using the same logic as init step 6 (`AGENTS.md`/`CLAUDE.md` handling). For ai-rules, it creates a rule file in `ai-rules/` with the ANCHORS instructions so that `ai-rules generate` includes them in generated agent configs.

---

## 7. Detached Mode

- <a id="P-ANCHORS-MODE-EMBEDDED"></a>**P-ANCHORS-MODE-EMBEDDED**: The default mode — docs live in the same repo as the code. All existing behavior (inline code tags, audit code search, init research against local files) applies to embedded mode.

- <a id="P-ANCHORS-MODE-DETACHED"></a>**P-ANCHORS-MODE-DETACHED**: Docs can live in a separate repo from the code they describe. ANCHORS.md points to the target codebase. This enables requirements-driven development for codebases the user doesn't own or can't modify.

- <a id="P-ANCHORS-DETACHED-POINTER"></a>**P-ANCHORS-DETACHED-POINTER**: In detached mode, ANCHORS.md frontmatter includes `repo`, `ref`, and `path` fields that identify the target codebase.

- <a id="P-ANCHORS-DETACHED-FORWARD-REFS"></a>**P-ANCHORS-DETACHED-FORWARD-REFS**: In detached mode, ERD.md uses `→` forward references to trace requirements to specific code locations in the target repo (files and symbols).

- <a id="P-ANCHORS-DETACHED-INIT"></a>**P-ANCHORS-DETACHED-INIT**: Init for detached mode fetches the target repo for research and generates documents with forward references to code locations.

- <a id="P-ANCHORS-DETACHED-AUDIT"></a>**P-ANCHORS-DETACHED-AUDIT**: Audit for detached mode fetches the target repo and validates that forward references resolve to real files and symbols.

- <a id="P-ANCHORS-DETACHED-NO-TOUCH"></a>**P-ANCHORS-DETACHED-NO-TOUCH**: Detached mode never modifies the target codebase — no inline tags, no sidecar files, nothing.

- <a id="P-ANCHORS-DETACHED-EMBED"></a>**P-ANCHORS-DETACHED-EMBED**: A detached module can be converted to embedded mode. The embed action adds inline requirement tags to source files based on the `→` forward references, removes the forward references from ERD.md, and removes the `repo`/`ref`/`path` fields from ANCHORS.md. This requires the target code to be locally accessible.

---

## Open Questions

(none)

## Resolved Questions
