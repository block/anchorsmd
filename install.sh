#!/bin/bash
# Install the ANCHORS skill for AI coding agents
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SOURCE="${SCRIPT_DIR}/skill"
SKILL_NAME="anchors"

# --- Agent selection ---

echo "Which agent?"
echo "  1) Claude Code"
echo "  2) Amp"
echo "  3) Codex"
read -rp "Choice [1-3]: " agent_choice

case "${agent_choice}" in
  1) agent="claude" ;;
  2) agent="amp" ;;
  3) agent="codex" ;;
  *) echo "Invalid choice." >&2; exit 1 ;;
esac

# --- Scope selection ---

echo ""
echo "Install scope?"
echo "  1) User-level (available in all projects)"
echo "  2) Project-level (available in this repo only)"
read -rp "Choice [1-2]: " scope_choice

case "${scope_choice}" in
  1) scope="user" ;;
  2) scope="project" ;;
  *) echo "Invalid choice." >&2; exit 1 ;;
esac

# --- Resolve target directory ---

case "${agent}-${scope}" in
  claude-user)   target_dir="${HOME}/.claude/skills/${SKILL_NAME}" ;;
  claude-project) target_dir=".claude/skills/${SKILL_NAME}" ;;
  amp-user)      target_dir="${HOME}/.config/agents/skills/${SKILL_NAME}" ;;
  amp-project)   target_dir=".agents/skills/${SKILL_NAME}" ;;
  codex-user)    target_dir="${HOME}/.codex/skills/${SKILL_NAME}" ;;
  codex-project) target_dir=".agents/skills/${SKILL_NAME}" ;;
esac

# --- Install ---

# Remove any existing skill at the target (file, symlink, or directory)
if [ -e "${target_dir}" ] || [ -L "${target_dir}" ]; then
  echo "Removing existing skill at ${target_dir}..."
  rm -rf "${target_dir}"
fi

mkdir -p "$(dirname "${target_dir}")"
cp -R "${SKILL_SOURCE}" "${target_dir}"

echo ""
echo "Installed ANCHORS skill to ${target_dir}"
echo "Usage: /anchors init | /anchors audit"
