---
scope: External dependencies — tools and services that must be present in the environment because the system cannot supply them itself.
see-also:
  - ERD.md — engineering requirements, including managed toolchains that eliminate would-be dependencies.
  - PRODUCT.md — product requirements that drive deployment modes.
---

# ANCHORS: External Dependencies

### D-DEP-BASH: Bash
- **Used by:** `anchors` CLI
- **Where it runs:** Developer machines (macOS, Linux)
- **Why external:** The CLI is a bash script (`#!/bin/bash`) using bash-specific constructs (arrays, `[[ ]]`, `(( ))`, `<<<`). The system ships the script but cannot supply the shell itself.

### D-DEP-AIRULES: ai-rules CLI
- **Used by:** `anchors install` and `anchors upgrade` when `--agent airules`
- **Where it runs:** Developer machines with ai-rules projects
- **Why external:** The CLI calls `ai-rules generate` to integrate the skill into the ai-rules framework. The `anchors` CLI validates its presence and errors with installation instructions if absent.
