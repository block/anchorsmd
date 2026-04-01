#!/bin/bash
# Layer 2/3: Self-audit — Validate the ANCHORS repo's own documents
# Tests: E-ANCHORS-CHECK-COMPLETENESS, E-ANCHORS-DOC-INTEGRITY
# TESTING.md: "running /anchors audit on the ANCHORS repo itself is a form of integration test"
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

PRODUCT="$REPO_ROOT/PRODUCT.md"
ERD="$REPO_ROOT/ENGINEERING.md"
TESTING="$REPO_ROOT/TESTING.md"
ANCHORS="$REPO_ROOT/ANCHORS.md"

echo "  [2.1] ANCHORS.md marker format"
assert_grep "ANCHORS.md has prefix field" '^prefix:' "$ANCHORS"
prefix=$(grep '^prefix:' "$ANCHORS" | sed 's/prefix: *//')
assert_eq "Prefix is ANCHORS" "ANCHORS" "$prefix"

echo "  [2.2] All four documents exist"
assert_file_exists "PRODUCT.md exists" "$PRODUCT"
assert_file_exists "ENGINEERING.md exists" "$ERD"
assert_file_exists "TESTING.md exists" "$TESTING"
# DEPENDENCIES.md is optional for this project (no external deps beyond Claude Code)

echo "  [2.3] All P-* requirements have IDs in correct format"
p_ids=$(grep -oE 'P-ANCHORS-[A-Z0-9-]+' "$PRODUCT" | sort -u)
p_count=$(echo "$p_ids" | wc -l | tr -d ' ')
assert_true "PRODUCT.md has P-* requirements (found ${p_count})" [[ "$p_count" -gt 0 ]]

# Every P-* should have an HTML anchor
while IFS= read -r pid; do
  assert_grep "P-ID ${pid} has HTML anchor" "<a id=\"${pid}\">" "$PRODUCT"
done <<< "$p_ids"

echo "  [2.4] All E-* requirements have IDs in correct format"
e_ids=$(grep -oE 'E-ANCHORS-[A-Z0-9-]+' "$ERD" | sort -u)
e_count=$(echo "$e_ids" | wc -l | tr -d ' ')
assert_true "ENGINEERING.md has E-* requirements (found ${e_count})" [[ "$e_count" -gt 0 ]]

while IFS= read -r eid; do
  assert_grep "E-ID ${eid} has HTML anchor" "<a id=\"${eid}\">" "$ERD"
done <<< "$e_ids"

echo "  [2.5] Every E-* has a ← backlink to P-*"
# For each E-* anchor, check that a ← [P-ANCHORS-*] appears nearby
missing_backlinks=0
while IFS= read -r eid; do
  # Find the line number of the anchor, then check if ← appears within 5 lines
  line_num=$(grep -n "<a id=\"${eid}\">" "$ERD" | head -1 | cut -d: -f1)
  if [[ -n "$line_num" ]]; then
    # Check lines line_num through line_num+5 for a backlink
    context=$(sed -n "${line_num},$((line_num + 5))p" "$ERD")
    if ! echo "$context" | grep -qE '← \[P-'; then
      echo "    ✗ ${eid} missing ← backlink"
      missing_backlinks=$((missing_backlinks + 1))
      inc_fail
    fi
  fi
  inc_test
done <<< "$e_ids"
if [[ $missing_backlinks -eq 0 ]]; then
  echo "    ✓ All E-* requirements have ← backlinks"
fi

echo "  [2.6] Every P-* is covered by at least one E-*"
uncovered=0
while IFS= read -r pid; do
  inc_test
  if ! grep -qE "$pid" "$ERD"; then
    echo "    ✗ ${pid} has no E-* coverage in ENGINEERING.md"
    uncovered=$((uncovered + 1))
    inc_fail
  fi
done <<< "$p_ids"
if [[ $uncovered -eq 0 ]]; then
  echo "    ✓ All P-* requirements covered by E-*"
fi

echo "  [2.7] No unresolved OPEN-* items (unless expected)"
# Filter out: resolved (~~OPEN-), comments (<!-- ), backtick-quoted (`OPEN-*`),
# requirement definitions (<a id=), and lines that reference OPEN-* as a pattern
open_items=$(grep -rE 'OPEN-[A-Z]' "$REPO_ROOT"/*.md 2>/dev/null \
  | grep -v '~~OPEN-' \
  | grep -v '<!-- ' \
  | grep -v '`OPEN-' \
  | grep -v '<a id=' \
  | grep -v 'OPEN-\*' \
  || true)
if [[ -z "$open_items" ]]; then
  open_count="0"
else
  open_count=$(echo "$open_items" | wc -l | tr -d ' ')
fi
# The repo's own docs should have no open questions (both say "(none)")
assert_eq "No unresolved OPEN-* items" "0" "$open_count"

echo "  [2.8] Document frontmatter consistency"
for doc in "$PRODUCT" "$ERD" "$TESTING"; do
  name=$(basename "$doc")
  assert_grep "${name} has scope field" '^scope:' "$doc"
  assert_grep "${name} has see-also field" '^see-also:' "$doc"
done

finish_tests
