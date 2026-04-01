#!/bin/bash
# Layer 1/2: Document format validation on fixtures
# Tests: E-ANCHORS-DOC-INTEGRITY, E-ANCHORS-CANONICAL-IDS
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

FIXTURE="$FIXTURES_DIR/complete-module"

echo "  [1] E-ANCHORS-DOC-INTEGRITY: Documents are siblings of ANCHORS.md"
anchors_dir=$(dirname "$FIXTURE/ANCHORS.md")
assert_file_exists "PRODUCT.md is sibling of ANCHORS.md" "$anchors_dir/PRODUCT.md"
assert_file_exists "ENGINEERING.md is sibling of ANCHORS.md" "$anchors_dir/ENGINEERING.md"
assert_file_exists "TESTING.md is sibling of ANCHORS.md" "$anchors_dir/TESTING.md"
assert_file_exists "DEPENDENCIES.md is sibling of ANCHORS.md" "$anchors_dir/DEPENDENCIES.md"

echo "  [2] E-ANCHORS-CANONICAL-IDS: P-* IDs use HTML anchor format"
# P-* IDs must use <a id="P-PREFIX-SLUG"></a>**P-PREFIX-SLUG**: format
while IFS= read -r pid; do
  assert_grep "P-ID ${pid} uses bold label" "\\*\\*${pid}\\*\\*:" "$FIXTURE/PRODUCT.md"
done < <(grep -oE '<a id="(P-AUTH-[A-Z0-9-]+)">' "$FIXTURE/PRODUCT.md" | sed 's/<a id="//;s/">//')

echo "  [3] E-ANCHORS-CANONICAL-IDS: E-* IDs use HTML anchor + backlink"
while IFS= read -r eid; do
  assert_grep "E-ID ${eid} uses bold label" "\\*\\*${eid}\\*\\*:" "$FIXTURE/ENGINEERING.md"
  # Check backlink exists within 2 lines
  line_num=$(grep -n "<a id=\"${eid}\">" "$FIXTURE/ENGINEERING.md" | head -1 | cut -d: -f1)
  context=$(sed -n "${line_num},$((line_num + 2))p" "$FIXTURE/ENGINEERING.md")
  inc_test
  if echo "$context" | grep -qE '← \[P-'; then
    echo "    ✓ ${eid} has ← backlink"
  else
    echo "    ✗ ${eid} missing ← backlink"
    inc_fail
  fi
done < <(grep -oE '<a id="(E-AUTH-[A-Z0-9-]+)">' "$FIXTURE/ENGINEERING.md" | sed 's/<a id="//;s/">//')

echo "  [4] E-ANCHORS-CANONICAL-IDS: D-DEP-* uses section header + structured fields"
assert_grep "D-DEP uses section header format" '### D-DEP-' "$FIXTURE/DEPENDENCIES.md"
assert_grep "D-DEP has Used by field" '^\- \*\*Used by:\*\*' "$FIXTURE/DEPENDENCIES.md"
assert_grep "D-DEP has Where it runs field" '^\- \*\*Where it runs:\*\*' "$FIXTURE/DEPENDENCIES.md"
assert_grep "D-DEP has Why external field" '^\- \*\*Why external:\*\*' "$FIXTURE/DEPENDENCIES.md"

finish_tests
