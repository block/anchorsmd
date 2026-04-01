#!/bin/bash
# Test: anchors CLI structure and subcommands
# Covers: E-ANCHORS-CLI-SKILL-BOUNDARY, E-ANCHORS-AGENT-AGNOSTIC,
#         E-ANCHORS-IDEMPOTENT-OPS
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

CLI="$REPO_ROOT/anchors"

echo "  [1] Script syntax"
assert_true "anchors passes bash -n syntax check" "bash -n '$CLI'"

echo "  [2] E-ANCHORS-CLI-SKILL-BOUNDARY: Subcommand dispatch"
assert_grep "Has install subcommand" 'install)' "$CLI"
assert_grep "Has setup subcommand" 'setup)' "$CLI"
assert_grep "Has check subcommand" 'check)' "$CLI"
assert_grep "Has upgrade subcommand" 'upgrade)' "$CLI"
assert_grep "Has usage function" 'usage()' "$CLI"

echo "  [3] E-ANCHORS-AGENT-AGNOSTIC: Agent detection"
assert_grep "Detects .claude/ directory" '\.claude/' "$CLI"
assert_grep "Detects .goose/ directory" '\.goose/' "$CLI"
assert_grep "Detects .agents/ directory" '\.agents/' "$CLI"
assert_grep "Detects ai-rules/ directory" 'ai-rules/' "$CLI"
assert_grep "Accepts --agent flag" '\-\-agent' "$CLI"

echo "  [4] E-ANCHORS-AGENT-AGNOSTIC: Project-level skill paths"
assert_grep "Claude Code project path" '\.claude/skills/' "$CLI"
assert_grep "Goose project path" '\.goose/skills/' "$CLI"
assert_grep "Amp project path" '\.agents/skills/' "$CLI"
assert_grep "ai-rules project path" 'ai-rules/skills/' "$CLI"

echo "  [5] E-ANCHORS-CLI-SKILL-BOUNDARY: Setup creates document skeletons"
assert_grep "Creates ANCHORS.md" 'ANCHORS\.md' "$CLI"
assert_grep "Creates PRODUCT.md" 'PRODUCT\.md' "$CLI"
assert_grep "Creates ENGINEERING.md" 'ENGINEERING\.md' "$CLI"
assert_grep "Creates TESTING.md" 'TESTING\.md' "$CLI"
assert_grep "Creates DEPENDENCIES.md" 'DEPENDENCIES\.md' "$CLI"
assert_grep "Accepts --prefix flag" '\-\-prefix' "$CLI"
assert_grep "Accepts --mode flag" '\-\-mode' "$CLI"

echo "  [6] E-ANCHORS-AGENT-AGNOSTIC: Agent instructions handling"
assert_grep "Has append_agent_instructions function" 'append_agent_instructions' "$CLI"
assert_grep "Checks for AGENTS.md" 'AGENTS.md' "$CLI"
assert_grep "Checks for CLAUDE.md" 'CLAUDE.md' "$CLI"
assert_grep "Handles symlinks with readlink" 'readlink' "$CLI"
assert_grep "Skips if ANCHORS section present" '## ANCHORS' "$CLI"

echo "  [7] E-ANCHORS-AGENT-AGNOSTIC: ai-rules prerequisites"
assert_grep "Checks for ai-rules CLI" 'command -v ai-rules' "$CLI"
assert_grep "Checks for ai-rules directory" '! -d.*ai-rules' "$CLI"
assert_grep "CLI not found error message" 'ai-rules CLI not found' "$CLI"
assert_grep "Runs ai-rules generate" 'ai-rules generate' "$CLI"

echo "  [8] E-ANCHORS-AGENT-AGNOSTIC: ai-rules rule file"
assert_grep "Creates ai-rules/anchors.md" 'ai-rules/anchors.md' "$CLI"

echo "  [9] E-ANCHORS-CLI-SKILL-BOUNDARY: Check subcommand features"
assert_grep "Check requires ANCHORS.md" 'No ANCHORS.md found' "$CLI"
assert_grep "Check validates backlinks" '←.*P-' "$CLI"
assert_grep "Check outputs structured report" 'Check Report' "$CLI"
assert_grep "Check reports open questions" 'Open Questions' "$CLI"

echo "  [10] E-ANCHORS-CLI-SKILL-BOUNDARY: Upgrade subcommand"
assert_grep "Upgrade removes existing skill" 'rm -rf' "$CLI"
assert_grep "Upgrade copies new skill" 'cp -R' "$CLI"
assert_grep "Upgrade has --force flag" '\-\-force' "$CLI"

echo "  [10b] E-ANCHORS-VERSION-FILE: VERSION file exists in skill directory"
assert_file_exists "skill/VERSION exists" "$REPO_ROOT/skill/VERSION"

