#!/bin/bash
# Install the ANCHORS skill for AI coding agents
# E-ANCHORS-INSTALL-AGENT-MENU: supports Claude Code, Amp, Codex, ai-rules
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_SOURCE="${SCRIPT_DIR}/skill"
SKILL_NAME="anchors"

ANCHORS_SECTION='## ANCHORS

This repo uses ANCHORS for requirements-driven development. Always load the anchors skill (`/anchors`) before making changes.'

# E-ANCHORS-INSTALL-INSTRUCTIONS-DIRECT: append ANCHORS section to agent instructions
# Uses same logic as init step 6: AGENTS.md/CLAUDE.md with symlink handling
append_agent_instructions() {
  local agents_md="AGENTS.md"
  local claude_md="CLAUDE.md"
  local agents_exists=false
  local claude_exists=false
  local agents_is_symlink_to_claude=false
  local claude_is_symlink_to_agents=false

  [ -e "${agents_md}" ] && agents_exists=true
  [ -e "${claude_md}" ] && claude_exists=true

  # Check symlink relationships
  if [ -L "${agents_md}" ] && [ "$(readlink "${agents_md}")" = "${claude_md}" ]; then
    agents_is_symlink_to_claude=true
  fi
  if [ -L "${claude_md}" ] && [ "$(readlink "${claude_md}")" = "${agents_md}" ]; then
    claude_is_symlink_to_agents=true
  fi

  append_if_missing() {
    local file="$1"
    if grep -qF '## ANCHORS' "$file" 2>/dev/null; then
      echo "ANCHORS section already present in ${file}, skipping."
      return
    fi
    printf '\n%s\n' "${ANCHORS_SECTION}" >> "$file"
    echo "Appended ANCHORS section to ${file}"
  }

  if $agents_exists && $claude_exists; then
    if $agents_is_symlink_to_claude; then
      # AGENTS.md -> CLAUDE.md, update the real file
      append_if_missing "${claude_md}"
    elif $claude_is_symlink_to_agents; then
      # CLAUDE.md -> AGENTS.md, update the real file
      append_if_missing "${agents_md}"
    else
      # Both exist as separate files
      append_if_missing "${agents_md}"
      append_if_missing "${claude_md}"
    fi
  elif $agents_exists; then
    append_if_missing "${agents_md}"
  elif $claude_exists; then
    append_if_missing "${claude_md}"
  else
    printf '%s\n' "${ANCHORS_SECTION}" > "${agents_md}"
    echo "Created ${agents_md} with ANCHORS section"
  fi
}

# --- Agent selection ---

echo "Which agent?"
echo "  1) Claude Code"
echo "  2) Amp"
echo "  3) Codex"
echo "  4) ai-rules (github.com/block/ai-rules)"
read -rp "Choice [1-4]: " agent_choice

case "${agent_choice}" in
  1) agent="claude" ;;
  2) agent="amp" ;;
  3) agent="codex" ;;
  4) agent="airules" ;;
  *) echo "Invalid choice." >&2; exit 1 ;;
esac

# --- ai-rules path (always project-level) ---
# E-ANCHORS-INSTALL-AIRULES-CHECKS: validate CLI and directory prerequisites
# E-ANCHORS-INSTALL-AIRULES-PATH: copy to ai-rules/skills/ and run generate
# E-ANCHORS-INSTALL-INSTRUCTIONS-AIRULES: create ai-rules/anchors.md rule file

if [ "${agent}" = "airules" ]; then
  if ! command -v ai-rules &>/dev/null; then
    echo "Error: ai-rules CLI not found." >&2
    echo "Install it: curl -fsSL https://raw.githubusercontent.com/block/ai-rules/main/scripts/install.sh | bash" >&2
    exit 1
  fi

  if [ ! -d "ai-rules" ]; then
    echo "Error: No ai-rules/ directory found in the current project." >&2
    echo "Run 'ai-rules init' first to set up ai-rules in this project." >&2
    exit 1
  fi

  target_dir="ai-rules/skills/${SKILL_NAME}"

  # E-ANCHORS-INSTALL-REPLACE: remove existing before copying
  if [ -e "${target_dir}" ] || [ -L "${target_dir}" ]; then
    echo "Removing existing skill at ${target_dir}..."
    rm -rf "${target_dir}"
  fi

  mkdir -p "$(dirname "${target_dir}")"
  cp -R "${SKILL_SOURCE}" "${target_dir}"

  # Create ai-rules rule file if it doesn't already exist
  if [ -e "ai-rules/anchors.md" ]; then
    echo "ai-rules/anchors.md already exists, skipping."
  else
    printf '%s\n' "${ANCHORS_SECTION}" > "ai-rules/anchors.md"
    echo "Created ai-rules/anchors.md"
  fi

  echo ""
  echo "Installed ANCHORS skill to ${target_dir}"
  echo "Running ai-rules generate..."
  ai-rules generate
  echo ""
  echo "Done. ai-rules has regenerated agent configurations."
  echo "Usage: /anchors init | /anchors audit"
  exit 0
fi

# --- Scope selection ---
# E-ANCHORS-INSTALL-SCOPE-MENU: user-level or project-level

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
# E-ANCHORS-INSTALL-TARGET-DIRS: agent+scope → path

case "${agent}-${scope}" in
  claude-user)   target_dir="${HOME}/.claude/skills/${SKILL_NAME}" ;;
  claude-project) target_dir=".claude/skills/${SKILL_NAME}" ;;
  amp-user)      target_dir="${HOME}/.config/agents/skills/${SKILL_NAME}" ;;
  amp-project)   target_dir=".agents/skills/${SKILL_NAME}" ;;
  codex-user)    target_dir="${HOME}/.codex/skills/${SKILL_NAME}" ;;
  codex-project) target_dir=".agents/skills/${SKILL_NAME}" ;;
esac

# --- Install ---
# E-ANCHORS-INSTALL-REPLACE: remove existing, create parents, copy skill

if [ -e "${target_dir}" ] || [ -L "${target_dir}" ]; then
  echo "Removing existing skill at ${target_dir}..."
  rm -rf "${target_dir}"
fi

mkdir -p "$(dirname "${target_dir}")"
cp -R "${SKILL_SOURCE}" "${target_dir}"

echo ""
echo "Installed ANCHORS skill to ${target_dir}"

# E-ANCHORS-INSTALL-INSTRUCTIONS-DIRECT: append agent instructions for project-level
if [ "${scope}" = "project" ]; then
  append_agent_instructions
fi

echo "Usage: /anchors init | /anchors audit"
