#!/bin/bash
# Install the anchors skill for Claude Code
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${HOME}/.claude/skills/anchors"

echo "Installing anchors skill to ${SKILL_DIR}..."

# Symlink the entire skill directory so updates to the repo propagate
ln -sfn "${SCRIPT_DIR}/skill" "${SKILL_DIR}"

echo "Installed:"
echo "  ${SKILL_DIR} -> ${SCRIPT_DIR}/skill"
echo ""
echo "Usage: /anchors init | /anchors audit"