echo "  [10c] E-ANCHORS-VERSION-COMPARE: Version comparison in CLI"
assert_grep "CLI has version_compare function" 'version_compare' "$CLI"
assert_grep "CLI reads installed VERSION" 'target_dir.*VERSION' "$CLI"
assert_grep "CLI reads bundled VERSION" 'SKILL_SOURCE.*VERSION' "$CLI"
assert_grep "CLI blocks downgrade" 'newer than CLI version' "$CLI"
assert_grep "CLI detects equal version" 'Already at version' "$CLI"
assert_grep "CLI shows --force hint" 'Use --force to downgrade' "$CLI"

echo "  [11] E-ANCHORS-IDEMPOTENT-OPS: Prefix uniqueness check"
assert_grep "Checks prefix uniqueness" 'check_prefix_unique' "$CLI"
assert_grep "Reports prefix collision" "Prefix.*already used" "$CLI"

echo "  [12] Functional: install + setup in temp dir"
tmpdir=$(mktemp -d)
trap "rm -rf '${tmpdir}'" EXIT

# Create a fake .claude dir so agent detection works
mkdir -p "${tmpdir}/.claude"

# Install skill first
(cd "${tmpdir}" && "$CLI" install --agent claude) >/dev/null 2>&1
assert_file_exists "Skill installed" "${tmpdir}/.claude/skills/anchors/SKILL.md"

# Then setup a module
(cd "${tmpdir}" && "$CLI" setup ./mymod --prefix MYMOD) >/dev/null 2>&1

assert_file_exists "ANCHORS.md created" "${tmpdir}/mymod/ANCHORS.md"
assert_file_exists "PRODUCT.md created" "${tmpdir}/mymod/PRODUCT.md"
assert_file_exists "ENGINEERING.md created" "${tmpdir}/mymod/ENGINEERING.md"
assert_file_exists "TESTING.md created" "${tmpdir}/mymod/TESTING.md"
assert_file_exists "DEPENDENCIES.md created" "${tmpdir}/mymod/DEPENDENCIES.md"
assert_grep "ANCHORS.md has correct prefix" '^prefix: MYMOD' "${tmpdir}/mymod/ANCHORS.md"

echo "  [13] Functional: setup --skip-existing preserves files"
echo "# Custom content" > "${tmpdir}/mymod/PRODUCT.md"
(cd "${tmpdir}" && "$CLI" setup ./mymod --prefix MYMOD --skip-existing) >/dev/null 2>&1
assert_grep "PRODUCT.md preserved with --skip-existing" '# Custom content' "${tmpdir}/mymod/PRODUCT.md"

echo "  [14] Functional: setup --mode detached"
(cd "${tmpdir}" && "$CLI" setup ./detmod --prefix DETMOD --mode detached --path ../src) >/dev/null 2>&1
assert_grep "Detached ANCHORS.md has mode" 'mode: detached' "${tmpdir}/detmod/ANCHORS.md"
assert_grep "Detached ANCHORS.md has path" 'path: \.\./src' "${tmpdir}/detmod/ANCHORS.md"

echo "  [15] Functional: prefix collision rejected"
mkdir -p "${tmpdir}/dup"
printf '%s\n' '---' 'prefix: MYMOD' '---' > "${tmpdir}/dup/ANCHORS.md"
if (cd "${tmpdir}" && "$CLI" setup ./newmod --prefix MYMOD) 2>/dev/null; then
  echo "    ✗ Duplicate prefix should have been rejected"
  inc_test; inc_fail
else
  echo "    ✓ Duplicate prefix correctly rejected"
  inc_test
fi

echo "  [16] Functional: install with --agent goose"
goose_tmpdir=$(mktemp -d)
trap "rm -rf '${tmpdir}' '${goose_tmpdir}'" EXIT
mkdir -p "${goose_tmpdir}/.goose"
(cd "${goose_tmpdir}" && "$CLI" install --agent goose) >/dev/null 2>&1
assert_file_exists "Goose skill installed" "${goose_tmpdir}/.goose/skills/anchors/SKILL.md"

echo "  [17] Functional: install is idempotent"
install_output=$( (cd "${tmpdir}" && "$CLI" install --agent claude) 2>&1 )
inc_test
if echo "$install_output" | grep -q 'already installed'; then
  echo "    ✓ Second install skips (idempotent)"
else
  echo "    ✗ Second install should have skipped"
  inc_fail
fi

echo "  [18] Functional: check requires path"
if ("$CLI" check) 2>/dev/null; then
  echo "    ✗ Check without path should have failed"
  inc_test; inc_fail
else
  echo "    ✓ Check without path correctly fails"
  inc_test
fi

