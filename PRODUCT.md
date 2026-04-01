---
scope: Product requirements — observable behavior, outcomes, and qualities. No implementation approach.
see-also:
  - ENGINEERING.md — engineering architecture; must not contradict this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies the system cannot supply itself.
---

# ANCHORS: Product Requirements

## Overview

ANCHORS is a requirements-driven development framework consisting of a CLI tool and an AI agent skill. It keeps product requirements, engineering requirements, testing strategy, dependency constraints, and implementation in a consistent, traceable hierarchy.

**Users** are developers using AI coding agents who want structured requirements traceability in their projects.

**Problem** — Requirements drift from implementation over time. Without a defined truth hierarchy and check tooling, teams lose track of which requirements are covered, which are stale, and where tests are missing.

**Design principles:**
- PRODUCT.md is always the source of truth
- Documents form a strict truth hierarchy that resolves disagreements deterministically
- Every requirement must be traceable from document → code → test
- The framework is lightweight — plain markdown files, no build tooling required
- The framework is agent-agnostic — documents are plain markdown, the skill works across agents

**Deployment model:** The `anchors` CLI is installed globally via a package manager. It handles deterministic operations: scaffolding document skeletons, structural linting, and managing skill files in repos. The `/anchors` skill handles LLM-powered operations: researching codebases, populating requirements content, semantic analysis, and converting detached modules. The skill invokes the CLI for its deterministic steps.

---

## 1. Document Framework

- <a id="P-ANCHORS-DOC-SET"></a>**P-ANCHORS-DOC-SET**: A module's document set consists of a marker file (`ANCHORS.md`) plus up to four documents: `PRODUCT.md`, `ENGINEERING.md`, `TESTING.md`, and `DEPENDENCIES.md`. Not every module requires all four.

- <a id="P-ANCHORS-TRUTH-HIERARCHY"></a>**P-ANCHORS-TRUTH-HIERARCHY**: Documents form a strict truth hierarchy: PRODUCT.md → ENGINEERING.md → DEPENDENCIES.md, with TESTING.md covering both PRODUCT.md and ENGINEERING.md. Tests are truthier than implementation; documents are truthier than tests.

- <a id="P-ANCHORS-DISAGREEMENT"></a>**P-ANCHORS-DISAGREEMENT**: When artifacts disagree, the framework defines deterministic resolution rules: implementation yields to tests, tests yield to documents, ENGINEERING.md yields to PRD, and TESTING.md yields to PRD/ENGINEERING.md.

- <a id="P-ANCHORS-REQ-IDS"></a>**P-ANCHORS-REQ-IDS**: Requirements use stable anchor IDs with prefixes: `P-*` for product requirements, `E-*` for engineering requirements, `D-DEP-*` for dependencies. Every `E-*` must backlink to a `P-*` via `←`.

- <a id="P-ANCHORS-TRACEABILITY"></a>**P-ANCHORS-TRACEABILITY**: Requirement IDs can be tagged in source code and test files to create traceable links from documents through implementation to verification.

- <a id="P-ANCHORS-PREFIX"></a>**P-ANCHORS-PREFIX**: Each module declares a unique uppercase prefix in `ANCHORS.md` frontmatter. Requirement IDs are scoped by this prefix (e.g., prefix `AUTH` → `P-AUTH-LOGIN`).

---

## 2. Setup Workflow

- <a id="P-ANCHORS-SETUP-SCAFFOLD"></a>**P-ANCHORS-SETUP-SCAFFOLD**: Users can set up a new ANCHORS module in any directory. The CLI scaffolds the document skeleton (files with structure but no content), and the skill researches the project (exhaustively for existing codebases, from user description for greenfield) and populates them with real requirements, real engineering specs, and a real testing strategy. A full setup (not "Skip existing") should produce a document set that passes an immediate check.

- <a id="P-ANCHORS-INSTALL"></a>**P-ANCHORS-INSTALL**: `anchors install` is a one-time repo setup command that copies the ANCHORS skill into the repo for the detected agent and updates agent instructions. This is idempotent — subsequent runs skip if already installed. It is separate from `setup` so that skill installation happens once per repo, while `setup` runs once per module.

- <a id="P-ANCHORS-SETUP-PATH"></a>**P-ANCHORS-SETUP-PATH**: If no path is given and the current directory already has `ANCHORS.md`, the skill asks the user where to set up. If the current directory is clean, it sets up there.

- <a id="P-ANCHORS-SETUP-PREFIX"></a>**P-ANCHORS-SETUP-PREFIX**: During setup, the skill asks the user for a project name and requirement ID prefix, offering sensible defaults derived from the directory name.

