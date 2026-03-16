#!/bin/bash
# Layer 1: Unit / Static — SKILL.md Consistency
# Verifies SKILL.md is structurally complete: routing table,
# check report format, framework concepts, and frontmatter.
# Validates TESTING.md §1.2
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "  [1.2.1] Routing table matches documented modes"
# E-ANCHORS-ROUTE-PARSE: SKILL.md must document all routing entries
assert_grep "SKILL.md documents interactive mode" 'no args.*Interactive|Interactive.*no args' "$SKILL_FILE"
assert_grep "SKILL.md documents setup mode" '/anchors setup' "$SKILL_FILE"
assert_grep "SKILL.md documents setup with path" 'setup.*path|setup <path>' "$SKILL_FILE"
assert_grep "SKILL.md documents check mode" '/anchors check' "$SKILL_FILE"
assert_grep "SKILL.md documents embed mode" '/anchors embed' "$SKILL_FILE"
assert_grep "SKILL.md documents embed with path" 'embed.*path' "$SKILL_FILE"

echo "  [1.2.2] Check report format includes all gap categories"
# E-ANCHORS-CHECK-REPORT-FORMAT: the example report must include every gap category
assert_grep "Report has Modules section" '### Modules' "$SKILL_FILE"
assert_grep "Report has Traceability section" '### Traceability' "$SKILL_FILE"
assert_grep "Report has Gaps section" '### Gaps' "$SKILL_FILE"
assert_grep "Report has Missing ERD Backlinks" 'Missing ERD Backlinks' "$SKILL_FILE"
assert_grep "Report has Uncovered Product Requirements" 'Uncovered Product Requirements' "$SKILL_FILE"
assert_grep "Report has Untraced Requirements" 'Untraced Requirements' "$SKILL_FILE"
assert_grep "Report has Requirements Without Test References" 'Without Test References' "$SKILL_FILE"
assert_grep "Report has Stale Code References" 'Stale Code References' "$SKILL_FILE"
assert_grep "Report has Open Questions" 'Open Questions' "$SKILL_FILE"
assert_grep "Report has DEPENDENCIES.md Boundary Issues" 'DEPENDENCIES.md Boundary' "$SKILL_FILE"

echo "  [1.2.4] SKILL.md covers key framework concepts"
# The framework section must describe these core concepts so the LLM has the
# full mental model when working in an ANCHORS repo.
assert_grep "SKILL.md describes truth hierarchy" 'Truth Hierarchy|truth hierarchy' "$SKILL_FILE"
assert_grep "SKILL.md describes disagreement rules" 'Disagreement|disagree' "$SKILL_FILE"
assert_grep "SKILL.md describes monorepo support" 'Monorepo|monorepo' "$SKILL_FILE"
assert_grep "SKILL.md describes code traceability" 'Code Traceability|code traceability|Code traceability' "$SKILL_FILE"
assert_grep "SKILL.md describes prefix uniqueness" 'prefix.*unique|unique.*prefix|Prefixes must be unique' "$SKILL_FILE"

echo "  [1.2.5] SKILL.md has valid frontmatter"
assert_grep "SKILL.md has name field" '^name:' "$SKILL_FILE"
assert_grep "SKILL.md has description field" '^description:' "$SKILL_FILE"

finish_tests
