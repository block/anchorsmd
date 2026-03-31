---
scope: Engineering requirements — how the system achieves the product requirements. Technical decisions, mechanisms, and interfaces. Derived from product requirements.
see-also:
  - PRODUCT.md — product requirements that drive the technical decisions in this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies that the system cannot supply itself.
---

# ANCHORS: Engineering Requirements

This document defines the technical requirements for the ANCHORS skill. These are derived from the [product requirements](PRODUCT.md).

ANCHORS consists of two components: an `anchors` CLI (bash script with subcommands) for deterministic operations, and a Claude Code skill (`SKILL.md` plus templates) for LLM-powered operations. The CLI handles scaffolding, structural linting, and skill file management. The skill handles codebase research, content population, semantic analysis, and interactive workflows. The skill invokes the CLI for its deterministic steps.

---

## 1. Document Format

- <a id="E-ANCHORS-MARKER-FORMAT"></a>**E-ANCHORS-MARKER-FORMAT**: `ANCHORS.md` must contain YAML frontmatter with a `prefix` field. The prefix value is an uppercase string used to scope all requirement IDs in the module.
  ← [P-ANCHORS-PREFIX](PRODUCT.md#P-ANCHORS-PREFIX)

- <a id="E-ANCHORS-DOC-LOCATIONS"></a>**E-ANCHORS-DOC-LOCATIONS**: When present, the four documents (`PRODUCT.md`, `ERD.md`, `TESTING.md`, `DEPENDENCIES.md`) must be siblings of `ANCHORS.md` in the same directory. Not all four are required (see P-ANCHORS-MONO-PARTIAL).
  ← [P-ANCHORS-DOC-SET](PRODUCT.md#P-ANCHORS-DOC-SET)

- <a id="E-ANCHORS-FRONTMATTER"></a>**E-ANCHORS-FRONTMATTER**: Each document includes YAML frontmatter with `scope` and `see-also` fields for self-documentation. Templates provide this structure.
  ← [P-ANCHORS-DOC-SET](PRODUCT.md#P-ANCHORS-DOC-SET)

---

## 2. Requirement ID Format

- <a id="E-ANCHORS-P-ID-FORMAT"></a>**E-ANCHORS-P-ID-FORMAT**: Product requirement IDs use the format `P-{PREFIX}-{SLUG}` where `{PREFIX}` comes from `ANCHORS.md` frontmatter and `{SLUG}` is an uppercase section-scoped name. IDs are declared as HTML anchors: `<a id="P-PREFIX-SLUG"></a>**P-PREFIX-SLUG**:`.
  ← [P-ANCHORS-REQ-IDS](PRODUCT.md#P-ANCHORS-REQ-IDS)

- <a id="E-ANCHORS-E-ID-FORMAT"></a>**E-ANCHORS-E-ID-FORMAT**: Engineering requirement IDs use the format `E-{PREFIX}-{SLUG}` with the same anchor pattern. Every `E-*` entry must include a `← [P-*](PRODUCT.md#P-*)` backlink on the line following the requirement text.
  ← [P-ANCHORS-REQ-IDS](PRODUCT.md#P-ANCHORS-REQ-IDS)

- <a id="E-ANCHORS-DEP-ID-FORMAT"></a>**E-ANCHORS-DEP-ID-FORMAT**: Dependency IDs use the format `D-DEP-{SLUG}` as section headers in `DEPENDENCIES.md`, with structured fields: Used by, Where it runs, Why external.
  ← [P-ANCHORS-REQ-IDS](PRODUCT.md#P-ANCHORS-REQ-IDS)

- <a id="E-ANCHORS-CODE-TAG-FORMAT"></a>**E-ANCHORS-CODE-TAG-FORMAT**: Code traceability tags are single-line comments containing a requirement ID, placed once per function. Format: `// E-PREFIX-SLUG: description` or natural prose like `// Per E-PREFIX-SLUG, ...`. Tags augment existing comments, never replace them.
  ← [P-ANCHORS-TRACEABILITY](PRODUCT.md#P-ANCHORS-TRACEABILITY)

---

## 3. Truth Hierarchy Resolution

- <a id="E-ANCHORS-HIERARCHY-ORDER"></a>**E-ANCHORS-HIERARCHY-ORDER**: The truth hierarchy is strictly ordered: PRODUCT.md > ERD.md > DEPENDENCIES.md for document authority, with TESTING.md covering both PRODUCT.md and ERD.md. Tests > implementation. Documents > tests.
  ← [P-ANCHORS-TRUTH-HIERARCHY](PRODUCT.md#P-ANCHORS-TRUTH-HIERARCHY)

- <a id="E-ANCHORS-DISAGREE-RULES"></a>**E-ANCHORS-DISAGREE-RULES**: Disagreement resolution is deterministic: (1) implementation vs tests → fix implementation, (2) tests vs PRD/ERD → fix tests, (3) TESTING.md vs PRD/ERD → fix TESTING.md, (4) ERD vs PRD → fix ERD, (5) DEPENDENCIES.md vs ERD → investigate which is correct.
  ← [P-ANCHORS-DISAGREEMENT](PRODUCT.md#P-ANCHORS-DISAGREEMENT)

---

## 4. Setup Algorithm

- <a id="E-ANCHORS-SETUP-PATH-RESOLUTION"></a>**E-ANCHORS-SETUP-PATH-RESOLUTION**: Path resolution follows: (1) explicit path argument → use it, (2) no argument and CWD has no `ANCHORS.md` → use CWD, (3) no argument and CWD has `ANCHORS.md` → prompt user with suggested subdirectories.
  ← [P-ANCHORS-SETUP-PATH](PRODUCT.md#P-ANCHORS-SETUP-PATH)

- <a id="E-ANCHORS-SETUP-CONFLICT-CHECK"></a>**E-ANCHORS-SETUP-CONFLICT-CHECK**: Before writing, glob the target directory for all five filenames. If any exist, prompt: "Skip existing" (only create missing) or "Overwrite all" (replace everything).
  ← [P-ANCHORS-SETUP-EXISTING](PRODUCT.md#P-ANCHORS-SETUP-EXISTING)

- <a id="E-ANCHORS-SETUP-RESEARCH"></a>**E-ANCHORS-SETUP-RESEARCH**: For existing codebases, launch parallel subagents to exhaustively research functional areas, technical architecture, external dependencies, and testing. Each subagent returns structured findings (not raw source code) to protect context. Tests are weighted heavily — tested behaviors are stronger requirement signals than implementation details. For greenfield projects, generate from the user's project description. The document format conventions described in SKILL.md's framework section guide the structure of the generated content.
  ← [P-ANCHORS-SETUP-SCAFFOLD](PRODUCT.md#P-ANCHORS-SETUP-SCAFFOLD)

- <a id="E-ANCHORS-SETUP-DEFAULTS"></a>**E-ANCHORS-SETUP-DEFAULTS**: The skill suggests the target directory name as the default project name and an uppercase abbreviation as the default prefix (e.g., directory `auth-service` → name "auth-service", prefix "AUTH").
  ← [P-ANCHORS-SETUP-PREFIX](PRODUCT.md#P-ANCHORS-SETUP-PREFIX)

- <a id="E-ANCHORS-SETUP-AGENT-INSTRUCTIONS"></a>**E-ANCHORS-SETUP-AGENT-INSTRUCTIONS**: When no parent directory (up to repo root) contains `ANCHORS.md`, append a minimal ANCHORS section to the agent instructions file at the repo root. Resolution: check for `AGENTS.md` and `CLAUDE.md`; if one symlinks to the other, update the real file; if both exist as separate files, update both; if only one exists, update it; if neither exists, create `AGENTS.md`. The section instructs the agent to load the anchors skill — it does not duplicate the framework rules already in the skill. If an `ai-rules/` directory exists at the repo root, skip this step entirely — ai-rules manages those files via `ai-rules generate`. This logic lives in the CLI (`anchors setup`) so it can be invoked both directly and by the skill.
  ← [P-ANCHORS-SETUP-AGENT-INSTRUCTIONS](PRODUCT.md#P-ANCHORS-SETUP-AGENT-INSTRUCTIONS)

- <a id="E-ANCHORS-SETUP-PREFIX-UNIQUE"></a>**E-ANCHORS-SETUP-PREFIX-UNIQUE**: After the user chooses a prefix, glob for all `**/ANCHORS.md` files in the repo (excluding `node_modules`, `vendor`, `.git`, build output), read their `prefix` fields, and reject duplicates. This check runs in the CLI.
  ← [P-ANCHORS-SETUP-UNIQUE-PREFIX](PRODUCT.md#P-ANCHORS-SETUP-UNIQUE-PREFIX)

- <a id="E-ANCHORS-CLI-INSTALL"></a>**E-ANCHORS-CLI-INSTALL**: `anchors install [--agent AGENT]` detects the agent (via `--agent` flag or by checking for `.claude/`, `.agents/`, `ai-rules/` directories) and copies the skill files to the agent-appropriate project-level location, then updates agent instructions. Subsequent runs detect the existing skill and skip. For ai-rules, it also creates the rule file and runs `ai-rules generate`.
  ← [P-ANCHORS-INSTALL](PRODUCT.md#P-ANCHORS-INSTALL)

---

## 5. Check Algorithm

- <a id="E-ANCHORS-CHECK-GLOB"></a>**E-ANCHORS-CHECK-GLOB**: Module discovery globs for `**/ANCHORS.md` excluding `node_modules`, `vendor`, `.git`, and build output directories. Each file's YAML frontmatter is parsed for the `prefix` field.
  ← [P-ANCHORS-CHECK-DISCOVER](PRODUCT.md#P-ANCHORS-CHECK-DISCOVER)

- <a id="E-ANCHORS-CHECK-PREFIX-COLLISION"></a>**E-ANCHORS-CHECK-PREFIX-COLLISION**: If two modules share the same prefix, the check reports a prefix collision as an error.
  ← [P-ANCHORS-CHECK-DISCOVER](PRODUCT.md#P-ANCHORS-CHECK-DISCOVER)

- <a id="E-ANCHORS-CHECK-DOC-PRESENCE"></a>**E-ANCHORS-CHECK-DOC-PRESENCE**: For each module directory, check for the existence of `PRODUCT.md`, `ERD.md`, `TESTING.md`, and `DEPENDENCIES.md`. Report as `N/4 documents`.
  ← [P-ANCHORS-CHECK-DOCS](PRODUCT.md#P-ANCHORS-CHECK-DOCS)

- <a id="E-ANCHORS-CHECK-ID-EXTRACT"></a>**E-ANCHORS-CHECK-ID-EXTRACT**: Extract requirement IDs by scanning PRODUCT.md for `P-{PREFIX}-*` patterns, ERD.md for `E-{PREFIX}-*` patterns, and DEPENDENCIES.md for `D-DEP-*` patterns. Use the HTML anchor `<a id="...">` as the canonical source.
  ← [P-ANCHORS-CHECK-BACKLINKS](PRODUCT.md#P-ANCHORS-CHECK-BACKLINKS)

- <a id="E-ANCHORS-CHECK-BACKLINK-CHECK"></a>**E-ANCHORS-CHECK-BACKLINK-CHECK**: For each `E-*` requirement, search for a `←` marker followed by a `[P-*]` link on the same or next line. Report any `E-*` without a backlink.
  ← [P-ANCHORS-CHECK-BACKLINKS](PRODUCT.md#P-ANCHORS-CHECK-BACKLINKS)

- <a id="E-ANCHORS-CHECK-PRD-COVERAGE"></a>**E-ANCHORS-CHECK-PRD-COVERAGE**: Build a set of all `P-*` IDs from PRODUCT.md. For each, check if any `E-*` requirement's backlink references it. Report `P-*` IDs with zero `E-*` coverage.
  ← [P-ANCHORS-CHECK-COVERAGE](PRODUCT.md#P-ANCHORS-CHECK-COVERAGE)

- <a id="E-ANCHORS-CHECK-CODE-SEARCH"></a>**E-ANCHORS-CHECK-CODE-SEARCH**: Search all non-excluded source files for strings matching known `P-*`, `E-*`, and `D-DEP-*` IDs. Classify each file as implementation or test based on path conventions (e.g., `*_test.go`, `*.test.ts`, `test_*.py`, files under `__tests__/`).
  ← [P-ANCHORS-CHECK-CODE-TRACE](PRODUCT.md#P-ANCHORS-CHECK-CODE-TRACE)

- <a id="E-ANCHORS-CHECK-STALE-REFS"></a>**E-ANCHORS-CHECK-STALE-REFS**: Any requirement ID found in code that doesn't match an ID in any ANCHORS document is reported as a stale reference.
  ← [P-ANCHORS-CHECK-CODE-TRACE](PRODUCT.md#P-ANCHORS-CHECK-CODE-TRACE)

- <a id="E-ANCHORS-CHECK-TEST-GAP"></a>**E-ANCHORS-CHECK-TEST-GAP**: Requirements that appear in implementation files but not in test files are reported as "in code but not in tests."
  ← [P-ANCHORS-CHECK-TEST-TRACE](PRODUCT.md#P-ANCHORS-CHECK-TEST-TRACE)

- <a id="E-ANCHORS-CHECK-CROSS-RESOLVE"></a>**E-ANCHORS-CHECK-CROSS-RESOLVE**: For backlinks containing relative paths (e.g., `../checkout/PRODUCT.md#P-*`), resolve the path relative to the current module directory and verify the target file exists and contains the referenced anchor ID.
  ← [P-ANCHORS-CHECK-CROSS-MODULE](PRODUCT.md#P-ANCHORS-CHECK-CROSS-MODULE)

- <a id="E-ANCHORS-CHECK-OPEN-SCAN"></a>**E-ANCHORS-CHECK-OPEN-SCAN**: Scan all ANCHORS documents for `OPEN-*` strings not preceded by `~~` (which indicates resolved). Report each with its source file.
  ← [P-ANCHORS-CHECK-OPEN](PRODUCT.md#P-ANCHORS-CHECK-OPEN)

- <a id="E-ANCHORS-CHECK-REPORT-FORMAT"></a>**E-ANCHORS-CHECK-REPORT-FORMAT**: The check report is structured markdown with sections: Modules (list with prefix, doc count), Traceability (aggregate stats), and Gaps (categorized: missing backlinks, uncovered PRD, untraced requirements, missing test refs, stale refs, structural drift, open questions, dependency boundary issues). The CLI produces the structural report; the skill adds semantic analysis on top.
  ← [P-ANCHORS-CHECK-REPORT](PRODUCT.md#P-ANCHORS-CHECK-REPORT)

---

## 6. Monorepo Conventions

- <a id="E-ANCHORS-MONO-MODULE-DETECTION"></a>**E-ANCHORS-MONO-MODULE-DETECTION**: A directory is an ANCHORS module if and only if it contains an `ANCHORS.md` file whose YAML frontmatter includes a `prefix` field. Nesting depth is unlimited.
  ← [P-ANCHORS-MONO-NESTING](PRODUCT.md#P-ANCHORS-MONO-NESTING)

- <a id="E-ANCHORS-MONO-RELATIVE-PATHS"></a>**E-ANCHORS-MONO-RELATIVE-PATHS**: Cross-module references use relative paths from the referencing document to the target document, with an anchor fragment: `← [P-PREFIX-SLUG](../other-module/PRODUCT.md#P-PREFIX-SLUG)`.
  ← [P-ANCHORS-MONO-CROSS-REF](PRODUCT.md#P-ANCHORS-MONO-CROSS-REF)

- <a id="E-ANCHORS-MONO-PARTIAL-MODULES"></a>**E-ANCHORS-MONO-PARTIAL-MODULES**: Modules are not required to have all four documents. The audit reports missing documents as informational, not as errors.
  ← [P-ANCHORS-MONO-PARTIAL](PRODUCT.md#P-ANCHORS-MONO-PARTIAL)

---

## 7. Routing Logic

- <a id="E-ANCHORS-ROUTE-PARSE"></a>**E-ANCHORS-ROUTE-PARSE**: Argument parsing: no args → interactive mode, `setup` → setup mode (CWD), `setup <path>` → setup mode (given path), `check` → check mode (determine module path), `embed` → embed mode (CWD), `embed <path>` → embed mode (given path), anything else → print usage.
  ← [P-ANCHORS-ROUTE-ARGS](PRODUCT.md#P-ANCHORS-ROUTE-ARGS)

- <a id="E-ANCHORS-ROUTE-RECOMMEND"></a>**E-ANCHORS-ROUTE-RECOMMEND**: In interactive mode, if any `**/ANCHORS.md` exists in the repo, recommend Check first. If none exist, recommend Setup first. Show Embed as an option only if any module has `mode: detached`. Use `AskUserQuestion`.
  ← [P-ANCHORS-ROUTE-INTERACTIVE](PRODUCT.md#P-ANCHORS-ROUTE-INTERACTIVE)

---

## 8. CLI

- <a id="E-ANCHORS-CLI-SUBCOMMANDS"></a>**E-ANCHORS-CLI-SUBCOMMANDS**: The `anchors` CLI is a bash script that dispatches to subcommands: `setup`, `check`, `upgrade`. Running with no arguments or an unknown subcommand prints usage. The CLI bundles the skill files and templates alongside itself.
  ← [P-ANCHORS-CLI](PRODUCT.md#P-ANCHORS-CLI)

- <a id="E-ANCHORS-CLI-SETUP-FLOW"></a>**E-ANCHORS-CLI-SETUP-FLOW**: `anchors setup [--prefix PREFIX] [--mode MODE] [path]` scaffolds a document skeleton in the target directory. It checks prefix uniqueness, creates the target directory, and writes skeleton files (ANCHORS.md with frontmatter, plus empty PRODUCT.md, ERD.md, TESTING.md, DEPENDENCIES.md). Does not install the skill — that is `anchors install`.
  ← [P-ANCHORS-CLI-SETUP](PRODUCT.md#P-ANCHORS-CLI-SETUP)

- <a id="E-ANCHORS-CLI-AGENT-DETECT"></a>**E-ANCHORS-CLI-AGENT-DETECT**: Agent detection order: (1) `--agent` flag if provided, (2) check for `.claude/` directory → Claude Code, (3) check for `.goose/` directory → Goose, (4) check for `.agents/` directory → Amp/Codex, (5) check for `ai-rules/` directory → ai-rules. If no agent can be detected, prompt the user.
  ← [P-ANCHORS-CLI-AGENTS](PRODUCT.md#P-ANCHORS-CLI-AGENTS)

- <a id="E-ANCHORS-CLI-SKILL-TARGET-DIRS"></a>**E-ANCHORS-CLI-SKILL-TARGET-DIRS**: Skill installation target maps agent to project-level path: Claude Code → `.claude/skills/anchors/`, Goose → `.goose/skills/anchors/`, Amp → `.agents/skills/anchors/`, Codex → `.agents/skills/anchors/`, ai-rules → `ai-rules/skills/anchors/`. All installs are project-level only.
  ← [P-ANCHORS-CLI-AGENTS](PRODUCT.md#P-ANCHORS-CLI-AGENTS)

- <a id="E-ANCHORS-CLI-SKILL-REPLACE"></a>**E-ANCHORS-CLI-SKILL-REPLACE**: Before copying skill files, the CLI removes any existing file, symlink, or directory at the target path. It creates parent directories as needed and copies the skill directory.
  ← [P-ANCHORS-CLI-SETUP](PRODUCT.md#P-ANCHORS-CLI-SETUP)

- <a id="E-ANCHORS-CLI-INSTRUCTIONS-DIRECT"></a>**E-ANCHORS-CLI-INSTRUCTIONS-DIRECT**: For Claude Code, Amp, or Codex, the CLI appends an ANCHORS section to the agent instructions file at the repo root. Uses resolution logic: check for `AGENTS.md` and `CLAUDE.md`; if one symlinks to the other, update the real file; if both exist as separate files, update both; if only one exists, update it; if neither exists, create `AGENTS.md`. Skips if the file already contains an ANCHORS section.
  ← [P-ANCHORS-SETUP-AGENT-INSTRUCTIONS](PRODUCT.md#P-ANCHORS-SETUP-AGENT-INSTRUCTIONS)

- <a id="E-ANCHORS-CLI-INSTRUCTIONS-AIRULES"></a>**E-ANCHORS-CLI-INSTRUCTIONS-AIRULES**: For ai-rules, the CLI creates `ai-rules/anchors.md` containing the ANCHORS instructions. Skips if the file already exists. Runs `ai-rules generate` after both the skill copy and rule file creation.
  ← [P-ANCHORS-CLI-AIRULES](PRODUCT.md#P-ANCHORS-CLI-AIRULES)

- <a id="E-ANCHORS-CLI-AIRULES-CHECKS"></a>**E-ANCHORS-CLI-AIRULES-CHECKS**: Before proceeding with ai-rules setup, the CLI checks: (1) `ai-rules` command is available on PATH via `command -v`, (2) an `ai-rules/` directory exists in the current working directory. Each failed check exits with a descriptive error message and remediation instructions.
  ← [P-ANCHORS-CLI-AIRULES](PRODUCT.md#P-ANCHORS-CLI-AIRULES)

- <a id="E-ANCHORS-CLI-SCAFFOLD"></a>**E-ANCHORS-CLI-SCAFFOLD**: `anchors setup` creates the document skeleton: `ANCHORS.md` (with prefix and mode in frontmatter), `PRODUCT.md`, `ERD.md`, `TESTING.md`, and `DEPENDENCIES.md` (with structure from templates but no populated content). The `--prefix` flag is required; `--mode` defaults to embedded.
  ← [P-ANCHORS-CLI-SETUP](PRODUCT.md#P-ANCHORS-CLI-SETUP)

- <a id="E-ANCHORS-CLI-CHECK-STRUCTURAL"></a>**E-ANCHORS-CLI-CHECK-STRUCTURAL**: `anchors check <path>` requires a path to a directory containing `ANCHORS.md`. It performs all structural validation on that single module without an LLM: document presence, frontmatter validation, backlink checking, PRD coverage, ID extraction, open question scanning, and forward reference validation for detached modules. Outputs a structured report and exits with non-zero status if errors are found.
  ← [P-ANCHORS-CLI-CHECK](PRODUCT.md#P-ANCHORS-CLI-CHECK)

- <a id="E-ANCHORS-CLI-UPGRADE"></a>**E-ANCHORS-CLI-UPGRADE**: `anchors upgrade [--force]` detects the installed skill location (same agent detection as setup), compares the installed and bundled versions (see E-ANCHORS-VERSION-COMPARE), and if the upgrade should proceed, removes the existing skill directory and copies the current version bundled with the CLI. Prints the previous and new version.
  ← [P-ANCHORS-CLI-UPGRADE](PRODUCT.md#P-ANCHORS-CLI-UPGRADE)
  ← [P-ANCHORS-UPGRADE-VERSION](PRODUCT.md#P-ANCHORS-UPGRADE-VERSION)

---

## 9. Versioning

- <a id="E-ANCHORS-VERSION-FILE"></a>**E-ANCHORS-VERSION-FILE**: The `skill/` directory includes a `VERSION` file containing a semver string (e.g., `1.2.0`). During development it reads `0.0.0-dev`. The release workflow stamps the git tag into this file before building the tarball. When the skill is copied during `install` or `upgrade`, the VERSION file is included.
  ← [P-ANCHORS-UPGRADE-VERSION](PRODUCT.md#P-ANCHORS-UPGRADE-VERSION)

- <a id="E-ANCHORS-VERSION-COMPARE"></a>**E-ANCHORS-VERSION-COMPARE**: `anchors upgrade` reads the installed `{target_dir}/VERSION` and the bundled `${SKILL_SOURCE}/VERSION`, strips any pre-release suffix (text after `-`), and compares `major.minor.patch` numerically. If the installed version is strictly newer, abort with error showing both versions (exit 1). If versions are equal, print "already at version X" and exit 0. If the installed version is older or the installed VERSION file is missing (pre-versioning install), proceed with the upgrade. The `--force` flag bypasses the comparison entirely.
  ← [P-ANCHORS-UPGRADE-VERSION](PRODUCT.md#P-ANCHORS-UPGRADE-VERSION)

---

## 10. Detached Mode

- <a id="E-ANCHORS-EMBEDDED-DEFAULT"></a>**E-ANCHORS-EMBEDDED-DEFAULT**: When `ANCHORS.md` frontmatter contains no `mode` field (or any value other than `detached`), the module operates in embedded mode. All existing behavior applies: inline code tags, audit code search, init research against local files. This is the default and requires no additional configuration.
  ← [P-ANCHORS-MODE-EMBEDDED](PRODUCT.md#P-ANCHORS-MODE-EMBEDDED)

- <a id="E-ANCHORS-DETACHED-MODE-DETECTION"></a>**E-ANCHORS-DETACHED-MODE-DETECTION**: The `mode: detached` field in `ANCHORS.md` frontmatter triggers detached mode. This is an explicit behavioral flag — mode is not inferred from the presence or absence of other fields.
  ← [P-ANCHORS-MODE-DETACHED](PRODUCT.md#P-ANCHORS-MODE-DETACHED)

- <a id="E-ANCHORS-DETACHED-IN-REPO-FRONTMATTER"></a>**E-ANCHORS-DETACHED-IN-REPO-FRONTMATTER**: In-repo detached frontmatter: `prefix` (required), `mode: detached` (required), `path` (required — relative to the ANCHORS.md file, locates the target code directory). No `repo` or `ref` fields.
  ← [P-ANCHORS-DETACHED-IN-REPO](PRODUCT.md#P-ANCHORS-DETACHED-IN-REPO)

- <a id="E-ANCHORS-DETACHED-EXTERNAL-FRONTMATTER"></a>**E-ANCHORS-DETACHED-EXTERNAL-FRONTMATTER**: External detached frontmatter: `prefix` (required), `mode: detached` (required), `repo` (required — GitHub URL or local path to the target codebase), `ref` (branch/tag/SHA — defaults to `main`), `path` (subdirectory within the target repo root — defaults to `/`).
  ← [P-ANCHORS-DETACHED-EXTERNAL](PRODUCT.md#P-ANCHORS-DETACHED-EXTERNAL)

- <a id="E-ANCHORS-DETACHED-PATH-RESOLUTION"></a>**E-ANCHORS-DETACHED-PATH-RESOLUTION**: The `path` field resolves differently depending on whether `repo` is present. **In-repo** (no `repo`): `path` is relative to the ANCHORS.md file, like embedded mode's implicit scoping. **External** (with `repo`): `path` is relative to the target repo root. This means in-repo detached uses the same spatial conventions as embedded mode — the anchors directory and the code are nearby in the same filesystem.
  ← [P-ANCHORS-DETACHED-IN-REPO](PRODUCT.md#P-ANCHORS-DETACHED-IN-REPO)
  ← [P-ANCHORS-DETACHED-EXTERNAL](PRODUCT.md#P-ANCHORS-DETACHED-EXTERNAL)

- <a id="E-ANCHORS-DETACHED-TARGET-ACCESS"></a>**E-ANCHORS-DETACHED-TARGET-ACCESS**: Setup and check resolve the target codebase. **In-repo**: resolve `path` relative to ANCHORS.md and use the local filesystem directly. **External**: access the codebase at `repo` and `ref`, then scope to `path` (relative to repo root; defaults to `/`). External targets should be cached for the session to avoid redundant fetches.
  ← [P-ANCHORS-DETACHED-SETUP](PRODUCT.md#P-ANCHORS-DETACHED-SETUP)
  ← [P-ANCHORS-DETACHED-CHECK](PRODUCT.md#P-ANCHORS-DETACHED-CHECK)

- <a id="E-ANCHORS-DETACHED-FORWARD-REF-FORMAT"></a>**E-ANCHORS-DETACHED-FORWARD-REF-FORMAT**: Forward references use `→` followed by backtick-wrapped `file:symbol` entries (e.g., `` → `src/auth/session.go:NewSession`, `src/auth/middleware.go:ValidateToken` ``). Multiple refs are comma-separated on one line. File paths are relative to the resolved target directory (the `path` directory, however it was resolved).
  ← [P-ANCHORS-DETACHED-FORWARD-REFS](PRODUCT.md#P-ANCHORS-DETACHED-FORWARD-REFS)

- <a id="E-ANCHORS-DETACHED-FORWARD-REF-VALIDATION"></a>**E-ANCHORS-DETACHED-FORWARD-REF-VALIDATION**: Check resolves each `→` reference against the target codebase: the file must exist within the resolved target directory, and the symbol should be findable via grep in that file. Broken refs (missing file or missing symbol) are reported in the check gaps.
  ← [P-ANCHORS-DETACHED-CHECK](PRODUCT.md#P-ANCHORS-DETACHED-CHECK)

- <a id="E-ANCHORS-DETACHED-SETUP-RESEARCH"></a>**E-ANCHORS-DETACHED-SETUP-RESEARCH**: Setup resolves the target codebase and runs the same subagent research as embedded mode, scoped to the resolved target directory. Generated ERD.md includes `→` forward references to code locations discovered during research.
  ← [P-ANCHORS-DETACHED-SETUP](PRODUCT.md#P-ANCHORS-DETACHED-SETUP)

- <a id="E-ANCHORS-DETACHED-NO-INLINE-TAGS"></a>**E-ANCHORS-DETACHED-NO-INLINE-TAGS**: In detached mode, check does not search the target codebase for inline requirement tags (`P-*`, `E-*` in code comments). Traceability is purely via `→` forward references in the docs. The target codebase is never modified.
  ← [P-ANCHORS-DETACHED-NO-TOUCH](PRODUCT.md#P-ANCHORS-DETACHED-NO-TOUCH)

- <a id="E-ANCHORS-EMBED-PREREQ"></a>**E-ANCHORS-EMBED-PREREQ**: The embed action is only available for detached modules (`mode: detached` in ANCHORS.md). If invoked on an embedded module, report an error. The target code must be locally accessible. **In-repo**: resolve `path` relative to ANCHORS.md — the code is already local. **External**: if `repo` is a local path, use it directly; if `repo` is a remote URL, prompt for the local path.
  ← [P-ANCHORS-DETACHED-EMBED](PRODUCT.md#P-ANCHORS-DETACHED-EMBED)

- <a id="E-ANCHORS-EMBED-INLINE-TAGS"></a>**E-ANCHORS-EMBED-INLINE-TAGS**: For each `→` forward reference in ERD.md, the embed action locates the referenced file and symbol in the local code, and adds an inline requirement tag comment (e.g., `// E-AUTH-SESSION: ...`) to the function or symbol. Tags follow the standard code traceability format: one tag per function, augmenting existing comments.
  ← [P-ANCHORS-DETACHED-EMBED](PRODUCT.md#P-ANCHORS-DETACHED-EMBED)

- <a id="E-ANCHORS-EMBED-STRIP-FORWARD-REFS"></a>**E-ANCHORS-EMBED-STRIP-FORWARD-REFS**: After adding inline tags, the embed action removes all `→` lines from ERD.md. The `←` backlinks are preserved.
  ← [P-ANCHORS-DETACHED-EMBED](PRODUCT.md#P-ANCHORS-DETACHED-EMBED)

- <a id="E-ANCHORS-EMBED-STRIP-FRONTMATTER"></a>**E-ANCHORS-EMBED-STRIP-FRONTMATTER**: The embed action removes the `mode`, `repo`, `ref`, and `path` fields from ANCHORS.md frontmatter, leaving only `prefix`. This switches the module to embedded mode.
  ← [P-ANCHORS-DETACHED-EMBED](PRODUCT.md#P-ANCHORS-DETACHED-EMBED)

---

## Open Questions

(none)

## Resolved Questions

(none)