- <a id="P-ANCHORS-SETUP-EXISTING"></a>**P-ANCHORS-SETUP-EXISTING**: If ANCHORS documents already exist in the target directory, the skill asks the user whether to skip existing files or overwrite all.

- <a id="P-ANCHORS-SETUP-AGENT-INSTRUCTIONS"></a>**P-ANCHORS-SETUP-AGENT-INSTRUCTIONS**: When setting up the first module in a repo (no parent `ANCHORS.md`), the CLI ensures the repo's agent instructions file contains a section that tells the agent to load the anchors skill. The section should not duplicate the framework rules already in the skill. If the project uses ai-rules (has an `ai-rules/` directory), the CLI skips this step since ai-rules manages agent instruction files.

- <a id="P-ANCHORS-SETUP-UNIQUE-PREFIX"></a>**P-ANCHORS-SETUP-UNIQUE-PREFIX**: The CLI verifies that the chosen prefix is unique across all `ANCHORS.md` files in the repo.

---

## 3. Check Workflow

- <a id="P-ANCHORS-CHECK-DISCOVER"></a>**P-ANCHORS-CHECK-DISCOVER**: The check discovers all ANCHORS modules in the repo by globbing for `ANCHORS.md` files and reading their prefixes. It detects prefix collisions.

- <a id="P-ANCHORS-CHECK-DOCS"></a>**P-ANCHORS-CHECK-DOCS**: For each module, the check reports which of the four documents exist and which are missing.

- <a id="P-ANCHORS-CHECK-BACKLINKS"></a>**P-ANCHORS-CHECK-BACKLINKS**: The check verifies that every `E-*` requirement has a `← [P-*]` backlink and reports any missing.

- <a id="P-ANCHORS-CHECK-COVERAGE"></a>**P-ANCHORS-CHECK-COVERAGE**: The check verifies that every `P-*` requirement is referenced by at least one `E-*` requirement and reports uncovered product requirements.

- <a id="P-ANCHORS-CHECK-CODE-TRACE"></a>**P-ANCHORS-CHECK-CODE-TRACE**: The check searches the codebase for requirement ID references and reports: requirements referenced in code, requirements with no code references, and stale code references to IDs that don't exist in any document.

- <a id="P-ANCHORS-CHECK-TEST-TRACE"></a>**P-ANCHORS-CHECK-TEST-TRACE**: The check searches test files for requirement ID references and reports requirements that have implementation references but no test references.

- <a id="P-ANCHORS-CHECK-CROSS-MODULE"></a>**P-ANCHORS-CHECK-CROSS-MODULE**: The check validates cross-module backlinks resolve to actual files and anchors.

- <a id="P-ANCHORS-CHECK-OPEN"></a>**P-ANCHORS-CHECK-OPEN**: The check scans all documents for unresolved `OPEN-*` items and includes them in the report.

- <a id="P-ANCHORS-CHECK-REPORT"></a>**P-ANCHORS-CHECK-REPORT**: The check produces a structured summary report showing module status, traceability statistics, and categorized gaps. The report includes both structural validation and semantic analysis (requirement accuracy, staleness, drift).

---

## 4. Monorepo Support

- <a id="P-ANCHORS-MONO-NESTING"></a>**P-ANCHORS-MONO-NESTING**: ANCHORS supports arbitrary module nesting. Any directory with an `ANCHORS.md` containing a `prefix` field is a module.

- <a id="P-ANCHORS-MONO-CROSS-REF"></a>**P-ANCHORS-MONO-CROSS-REF**: Modules can reference requirements in other modules using relative paths (e.g., `← [P-PAY-CART](../checkout/PRODUCT.md#P-PAY-CART)`).

- <a id="P-ANCHORS-MONO-PARTIAL"></a>**P-ANCHORS-MONO-PARTIAL**: Not every module needs all four documents. Infrastructure modules may have only ENGINEERING.md tracing to another module's PRODUCT.md.

---

## 5. Interactive Routing

- <a id="P-ANCHORS-ROUTE-INTERACTIVE"></a>**P-ANCHORS-ROUTE-INTERACTIVE**: When invoked with no arguments, the skill asks the user whether to set up, check, or embed, recommending check if modules already exist and setup if none exist. Embed is only offered when detached modules exist.

- <a id="P-ANCHORS-ROUTE-ARGS"></a>**P-ANCHORS-ROUTE-ARGS**: The skill accepts `setup`, `setup <path>`, `check`, `embed`, and `embed <path>` as arguments to skip the interactive prompt.

---

## 6. CLI

- <a id="P-ANCHORS-CLI"></a>**P-ANCHORS-CLI**: ANCHORS provides an `anchors` CLI tool installed globally via a package manager. The CLI handles all deterministic operations that don't require an LLM: scaffolding document skeletons, structural linting, and managing skill files.

