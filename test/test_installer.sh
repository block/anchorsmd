#!/bin/bash
# Test: Installer structure and content
# Covers: E-ANCHORS-INSTALL-AGENT-MENU, E-ANCHORS-INSTALL-SCOPE-MENU,
#         E-ANCHORS-INSTALL-TARGET-DIRS, E-ANCHORS-INSTALL-AIRULES-PATH,
#         E-ANCHORS-INSTALL-AIRULES-CHECKS, E-ANCHORS-INSTALL-REPLACE,
#         E-ANCHORS-INSTALL-INSTRUCTIONS-DIRECT, E-ANCHORS-INSTALL-INSTRUCTIONS-AIRULES
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

INSTALL_SH="$REPO_ROOT/install.sh"

echo "  [1] Script syntax"
assert_true "install.sh passes bash -n syntax check" "bash -n '$INSTALL_SH'"

echo "  [2] E-ANCHORS-INSTALL-AGENT-MENU: All four agent options present"
assert_grep "Claude Code option" "Claude Code" "$INSTALL_SH"
assert_grep "Amp option" "Amp" "$INSTALL_SH"
assert_grep "Codex option" "Codex" "$INSTALL_SH"
assert_grep "ai-rules option" "ai-rules" "$INSTALL_SH"
assert_grep "Choice prompt accepts 1-4" 'Choice \[1-4\]' "$INSTALL_SH"

echo "  [3] E-ANCHORS-INSTALL-SCOPE-MENU: Scope options present"
assert_grep "User-level option" "User-level" "$INSTALL_SH"
assert_grep "Project-level option" "Project-level" "$INSTALL_SH"

echo "  [4] E-ANCHORS-INSTALL-TARGET-DIRS: All six agent-scope paths"
assert_grep "Claude user path" '\.claude/skills/' "$INSTALL_SH"
assert_grep "Amp user path" '\.config/agents/skills/' "$INSTALL_SH"
assert_grep "Amp project path" '\.agents/skills/' "$INSTALL_SH"
assert_grep "Codex user path" '\.codex/skills/' "$INSTALL_SH"

echo "  [5] E-ANCHORS-INSTALL-AIRULES-PATH: ai-rules target and generate"
assert_grep "ai-rules target dir" 'ai-rules/skills/' "$INSTALL_SH"
assert_grep "Runs ai-rules generate" 'ai-rules generate' "$INSTALL_SH"

echo "  [6] E-ANCHORS-INSTALL-AIRULES-CHECKS: Prerequisite validation"
assert_grep "Checks for ai-rules CLI" 'command -v ai-rules' "$INSTALL_SH"
assert_grep "Checks for ai-rules directory" '! -d' "$INSTALL_SH"
assert_grep "CLI not found error message" 'ai-rules CLI not found' "$INSTALL_SH"
assert_grep "Directory not found error message" 'ai-rules.*directory' "$INSTALL_SH"

echo "  [7] E-ANCHORS-INSTALL-REPLACE: Removes existing before copy"
assert_grep "Remove existing check" 'rm -rf' "$INSTALL_SH"
assert_grep "Create parent dirs" 'mkdir -p' "$INSTALL_SH"
assert_grep "Copy skill" 'cp -R' "$INSTALL_SH"

echo "  [8] E-ANCHORS-INSTALL-INSTRUCTIONS-DIRECT: Project-level agent instructions"
assert_grep "Has append_agent_instructions function" 'append_agent_instructions' "$INSTALL_SH"
assert_grep "Checks for AGENTS.md" 'AGENTS.md' "$INSTALL_SH"
assert_grep "Checks for CLAUDE.md" 'CLAUDE.md' "$INSTALL_SH"
assert_grep "Handles symlinks with readlink" 'readlink' "$INSTALL_SH"
assert_grep "Skips if ANCHORS section present" '## ANCHORS' "$INSTALL_SH"
assert_grep "Only appends for project scope" 'scope.*=.*project' "$INSTALL_SH"

echo "  [9] E-ANCHORS-INSTALL-INSTRUCTIONS-AIRULES: ai-rules rule file"
assert_grep "Creates ai-rules/anchors.md" 'ai-rules/anchors.md' "$INSTALL_SH"
assert_grep "Skips if anchors.md exists" '-e.*ai-rules/anchors.md' "$INSTALL_SH"

finish_tests
