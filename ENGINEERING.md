---
scope: Engineering architecture — rules, principles, and constraints that govern how the system achieves the product requirements. Organized by cross-cutting concern.
see-also:
  - PRODUCT.md — product requirements that engineering rules must not contradict.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies that the system cannot supply itself.
---

# ANCHORS: Engineering Architecture

ANCHORS consists of two components: an `anchors` CLI (bash script with subcommands) for deterministic operations, and a skill (`SKILL.md` plus templates) for LLM-powered operations. The CLI handles scaffolding, structural linting, and skill file management. The skill handles codebase research, content population, semantic analysis, and interactive workflows. The skill invokes the CLI for its deterministic steps.

---

## Document Integrity

- <a id="E-ANCHORS-DOC-INTEGRITY"></a>**E-ANCHORS-DOC-INTEGRITY**: Every ANCHORS module is a self-contained directory. An `ANCHORS.md` marker file with a `prefix` field in its YAML frontmatter is the only required configuration. The four documents (`PRODUCT.md`, `ENGINEERING.md`, `TESTING.md`, `DEPENDENCIES.md`) are siblings of the marker. Not every module requires all four — partial document sets are valid. Each document includes YAML frontmatter with `scope` and `see-also` fields for self-documentation.

  **Why:** Keeping configuration in one place (ANCHORS.md frontmatter) means discovery, validation, and tooling all read the same source. If config spread across files, tools would need to reconcile inconsistencies. Self-contained directories mean modules can be moved, copied, or deleted without breaking the framework.

  ← [P-ANCHORS-DOC-SET](PRODUCT.md#P-ANCHORS-DOC-SET)
  ← [P-ANCHORS-PREFIX](PRODUCT.md#P-ANCHORS-PREFIX)

---

## Canonical IDs

- <a id="E-ANCHORS-CANONICAL-IDS"></a>**E-ANCHORS-CANONICAL-IDS**: Every requirement has one canonical ID declared exactly once via HTML anchor (`<a id="...">`). Product IDs use `P-{PREFIX}-{SLUG}`, engineering IDs use `E-{PREFIX}-{SLUG}`, dependency IDs use `D-DEP-{SLUG}`. Every `E-*` entry must include a `← [P-*](PRODUCT.md#P-*)` backlink. Code traceability tags are single-line comments containing a requirement ID (e.g., `// E-PREFIX-SLUG: description`), placed once per function, augmenting existing comments.

  **Why:** A single canonical declaration per ID means grep finds exactly one definition. Prefix scoping prevents collisions across modules. HTML anchors make IDs linkable in any markdown renderer. Backlinks create a machine-verifiable dependency chain from engineering decisions to product requirements.

  ← [P-ANCHORS-REQ-IDS](PRODUCT.md#P-ANCHORS-REQ-IDS)
  ← [P-ANCHORS-TRACEABILITY](PRODUCT.md#P-ANCHORS-TRACEABILITY)
  ← [P-ANCHORS-PREFIX](PRODUCT.md#P-ANCHORS-PREFIX)

---

## Deterministic Resolution

- <a id="E-ANCHORS-DETERMINISTIC-RESOLUTION"></a>**E-ANCHORS-DETERMINISTIC-RESOLUTION**: Documents form a strict authority hierarchy: PRODUCT.md > ENGINEERING.md > DEPENDENCIES.md, with TESTING.md covering both PRODUCT.md and ENGINEERING.md. Tests are truthier than implementation; documents are truthier than tests. Disagreements resolve deterministically toward the higher authority: implementation yields to tests, tests yield to documents, ENGINEERING.md yields to PRODUCT.md, and DEPENDENCIES.md vs ENGINEERING.md requires investigation.

  **Why:** Ambiguity about which artifact is "right" is the root cause of requirements drift. A deterministic rule means agents and humans resolve conflicts the same way every time, without requiring escalation or judgment calls.

  ← [P-ANCHORS-TRUTH-HIERARCHY](PRODUCT.md#P-ANCHORS-TRUTH-HIERARCHY)
  ← [P-ANCHORS-DISAGREEMENT](PRODUCT.md#P-ANCHORS-DISAGREEMENT)

---

## CLI vs. Skill Boundary

- <a id="E-ANCHORS-CLI-SKILL-BOUNDARY"></a>**E-ANCHORS-CLI-SKILL-BOUNDARY**: Deterministic operations live in the CLI: scaffolding document skeletons (`setup`), structural linting (`check`), skill file management (`install`, `upgrade`). Non-deterministic operations live in the skill: codebase research, content population, semantic analysis, interactive workflows. The skill invokes the CLI for its deterministic steps. The CLI runs without an LLM and exits with non-zero status on errors, making it suitable for CI. The check report is structured markdown with sections for modules, traceability statistics, and categorized gaps.

  **Why:** The CLI is fast, testable, and CI-friendly because it has no LLM dependency. The skill handles tasks that require judgment. Mixing the two would make both harder to test and harder to trust. A clear boundary means each component can evolve independently.

  ← [P-ANCHORS-CLI](PRODUCT.md#P-ANCHORS-CLI)
  ← [P-ANCHORS-CLI-SETUP](PRODUCT.md#P-ANCHORS-CLI-SETUP)
  ← [P-ANCHORS-CLI-CHECK](PRODUCT.md#P-ANCHORS-CLI-CHECK)
  ← [P-ANCHORS-CLI-UPGRADE](PRODUCT.md#P-ANCHORS-CLI-UPGRADE)
  ← [P-ANCHORS-SETUP-SCAFFOLD](PRODUCT.md#P-ANCHORS-SETUP-SCAFFOLD)
  ← [P-ANCHORS-CHECK-REPORT](PRODUCT.md#P-ANCHORS-CHECK-REPORT)

---

## Agent Agnosticism

- <a id="E-ANCHORS-AGENT-AGNOSTIC"></a>**E-ANCHORS-AGENT-AGNOSTIC**: The CLI detects the target agent (via `--agent` flag or by probing for `.claude/`, `.goose/`, `.agents/`, `ai-rules/` directories) and maps skill files to agent-specific paths. Framework rules live in the skill file, not in agent instruction files — agent instructions contain only a minimal pointer to load the skill. The documents themselves are plain markdown with no agent-specific syntax. For ai-rules, the CLI creates a rule file and runs `ai-rules generate`, gating on the `ai-rules` CLI and directory being present.

  **Why:** The framework should work with any agent that can read markdown. Agent-specific integration is limited to skill installation paths and a minimal instruction pointer. Switching agents doesn't require rewriting documents or learning a different workflow.

  ← [P-ANCHORS-CLI-AGENTS](PRODUCT.md#P-ANCHORS-CLI-AGENTS)
  ← [P-ANCHORS-CLI-AIRULES](PRODUCT.md#P-ANCHORS-CLI-AIRULES)
  ← [P-ANCHORS-INSTALL](PRODUCT.md#P-ANCHORS-INSTALL)
  ← [P-ANCHORS-SETUP-AGENT-INSTRUCTIONS](PRODUCT.md#P-ANCHORS-SETUP-AGENT-INSTRUCTIONS)

---

## Idempotent Operations

- <a id="E-ANCHORS-IDEMPOTENT-OPS"></a>**E-ANCHORS-IDEMPOTENT-OPS**: Setup, install, and upgrade are safe to re-run. Setup detects existing files and offers skip/overwrite. Install detects an existing skill and skips. Upgrade removes the existing skill directory and copies the current version. Prefix uniqueness is enforced at setup time by globbing all `ANCHORS.md` files in the repo and rejecting duplicates. Agent instructions are appended only if no ANCHORS section already exists.

  **Why:** Users shouldn't fear re-running commands. Idempotency means recovery from partial failures is "just run it again." Prefix uniqueness at setup time prevents cross-module ID collisions that would be expensive to diagnose later.

  ← [P-ANCHORS-INSTALL](PRODUCT.md#P-ANCHORS-INSTALL)
  ← [P-ANCHORS-SETUP-EXISTING](PRODUCT.md#P-ANCHORS-SETUP-EXISTING)
  ← [P-ANCHORS-SETUP-UNIQUE-PREFIX](PRODUCT.md#P-ANCHORS-SETUP-UNIQUE-PREFIX)
  ← [P-ANCHORS-CLI-UPGRADE](PRODUCT.md#P-ANCHORS-CLI-UPGRADE)

---

## Research and Context Protection

- <a id="E-ANCHORS-RESEARCH-PROTECTION"></a>**E-ANCHORS-RESEARCH-PROTECTION**: Setup researches the target codebase exhaustively but returns structured findings (functional areas, architectural patterns, external dependencies), not raw source code. Parallel subagents scope research to avoid context bloat. Tests are weighted heavily — tested behaviors are stronger requirement signals than implementation details. The skill suggests sensible defaults for project name and prefix derived from the directory name. A full setup should produce a document set that passes an immediate check.

  **Why:** LLM context is a finite resource. Raw source code wastes tokens and degrades output quality. Structured findings give the LLM what it needs to write good requirements without context bloat. Test-weighted research produces requirements that reflect what the system actually does, not just what the code happens to contain.

  ← [P-ANCHORS-SETUP-SCAFFOLD](PRODUCT.md#P-ANCHORS-SETUP-SCAFFOLD)
  ← [P-ANCHORS-SETUP-PREFIX](PRODUCT.md#P-ANCHORS-SETUP-PREFIX)

---

## Check Completeness

- <a id="E-ANCHORS-CHECK-COMPLETENESS"></a>**E-ANCHORS-CHECK-COMPLETENESS**: The check workflow discovers all modules by globbing for `ANCHORS.md` (excluding `node_modules`, `vendor`, `.git`, build output), validates every structural property — document presence, backlinks, PRD coverage, code traceability, test traceability, cross-module reference resolution, open questions, prefix collisions — and produces a single structured report. Stale code references (IDs not in any document) and test gaps (IDs in code but not tests) are surfaced explicitly. The CLI handles structural checks; the skill adds semantic analysis on top.

  **Why:** A partial check gives false confidence. If the check misses a gap category, that gap type silently accumulates. The structured report makes gaps visible and actionable — categorized so teams know which type of work to prioritize.

  ← [P-ANCHORS-CHECK-DISCOVER](PRODUCT.md#P-ANCHORS-CHECK-DISCOVER)
  ← [P-ANCHORS-CHECK-DOCS](PRODUCT.md#P-ANCHORS-CHECK-DOCS)
  ← [P-ANCHORS-CHECK-BACKLINKS](PRODUCT.md#P-ANCHORS-CHECK-BACKLINKS)
  ← [P-ANCHORS-CHECK-COVERAGE](PRODUCT.md#P-ANCHORS-CHECK-COVERAGE)
  ← [P-ANCHORS-CHECK-CODE-TRACE](PRODUCT.md#P-ANCHORS-CHECK-CODE-TRACE)
  ← [P-ANCHORS-CHECK-TEST-TRACE](PRODUCT.md#P-ANCHORS-CHECK-TEST-TRACE)
  ← [P-ANCHORS-CHECK-CROSS-MODULE](PRODUCT.md#P-ANCHORS-CHECK-CROSS-MODULE)
  ← [P-ANCHORS-CHECK-OPEN](PRODUCT.md#P-ANCHORS-CHECK-OPEN)
  ← [P-ANCHORS-CHECK-REPORT](PRODUCT.md#P-ANCHORS-CHECK-REPORT)

---

## Module Independence

- <a id="E-ANCHORS-MODULE-INDEPENDENCE"></a>**E-ANCHORS-MODULE-INDEPENDENCE**: Any directory with an `ANCHORS.md` marker containing a `prefix` field is a module, regardless of nesting depth. Modules cross-reference each other via relative paths with anchor fragments (e.g., `← [P-PREFIX-SLUG](../other-module/PRODUCT.md#P-PREFIX-SLUG)`). Modules are not required to have all four documents — the check reports missing documents as informational, not as errors.

  **Why:** Modules must be self-contained so they can be moved, copied, or deleted without breaking the framework. Relative paths keep cross-references valid across repo moves. Partial document sets prevent forcing infrastructure modules to carry unnecessary files.

  ← [P-ANCHORS-MONO-NESTING](PRODUCT.md#P-ANCHORS-MONO-NESTING)
  ← [P-ANCHORS-MONO-CROSS-REF](PRODUCT.md#P-ANCHORS-MONO-CROSS-REF)
  ← [P-ANCHORS-MONO-PARTIAL](PRODUCT.md#P-ANCHORS-MONO-PARTIAL)

---

## Smart Routing

- <a id="E-ANCHORS-SMART-ROUTING"></a>**E-ANCHORS-SMART-ROUTING**: The skill infers the most useful action from context: recommend check if modules exist, setup if none do, embed only if detached modules exist. Explicit arguments (`setup`, `setup <path>`, `check`, `embed`, `embed <path>`) bypass inference entirely. Path resolution follows a 3-step algorithm: explicit path → use it; no argument and clean CWD → use CWD; no argument and CWD has `ANCHORS.md` → prompt the user.

  **Why:** Users shouldn't need to memorize subcommand names for the common case. Context-aware defaults reduce friction. Explicit arguments remain available for scripting, CI, and when the inference would be wrong.

  ← [P-ANCHORS-ROUTE-INTERACTIVE](PRODUCT.md#P-ANCHORS-ROUTE-INTERACTIVE)
  ← [P-ANCHORS-ROUTE-ARGS](PRODUCT.md#P-ANCHORS-ROUTE-ARGS)
  ← [P-ANCHORS-SETUP-PATH](PRODUCT.md#P-ANCHORS-SETUP-PATH)
  ← [P-ANCHORS-SETUP-PREFIX](PRODUCT.md#P-ANCHORS-SETUP-PREFIX)

---

## Detached Isolation

- <a id="E-ANCHORS-DETACHED-ISOLATION"></a>**E-ANCHORS-DETACHED-ISOLATION**: Detached mode keeps documents separate from the code they describe. Mode is set explicitly via `mode: detached` in ANCHORS.md frontmatter — never inferred from the absence of other fields. In-repo detached uses a `path` field relative to ANCHORS.md; external detached adds `repo` and `ref` fields with `path` relative to the repo root. Traceability is via `→` forward references in ENGINEERING.md (backtick-wrapped `file:symbol` entries, comma-separated), not inline tags in code. The target codebase is never modified.

  **Why:** You can't always modify the target codebase (third-party libraries, code owned by another team, compliance constraints). Detached mode gives structured traceability without requiring write access. Explicit mode prevents accidental behavior — a missing field shouldn't silently change how the framework operates.

  ← [P-ANCHORS-MODE-EMBEDDED](PRODUCT.md#P-ANCHORS-MODE-EMBEDDED)
  ← [P-ANCHORS-MODE-DETACHED](PRODUCT.md#P-ANCHORS-MODE-DETACHED)
  ← [P-ANCHORS-DETACHED-IN-REPO](PRODUCT.md#P-ANCHORS-DETACHED-IN-REPO)
  ← [P-ANCHORS-DETACHED-EXTERNAL](PRODUCT.md#P-ANCHORS-DETACHED-EXTERNAL)
  ← [P-ANCHORS-DETACHED-NO-TOUCH](PRODUCT.md#P-ANCHORS-DETACHED-NO-TOUCH)
  ← [P-ANCHORS-DETACHED-FORWARD-REFS](PRODUCT.md#P-ANCHORS-DETACHED-FORWARD-REFS)

---

## Detached Lifecycle

- <a id="E-ANCHORS-DETACHED-LIFECYCLE"></a>**E-ANCHORS-DETACHED-LIFECYCLE**: Detached modules follow the same setup-check-embed lifecycle as embedded modules. Setup resolves the target codebase and generates ENGINEERING.md with `→` forward references to discovered code locations. Check resolves forward references against the target — the file must exist and the symbol must be findable via grep. Embed converts a detached module to embedded: it adds inline requirement tags at each `→` location, removes the `→` lines from ENGINEERING.md, and strips `mode`/`repo`/`ref`/`path` from ANCHORS.md frontmatter. The target code must be locally accessible for embed.

  **Why:** The lifecycle is the same regardless of mode — only the traceability mechanism differs (forward refs vs inline tags). Users can start detached (low commitment) and convert to embedded (full commitment) when ready, without learning a different workflow.

  ← [P-ANCHORS-DETACHED-SETUP](PRODUCT.md#P-ANCHORS-DETACHED-SETUP)
  ← [P-ANCHORS-DETACHED-CHECK](PRODUCT.md#P-ANCHORS-DETACHED-CHECK)
  ← [P-ANCHORS-DETACHED-EMBED](PRODUCT.md#P-ANCHORS-DETACHED-EMBED)

---

## Open Questions

(none)

## Resolved Questions

(none)
