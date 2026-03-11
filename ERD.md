---
scope: Engineering requirements — technical design, interfaces, and implementation constraints. Derived from product requirements.
see-also:
  - PRODUCT.md — product requirements that drive the technical decisions in this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies that the system cannot supply itself.
---

# ANCHORS: Engineering Requirements

This document defines the technical requirements for the ANCHORS skill. These are derived from the [product requirements](PRODUCT.md).

ANCHORS is implemented entirely as a Claude Code skill — a markdown instruction file (`SKILL.md`) plus templates. There is no compiled code. The "implementation" is the LLM following the instructions in `SKILL.md`. This shapes the ERD: requirements describe document formats, algorithms the LLM must follow, and file system conventions rather than traditional code interfaces.

---

## 1. Document Format

- <a id="E-ANCHORS-MARKER-FORMAT"></a>**E-ANCHORS-MARKER-FORMAT**: `ANCHORS.md` must contain YAML frontmatter with a `prefix` field. The prefix value is an uppercase string used to scope all requirement IDs in the module.
  ← [P-ANCHORS-PREFIX](PRODUCT.md#P-ANCHORS-PREFIX)

- <a id="E-ANCHORS-DOC-LOCATIONS"></a>**E-ANCHORS-DOC-LOCATIONS**: The four documents (`PRODUCT.md`, `ERD.md`, `TESTING.md`, `DEPENDENCIES.md`) must be siblings of `ANCHORS.md` in the same directory.
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

## 4. Init Algorithm

- <a id="E-ANCHORS-INIT-PATH-RESOLUTION"></a>**E-ANCHORS-INIT-PATH-RESOLUTION**: Path resolution follows: (1) explicit path argument → use it, (2) no argument and CWD has no `ANCHORS.md` → use CWD, (3) no argument and CWD has `ANCHORS.md` → prompt user with suggested subdirectories.
  ← [P-ANCHORS-INIT-PATH](PRODUCT.md#P-ANCHORS-INIT-PATH)

- <a id="E-ANCHORS-INIT-CONFLICT-CHECK"></a>**E-ANCHORS-INIT-CONFLICT-CHECK**: Before writing, glob the target directory for all five filenames. If any exist, prompt: "Skip existing" (only create missing) or "Overwrite all" (replace everything).
  ← [P-ANCHORS-INIT-EXISTING](PRODUCT.md#P-ANCHORS-INIT-EXISTING)

- <a id="E-ANCHORS-INIT-TEMPLATE-COPY"></a>**E-ANCHORS-INIT-TEMPLATE-COPY**: Templates are read from the `templates/` directory relative to this skill's installed location (sibling of `SKILL.md`). The `[Project Name]` placeholder in each template is replaced with the user-provided name. `ANCHORS.md` is generated (not templated) with the chosen prefix in frontmatter.
  ← [P-ANCHORS-INIT-SCAFFOLD](PRODUCT.md#P-ANCHORS-INIT-SCAFFOLD)

- <a id="E-ANCHORS-INIT-DEFAULTS"></a>**E-ANCHORS-INIT-DEFAULTS**: The skill suggests the target directory name as the default project name and an uppercase abbreviation as the default prefix (e.g., directory `auth-service` → name "auth-service", prefix "AUTH").
  ← [P-ANCHORS-INIT-PREFIX](PRODUCT.md#P-ANCHORS-INIT-PREFIX)

- <a id="E-ANCHORS-INIT-CLAUDE-MD-APPEND"></a>**E-ANCHORS-INIT-CLAUDE-MD-APPEND**: When no parent directory (up to repo root) contains `ANCHORS.md`, append a minimal ANCHORS section to the agent instructions file at the repo root. Resolution: check for `AGENTS.md` and `CLAUDE.md`; if one symlinks to the other, update the real file; if both exist as separate files, update both; if only one exists, update it; if neither exists, create `AGENTS.md`. The section instructs the agent to load the anchors skill — it does not duplicate the framework rules already in the skill. If an `ai-rules/` directory exists at the repo root, skip this step entirely — ai-rules manages those files via `ai-rules generate`.
  ← [P-ANCHORS-INIT-CLAUDE-MD](PRODUCT.md#P-ANCHORS-INIT-CLAUDE-MD)

- <a id="E-ANCHORS-INIT-PREFIX-UNIQUE"></a>**E-ANCHORS-INIT-PREFIX-UNIQUE**: After the user chooses a prefix, glob for all `**/ANCHORS.md` files in the repo (excluding `node_modules`, `vendor`, `.git`, build output), read their `prefix` fields, and reject duplicates.
  ← [P-ANCHORS-INIT-UNIQUE-PREFIX](PRODUCT.md#P-ANCHORS-INIT-UNIQUE-PREFIX)

---

## 5. Audit Algorithm

- <a id="E-ANCHORS-AUDIT-GLOB"></a>**E-ANCHORS-AUDIT-GLOB**: Module discovery globs for `**/ANCHORS.md` excluding `node_modules`, `vendor`, `.git`, and build output directories. Each file's YAML frontmatter is parsed for the `prefix` field.
  ← [P-ANCHORS-AUDIT-DISCOVER](PRODUCT.md#P-ANCHORS-AUDIT-DISCOVER)

- <a id="E-ANCHORS-AUDIT-PREFIX-COLLISION"></a>**E-ANCHORS-AUDIT-PREFIX-COLLISION**: If two modules share the same prefix, the audit reports a prefix collision as an error.
  ← [P-ANCHORS-AUDIT-DISCOVER](PRODUCT.md#P-ANCHORS-AUDIT-DISCOVER)

- <a id="E-ANCHORS-AUDIT-DOC-PRESENCE"></a>**E-ANCHORS-AUDIT-DOC-PRESENCE**: For each module directory, check for the existence of `PRODUCT.md`, `ERD.md`, `TESTING.md`, and `DEPENDENCIES.md`. Report as `N/4 documents`.
  ← [P-ANCHORS-AUDIT-DOCS](PRODUCT.md#P-ANCHORS-AUDIT-DOCS)

- <a id="E-ANCHORS-AUDIT-ID-EXTRACT"></a>**E-ANCHORS-AUDIT-ID-EXTRACT**: Extract requirement IDs by scanning PRODUCT.md for `P-{PREFIX}-*` patterns, ERD.md for `E-{PREFIX}-*` patterns, and DEPENDENCIES.md for `D-DEP-*` patterns. Use the HTML anchor `<a id="...">` as the canonical source.
  ← [P-ANCHORS-AUDIT-BACKLINKS](PRODUCT.md#P-ANCHORS-AUDIT-BACKLINKS)

- <a id="E-ANCHORS-AUDIT-BACKLINK-CHECK"></a>**E-ANCHORS-AUDIT-BACKLINK-CHECK**: For each `E-*` requirement, search for a `←` marker followed by a `[P-*]` link on the same or next line. Report any `E-*` without a backlink.
  ← [P-ANCHORS-AUDIT-BACKLINKS](PRODUCT.md#P-ANCHORS-AUDIT-BACKLINKS)

- <a id="E-ANCHORS-AUDIT-PRD-COVERAGE"></a>**E-ANCHORS-AUDIT-PRD-COVERAGE**: Build a set of all `P-*` IDs from PRODUCT.md. For each, check if any `E-*` requirement's backlink references it. Report `P-*` IDs with zero `E-*` coverage.
  ← [P-ANCHORS-AUDIT-COVERAGE](PRODUCT.md#P-ANCHORS-AUDIT-COVERAGE)

- <a id="E-ANCHORS-AUDIT-CODE-SEARCH"></a>**E-ANCHORS-AUDIT-CODE-SEARCH**: Search all non-excluded source files for strings matching known `P-*`, `E-*`, and `D-DEP-*` IDs. Classify each file as implementation or test based on path conventions (e.g., `*_test.go`, `*.test.ts`, `test_*.py`, files under `__tests__/`).
  ← [P-ANCHORS-AUDIT-CODE-TRACE](PRODUCT.md#P-ANCHORS-AUDIT-CODE-TRACE)

- <a id="E-ANCHORS-AUDIT-STALE-REFS"></a>**E-ANCHORS-AUDIT-STALE-REFS**: Any requirement ID found in code that doesn't match an ID in any ANCHORS document is reported as a stale reference.
  ← [P-ANCHORS-AUDIT-CODE-TRACE](PRODUCT.md#P-ANCHORS-AUDIT-CODE-TRACE)

- <a id="E-ANCHORS-AUDIT-TEST-GAP"></a>**E-ANCHORS-AUDIT-TEST-GAP**: Requirements that appear in implementation files but not in test files are reported as "in code but not in tests."
  ← [P-ANCHORS-AUDIT-TEST-TRACE](PRODUCT.md#P-ANCHORS-AUDIT-TEST-TRACE)

- <a id="E-ANCHORS-AUDIT-CROSS-RESOLVE"></a>**E-ANCHORS-AUDIT-CROSS-RESOLVE**: For backlinks containing relative paths (e.g., `../checkout/PRODUCT.md#P-*`), resolve the path relative to the current module directory and verify the target file exists and contains the referenced anchor ID.
  ← [P-ANCHORS-AUDIT-CROSS-MODULE](PRODUCT.md#P-ANCHORS-AUDIT-CROSS-MODULE)

- <a id="E-ANCHORS-AUDIT-OPEN-SCAN"></a>**E-ANCHORS-AUDIT-OPEN-SCAN**: Scan all ANCHORS documents for `OPEN-*` strings not preceded by `~~` (which indicates resolved). Report each with its source file.
  ← [P-ANCHORS-AUDIT-OPEN](PRODUCT.md#P-ANCHORS-AUDIT-OPEN)

- <a id="E-ANCHORS-AUDIT-REPORT-FORMAT"></a>**E-ANCHORS-AUDIT-REPORT-FORMAT**: The audit report is structured markdown with sections: Modules (list with prefix, doc count), Traceability (aggregate stats), and Gaps (categorized: missing backlinks, uncovered PRD, untraced requirements, missing test refs, stale refs, open questions, dependency boundary issues).
  ← [P-ANCHORS-AUDIT-REPORT](PRODUCT.md#P-ANCHORS-AUDIT-REPORT)

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

- <a id="E-ANCHORS-ROUTE-PARSE"></a>**E-ANCHORS-ROUTE-PARSE**: Argument parsing: no args → interactive mode, `init` → init mode (CWD), `init <path>` → init mode (given path), `audit` → audit mode, anything else → print usage.
  ← [P-ANCHORS-ROUTE-ARGS](PRODUCT.md#P-ANCHORS-ROUTE-ARGS)

- <a id="E-ANCHORS-ROUTE-RECOMMEND"></a>**E-ANCHORS-ROUTE-RECOMMEND**: In interactive mode, if any `**/ANCHORS.md` exists in the repo, recommend Audit first. If none exist, recommend Init first. Use `AskUserQuestion` with two options.
  ← [P-ANCHORS-ROUTE-INTERACTIVE](PRODUCT.md#P-ANCHORS-ROUTE-INTERACTIVE)

---

## 8. Installer

- <a id="E-ANCHORS-INSTALL-AGENT-MENU"></a>**E-ANCHORS-INSTALL-AGENT-MENU**: The installer presents a numbered menu of supported agents: (1) Claude Code, (2) Amp, (3) Codex, (4) ai-rules. Invalid selections exit with an error.
  ← [P-ANCHORS-INSTALL-AGENTS](PRODUCT.md#P-ANCHORS-INSTALL-AGENTS)

- <a id="E-ANCHORS-INSTALL-SCOPE-MENU"></a>**E-ANCHORS-INSTALL-SCOPE-MENU**: For Claude Code, Amp, and Codex, the installer prompts for scope: (1) User-level, (2) Project-level. The ai-rules path skips this prompt (always project-level).
  ← [P-ANCHORS-INSTALL-SCOPE](PRODUCT.md#P-ANCHORS-INSTALL-SCOPE)

- <a id="E-ANCHORS-INSTALL-TARGET-DIRS"></a>**E-ANCHORS-INSTALL-TARGET-DIRS**: Target directory resolution maps agent and scope to a path: Claude Code user → `~/.claude/skills/anchors/`, Claude Code project → `.claude/skills/anchors/`, Amp user → `~/.config/agents/skills/anchors/`, Amp project → `.agents/skills/anchors/`, Codex user → `~/.codex/skills/anchors/`, Codex project → `.agents/skills/anchors/`.
  ← [P-ANCHORS-INSTALL-COPY](PRODUCT.md#P-ANCHORS-INSTALL-COPY)

- <a id="E-ANCHORS-INSTALL-REPLACE"></a>**E-ANCHORS-INSTALL-REPLACE**: Before copying, the installer removes any existing file, symlink, or directory at the target path. It creates parent directories as needed and copies the entire `skill/` directory.
  ← [P-ANCHORS-INSTALL-COPY](PRODUCT.md#P-ANCHORS-INSTALL-COPY)

- <a id="E-ANCHORS-INSTALL-AIRULES-PATH"></a>**E-ANCHORS-INSTALL-AIRULES-PATH**: For ai-rules, the target directory is `ai-rules/skills/anchors/`. After copying the skill, the installer runs `ai-rules generate` to regenerate all agent-specific output files from the ai-rules source tree.
  ← [P-ANCHORS-INSTALL-AIRULES](PRODUCT.md#P-ANCHORS-INSTALL-AIRULES)

- <a id="E-ANCHORS-INSTALL-AIRULES-CHECKS"></a>**E-ANCHORS-INSTALL-AIRULES-CHECKS**: Before proceeding with ai-rules installation, the installer checks: (1) `ai-rules` command is available on PATH via `command -v`, (2) an `ai-rules/` directory exists in the current working directory. Each failed check exits with a descriptive error message and remediation instructions.
  ← [P-ANCHORS-INSTALL-AIRULES-PREREQS](PRODUCT.md#P-ANCHORS-INSTALL-AIRULES-PREREQS)

- <a id="E-ANCHORS-INSTALL-INSTRUCTIONS-DIRECT"></a>**E-ANCHORS-INSTALL-INSTRUCTIONS-DIRECT**: For project-level installs of Claude Code, Amp, or Codex, the installer appends an ANCHORS section to the agent instructions file at the repo root. Uses the same resolution logic as init step 6: check for `AGENTS.md` and `CLAUDE.md`; if one symlinks to the other, update the real file; if both exist as separate files, update both; if only one exists, update it; if neither exists, create `AGENTS.md`. Skips if the file already contains an ANCHORS section.
  ← [P-ANCHORS-INSTALL-AGENT-INSTRUCTIONS](PRODUCT.md#P-ANCHORS-INSTALL-AGENT-INSTRUCTIONS)

- <a id="E-ANCHORS-INSTALL-INSTRUCTIONS-AIRULES"></a>**E-ANCHORS-INSTALL-INSTRUCTIONS-AIRULES**: For ai-rules installs, the installer creates `ai-rules/anchors.md` containing the ANCHORS instructions (telling the agent to load the anchors skill before making changes). Skips if the file already exists. Runs `ai-rules generate` after both the skill copy and rule file creation.
  ← [P-ANCHORS-INSTALL-AGENT-INSTRUCTIONS](PRODUCT.md#P-ANCHORS-INSTALL-AGENT-INSTRUCTIONS)

---

## Open Questions

(none)

## Resolved Questions