echo "  [19] Functional: check subcommand runs"
check_output=$("$CLI" check "$REPO_ROOT" 2>&1 || true)
inc_test
if echo "$check_output" | grep -q '## ANCHORS Check Report'; then
  echo "    ✓ Check produces structured report"
else
  echo "    ✗ Check did not produce expected report"
  inc_fail
fi

echo "  [20] Functional: version_compare"
# Extract the version functions from the CLI into a temp script we can source
ver_helper="${tmpdir}/_ver_funcs.sh"
sed -n '/^parse_version()/,/^}/p' "$CLI" > "$ver_helper"
sed -n '/^version_compare()/,/^}/p' "$CLI" >> "$ver_helper"
source "$ver_helper"

assert_eq "1.0.0 vs 0.9.0 → newer" "newer" "$(version_compare 1.0.0 0.9.0)"
assert_eq "0.1.0 vs 0.2.0 → older" "older" "$(version_compare 0.1.0 0.2.0)"
assert_eq "1.2.3 vs 1.2.3 → equal" "equal" "$(version_compare 1.2.3 1.2.3)"
assert_eq "2.0.0 vs 1.9.9 → newer" "newer" "$(version_compare 2.0.0 1.9.9)"
assert_eq "0.0.0-dev vs 0.1.0 → older" "older" "$(version_compare 0.0.0-dev 0.1.0)"
assert_eq "1.0.0-rc1 vs 1.0.0 → equal" "equal" "$(version_compare 1.0.0-rc1 1.0.0)"
assert_eq "0.2 vs 0.1.0 → newer (missing patch)" "newer" "$(version_compare 0.2 0.1.0)"

echo "  [21] Functional: upgrade blocks downgrade"
# Install skill with a "newer" version stamp
echo "99.0.0" > "${tmpdir}/.claude/skills/anchors/VERSION"
upgrade_output=$( (cd "${tmpdir}" && "$CLI" upgrade --agent claude) 2>&1 || true )
inc_test
if echo "$upgrade_output" | grep -q 'newer than CLI version'; then
  echo "    ✓ Upgrade blocked when installed version is newer"
else
  echo "    ✗ Upgrade should have been blocked (got: ${upgrade_output})"
  inc_fail
fi

echo "  [22] Functional: upgrade --force overrides downgrade check"
force_output=$( (cd "${tmpdir}" && "$CLI" upgrade --agent claude --force) 2>&1 )
inc_test
if echo "$force_output" | grep -q 'Upgraded ANCHORS skill'; then
  echo "    ✓ --force overrides downgrade check"
else
  echo "    ✗ --force should have allowed downgrade (got: ${force_output})"
  inc_fail
fi

echo "  [23] Functional: upgrade skips when versions are equal"
# After --force, installed VERSION now matches bundled
equal_output=$( (cd "${tmpdir}" && "$CLI" upgrade --agent claude) 2>&1 )
inc_test
if echo "$equal_output" | grep -q 'Already at version\|already at version'; then
  echo "    ✓ Upgrade skips when already at same version"
else
  echo "    ✗ Upgrade should have skipped for equal versions (got: ${equal_output})"
  inc_fail
fi

echo "  [24] Functional: upgrade proceeds when installed VERSION is missing (pre-versioning)"
rm -f "${tmpdir}/.claude/skills/anchors/VERSION"
legacy_output=$( (cd "${tmpdir}" && "$CLI" upgrade --agent claude) 2>&1 )
inc_test
if echo "$legacy_output" | grep -q 'Upgraded ANCHORS skill'; then
  echo "    ✓ Upgrade proceeds when no installed VERSION (legacy)"
else
  echo "    ✗ Upgrade should have proceeded for legacy install (got: ${legacy_output})"
  inc_fail
fi

echo "  [25] Functional: install includes VERSION file"
assert_file_exists "VERSION copied during install" "${tmpdir}/.claude/skills/anchors/VERSION"

echo "  [26] Functional: upgrade migrates ERD.md → ENGINEERING.md"
upgrade_tmpdir=$(mktemp -d)
trap "rm -rf '${tmpdir}' '${goose_tmpdir}' '${upgrade_tmpdir}'" EXIT
mkdir -p "${upgrade_tmpdir}/.claude"
# Install skill so upgrade has something to replace
(cd "${upgrade_tmpdir}" && "$CLI" install --agent claude) >/dev/null 2>&1
# Set up a module with legacy ERD.md (simulate pre-upgrade state)
mkdir -p "${upgrade_tmpdir}/legmod"
printf '%s\n' '---' 'prefix: LEG' '---' > "${upgrade_tmpdir}/legmod/ANCHORS.md"
printf '%s\n' '---' 'see-also:' '  - ERD.md' '---' '# Product' > "${upgrade_tmpdir}/legmod/PRODUCT.md"
printf '%s\n' '---' 'see-also:' '  - ERD.md' '---' '# Testing' > "${upgrade_tmpdir}/legmod/TESTING.md"
printf '%s\n' '# Engineering' > "${upgrade_tmpdir}/legmod/ERD.md"
# Run upgrade
upgrade_output=$( (cd "${upgrade_tmpdir}" && "$CLI" upgrade --agent claude) 2>&1 )
# ERD.md should be renamed
assert_file_exists "ENGINEERING.md exists after upgrade" "${upgrade_tmpdir}/legmod/ENGINEERING.md"
inc_test
if [[ ! -f "${upgrade_tmpdir}/legmod/ERD.md" ]]; then
  echo "    ✓ ERD.md removed after upgrade"