- <a id="P-ANCHORS-CLI-SETUP"></a>**P-ANCHORS-CLI-SETUP**: `anchors setup` scaffolds a document skeleton in the target directory. It accepts `--prefix`, `--mode`, `--skip-existing`, a target path, and detached-mode options (`--path`, `--repo`, `--ref`) as arguments. It does not install the skill — that is `anchors install`.

- <a id="P-ANCHORS-CLI-CHECK"></a>**P-ANCHORS-CLI-CHECK**: `anchors check <path>` performs structural linting on the ANCHORS module at the given path: validates frontmatter, checks backlinks, verifies PRD coverage, and reports gaps. Requires a path to a directory containing `ANCHORS.md`. Runs without an LLM, suitable for CI.

- <a id="P-ANCHORS-CLI-UPGRADE"></a>**P-ANCHORS-CLI-UPGRADE**: `anchors upgrade` updates the skill files in the repo to the latest version bundled with the CLI.

- <a id="P-ANCHORS-UPGRADE-VERSION"></a>**P-ANCHORS-UPGRADE-VERSION**: `anchors upgrade` prints the installed and incoming versions and refuses to downgrade — if the installed skill is newer than the CLI's bundled version, the upgrade aborts. A `--force` flag overrides the downgrade check.

- <a id="P-ANCHORS-CLI-AGENTS"></a>**P-ANCHORS-CLI-AGENTS**: The CLI supports multiple AI coding agents: Claude Code, Amp, Codex, Goose, and ai-rules. The agent is specified via `--agent` flag or auto-detected from the repo. Skill files are copied to the agent-appropriate project-level location.

- <a id="P-ANCHORS-CLI-AIRULES"></a>**P-ANCHORS-CLI-AIRULES**: When the agent is ai-rules, the CLI copies the skill into the project's `ai-rules/skills/` directory and runs `ai-rules generate`. This requires the `ai-rules` CLI to be installed and an `ai-rules/` directory to exist in the project.

---

## 7. Detached Mode

- <a id="P-ANCHORS-MODE-EMBEDDED"></a>**P-ANCHORS-MODE-EMBEDDED**: The default mode — docs live alongside the code they describe. All existing behavior (inline code tags, check code search, setup research against local files) applies to embedded mode.

- <a id="P-ANCHORS-MODE-DETACHED"></a>**P-ANCHORS-MODE-DETACHED**: Docs can live separately from the code they describe — either in a dedicated subdirectory within the same repo or in a completely separate repo. Detached mode enables requirements-driven development without modifying the target codebase. Mode is set explicitly via `mode: detached` in ANCHORS.md frontmatter.

- <a id="P-ANCHORS-DETACHED-IN-REPO"></a>**P-ANCHORS-DETACHED-IN-REPO**: In-repo detached mode: the anchors documents live in a subdirectory of the same repo as the code (e.g., `apps/penpal/anchors/`). The `path` field locates the target code relative to the ANCHORS.md file. No `repo` or `ref` fields are needed.

- <a id="P-ANCHORS-DETACHED-EXTERNAL"></a>**P-ANCHORS-DETACHED-EXTERNAL**: External detached mode: the anchors documents live in a separate repo from the code. The `repo` field identifies the target codebase (URL or local path), `ref` specifies the branch/tag/SHA, and `path` scopes to a subdirectory within that repo.

- <a id="P-ANCHORS-DETACHED-FORWARD-REFS"></a>**P-ANCHORS-DETACHED-FORWARD-REFS**: In detached mode, ENGINEERING.md uses `→` forward references to trace requirements to specific code locations in the target codebase (files and symbols).

- <a id="P-ANCHORS-DETACHED-SETUP"></a>**P-ANCHORS-DETACHED-SETUP**: Setup for detached mode researches the target codebase and generates documents with forward references to code locations.

- <a id="P-ANCHORS-DETACHED-CHECK"></a>**P-ANCHORS-DETACHED-CHECK**: Check for detached mode resolves the target codebase and validates that forward references resolve to real files and symbols.

- <a id="P-ANCHORS-DETACHED-NO-TOUCH"></a>**P-ANCHORS-DETACHED-NO-TOUCH**: Detached mode never modifies the target codebase — no inline tags, no sidecar files, nothing.

- <a id="P-ANCHORS-DETACHED-EMBED"></a>**P-ANCHORS-DETACHED-EMBED**: A detached module can be converted to embedded mode. The embed action adds inline requirement tags to source files based on the `→` forward references, removes the forward references from ENGINEERING.md, and removes the detached-mode fields from ANCHORS.md. This requires the target code to be locally accessible.

---

## Open Questions

(none)

## Resolved Questions
