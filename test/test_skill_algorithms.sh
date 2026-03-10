#!/bin/bash
# Layer 1: Static — SKILL.md algorithm completeness
# Tests: E-ANCHORS-HIERARCHY-ORDER, E-ANCHORS-DISAGREE-RULES,
#        E-ANCHORS-CODE-TAG-FORMAT, E-ANCHORS-INIT-PATH-RESOLUTION,
#        E-ANCHORS-INIT-CONFLICT-CHECK, E-ANCHORS-INIT-CLAUDE-MD-APPEND,
#        E-ANCHORS-INIT-DEFAULTS, E-ANCHORS-AUDIT-GLOB,
#        E-ANCHORS-ROUTE-RECOMMEND
# Validates that SKILL.md instructions contain all algorithm steps
# required by the ERD, so the LLM has complete guidance.
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

echo "  [1] E-ANCHORS-HIERARCHY-ORDER: Truth hierarchy is fully documented"
# Must show: PRODUCT.md > ERD.md > DEPENDENCIES.md, TESTING.md covers both, Tests > impl, Docs > tests
assert_grep "SKILL.md states PRODUCT.md is source of truth" 'PRODUCT\.md.*source of truth|source of truth.*PRODUCT\.md' "$SKILL_FILE"
assert_grep "SKILL.md states tests > implementation" 'tests.*truthier.*implementation|Tests.*implementation|implementation.*fix implementation' "$SKILL_FILE"
assert_grep "SKILL.md states documents > tests" 'documents.*truthier.*tests|documents are truthier' "$SKILL_FILE"

echo "  [2] E-ANCHORS-DISAGREE-RULES: All 5 disagreement rules present"
# Rule 1: impl vs tests → fix impl
assert_grep "Rule: impl vs tests" 'implementation.*tests.*fix implementation|Implementation vs tests.*implementation' "$SKILL_FILE"
# Rule 2: tests vs PRD/ERD → fix tests
assert_grep "Rule: tests vs docs" 'tests.*PRD.*fix tests|Tests vs.*documents.*fix tests|Tests vs PRD' "$SKILL_FILE"
# Rule 3: TESTING.md vs PRD/ERD → fix TESTING.md
assert_grep "Rule: TESTING.md vs PRD/ERD" 'TESTING\.md.*PRD.*fix TESTING|TESTING\.md vs PRD' "$SKILL_FILE"
# Rule 4: ERD vs PRD → fix ERD
assert_grep "Rule: ERD vs PRD" 'ERD.*PRD.*fix ERD|ERD vs PRD.*ERD' "$SKILL_FILE"
# Rule 5: DEPENDENCIES.md vs ERD → investigate
assert_grep "Rule: DEPS vs ERD" 'DEPENDENCIES.*ERD.*check|DEPENDENCIES\.md vs ERD' "$SKILL_FILE"

echo "  [3] E-ANCHORS-CODE-TAG-FORMAT: Code tagging convention documented"
assert_grep "SKILL.md shows single-line comment tag format" '// E-.*:' "$SKILL_FILE"
assert_grep "SKILL.md says one tag per function" 'One tag per function|one tag per function' "$SKILL_FILE"
assert_grep "SKILL.md says augment not replace" 'augment.*never replace|Augment.*never replace' "$SKILL_FILE"

echo "  [4] E-ANCHORS-INIT-PATH-RESOLUTION: 3-step path resolution"
# Step 1: explicit path → use it
assert_grep "Init: explicit path argument" 'path.*argument.*use it|path was given.*use it' "$SKILL_FILE"
# Step 2: no arg, no ANCHORS.md → use CWD
assert_grep "Init: no arg, clean dir → CWD" 'No.*use the current working directory|no path.*current working directory' "$SKILL_FILE"
# Step 3: no arg, has ANCHORS.md → ask
assert_grep "Init: no arg, has ANCHORS.md → ask" 'Yes.*AskUserQuestion|already has.*ANCHORS\.md.*ask' "$SKILL_FILE"

echo "  [5] E-ANCHORS-INIT-CONFLICT-CHECK: Existing file handling"
assert_grep "Init: check for existing files" 'already exist|Check.*any ANCHORS documents already exist' "$SKILL_FILE"
assert_grep "Init: skip or overwrite options" 'Skip existing|Overwrite all' "$SKILL_FILE"

echo "  [6] E-ANCHORS-INIT-CLAUDE-MD-APPEND: Agent instructions file logic"
assert_grep "Init: check for AGENTS.md and CLAUDE.md" 'AGENTS\.md.*CLAUDE\.md|Check for.*AGENTS' "$SKILL_FILE"
assert_grep "Init: symlink handling" 'symlink' "$SKILL_FILE"
assert_grep "Init: create AGENTS.md if neither exists" 'neither exists.*create.*AGENTS\.md|create.*AGENTS\.md' "$SKILL_FILE"

echo "  [7] E-ANCHORS-INIT-DEFAULTS: Default name and prefix suggestions"
assert_grep "Init: ask for project name" 'project.*name|module.*name|What is the project' "$SKILL_FILE"
assert_grep "Init: ask for prefix" 'prefix.*used|requirement ID prefix' "$SKILL_FILE"
assert_grep "Init: suggest directory name as default" 'directory name.*default|target directory name' "$SKILL_FILE"

echo "  [8] E-ANCHORS-AUDIT-GLOB: Module discovery with exclusions"
assert_grep "Audit: glob for ANCHORS.md" 'Glob.*ANCHORS\.md|\*\*/ANCHORS\.md|ANCHORS\.md' "$SKILL_FILE"
assert_grep "Audit: exclude node_modules" 'node_modules' "$SKILL_FILE"
assert_grep "Audit: exclude vendor" 'vendor' "$SKILL_FILE"
assert_grep "Audit: exclude .git" '\.git' "$SKILL_FILE"

echo "  [9] E-ANCHORS-ROUTE-RECOMMEND: Recommendation based on existing modules"
assert_grep "Route: recommend audit if modules exist" 'Audit.*Recommended|recommend.*Audit|exist.*Audit first' "$SKILL_FILE"
assert_grep "Route: recommend init if no modules" 'Init.*Recommended|recommend.*Init|no.*Init first' "$SKILL_FILE"

finish_tests