else
  echo "    ✗ ERD.md still exists after upgrade"
  inc_fail
fi
# Sibling see-also references should be updated
assert_grep "PRODUCT.md updated to ENGINEERING.md" 'ENGINEERING.md' "${upgrade_tmpdir}/legmod/PRODUCT.md"
assert_no_grep "PRODUCT.md no longer references ERD.md" 'ERD\.md' "${upgrade_tmpdir}/legmod/PRODUCT.md"
assert_grep "TESTING.md updated to ENGINEERING.md" 'ENGINEERING.md' "${upgrade_tmpdir}/legmod/TESTING.md"
assert_no_grep "TESTING.md no longer references ERD.md" 'ERD\.md' "${upgrade_tmpdir}/legmod/TESTING.md"
# Content should be preserved
assert_grep "ENGINEERING.md has original content" '# Engineering' "${upgrade_tmpdir}/legmod/ENGINEERING.md"

echo "  [27] Functional: upgrade warns when both ERD.md and ENGINEERING.md exist"
mkdir -p "${upgrade_tmpdir}/bothmod"
printf '%s\n' '---' 'prefix: BOTH' '---' > "${upgrade_tmpdir}/bothmod/ANCHORS.md"
printf '%s\n' '# Old' > "${upgrade_tmpdir}/bothmod/ERD.md"
printf '%s\n' '# New' > "${upgrade_tmpdir}/bothmod/ENGINEERING.md"
upgrade_both_output=$( (cd "${upgrade_tmpdir}" && "$CLI" upgrade --agent claude) 2>&1 )
inc_test
if echo "$upgrade_both_output" | grep -q 'Warning.*both.*ERD.md.*ENGINEERING.md'; then
  echo "    ✓ Upgrade warns about both files existing"
else
  echo "    ✗ Upgrade should warn about both files"
  inc_fail
fi
# Neither file should be modified
assert_grep "ERD.md preserved" '# Old' "${upgrade_tmpdir}/bothmod/ERD.md"
assert_grep "ENGINEERING.md preserved" '# New' "${upgrade_tmpdir}/bothmod/ENGINEERING.md"

echo "  [28] Functional: check works with legacy ERD.md"
legacy_tmpdir=$(mktemp -d)
trap "rm -rf '${tmpdir}' '${goose_tmpdir}' '${upgrade_tmpdir}' '${legacy_tmpdir}'" EXIT
mkdir -p "${legacy_tmpdir}/legcheck"
printf '%s\n' '---' 'prefix: LEGCHK' '---' > "${legacy_tmpdir}/legcheck/ANCHORS.md"
cat > "${legacy_tmpdir}/legcheck/PRODUCT.md" << 'LEGACY'
---
scope: Product requirements
see-also:
  - ERD.md
---
# Product
- <a id="P-LEGCHK-FEAT"></a>**P-LEGCHK-FEAT**: A feature.
LEGACY
cat > "${legacy_tmpdir}/legcheck/ERD.md" << 'LEGACY'
---
scope: Engineering requirements
see-also:
  - PRODUCT.md
---
# Engineering
- <a id="E-LEGCHK-IMPL"></a>**E-LEGCHK-IMPL**: Implementation.
  ← [P-LEGCHK-FEAT](PRODUCT.md#P-LEGCHK-FEAT)
LEGACY
check_legacy_output=$("$CLI" check "${legacy_tmpdir}/legcheck" 2>&1 || true)
inc_test
if echo "$check_legacy_output" | grep -q 'Engineering.*PRD backlinks: 1/1'; then
  echo "    ✓ Check finds E-* IDs in legacy ERD.md"
else
  echo "    ✗ Check should find E-* IDs in legacy ERD.md"
  echo "    Output: $check_legacy_output"
  inc_fail
fi
inc_test
if echo "$check_legacy_output" | grep -q 'PRD coverage.*1/1'; then
  echo "    ✓ Check finds P-* coverage via legacy ERD.md"
else
  echo "    ✗ Check should find P-* coverage via legacy ERD.md"
  inc_fail
fi

finish_tests
