#!/bin/bash
# Layer 2: Integration — Complete module fixture
# Tests: E-ANCHORS-AUDIT-DOC-PRESENCE, E-ANCHORS-AUDIT-BACKLINK-CHECK,
#        E-ANCHORS-AUDIT-PRD-COVERAGE, E-ANCHORS-AUDIT-ID-EXTRACT
# Validates TESTING.md §2.3: audit on well-formed repo
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

FIXTURE="$FIXTURES_DIR/complete-module"

echo "  [2.3.1] Module discovery"
assert_file_exists "ANCHORS.md found" "$FIXTURE/ANCHORS.md"
prefix=$(grep '^prefix:' "$FIXTURE/ANCHORS.md" | sed 's/prefix: *//')
assert_eq "Prefix extracted correctly" "AUTH" "$prefix"

echo "  [2.3.2] Document presence (4/4)"
assert_file_exists "PRODUCT.md exists" "$FIXTURE/PRODUCT.md"
assert_file_exists "ERD.md exists" "$FIXTURE/ERD.md"
assert_file_exists "TESTING.md exists" "$FIXTURE/TESTING.md"
assert_file_exists "DEPENDENCIES.md exists" "$FIXTURE/DEPENDENCIES.md"

echo "  [2.3.3] P-* ID extraction"
p_ids=$(grep -oE "P-AUTH-[A-Z0-9-]+" "$FIXTURE/PRODUCT.md" | sort -u)
p_count=$(echo "$p_ids" | wc -l | tr -d ' ')
assert_eq "Found 3 P-* IDs" "3" "$p_count"

echo "  [2.3.4] E-* ID extraction"
e_ids=$(grep -oE "E-AUTH-[A-Z0-9-]+" "$FIXTURE/ERD.md" | sort -u)
e_count=$(echo "$e_ids" | wc -l | tr -d ' ')
assert_eq "Found 3 E-* IDs" "3" "$e_count"

echo "  [2.3.5] Backlink coverage (100%)"
missing=0
while IFS= read -r eid; do
  line_num=$(grep -n "<a id=\"${eid}\">" "$FIXTURE/ERD.md" | head -1 | cut -d: -f1)
  if [[ -n "$line_num" ]]; then
    context=$(sed -n "${line_num},$((line_num + 2))p" "$FIXTURE/ERD.md")
    if ! echo "$context" | grep -qE '← \[P-'; then
      echo "    ✗ ${eid} missing backlink"
      missing=$((missing + 1))
      inc_fail
    fi
    inc_test
  fi
done <<< "$e_ids"
if [[ $missing -eq 0 ]]; then
  echo "    ✓ All E-* have ← backlinks"
fi

echo "  [2.3.6] PRD coverage (100%)"
uncovered=0
while IFS= read -r pid; do
  inc_test
  if ! grep -qE "$pid" "$FIXTURE/ERD.md"; then
    echo "    ✗ ${pid} not covered by E-*"
    uncovered=$((uncovered + 1))
    inc_fail
  fi
done <<< "$p_ids"
if [[ $uncovered -eq 0 ]]; then
  echo "    ✓ All P-* covered by E-*"
fi

echo "  [2.3.7] D-DEP-* extraction"
assert_grep "DEPENDENCIES.md has D-DEP-* IDs" 'D-DEP-' "$FIXTURE/DEPENDENCIES.md"

finish_tests
