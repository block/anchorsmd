#!/bin/bash
# Layer 1/2: Document format validation on fixtures
# Tests: E-ANCHORS-DOC-LOCATIONS, E-ANCHORS-P-ID-FORMAT,
#        E-ANCHORS-E-ID-FORMAT, E-ANCHORS-DEP-ID-FORMAT
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

FIXTURE="$FIXTURES_DIR/complete-module"

echo "  [1] E-ANCHORS-DOC-LOCATIONS: Documents are siblings of ANCHORS.md"
anchors_dir=$(dirname "$FIXTURE/ANCHORS.md")
assert_file_exists "PRODUCT.md is sibling of ANCHORS.md" "$anchors_dir/PRODUCT.md"
assert_file_exists "ERD.md is sibling of ANCHORS.md" "$anchors_dir/ERD.md"
assert_file_exists "TESTING.md is sibling of ANCHORS.md" "$anchors_dir/TESTING.md"
assert_file_exists "DEPENDENCIES.md is sibling of ANCHORS.md" "$anchors_dir/DEPENDENCIES.md"

echo "  [2] E-ANCHORS-P-ID-FORMAT: P-* IDs use HTML anchor format"
# P-* IDs must use <a id="P-PREFIX-SLUG"></a>**P-PREFIX-SLUG**: format
while IFS= read -r pid; do
  assert_grep "P-ID ${pid} uses bold label" "\\*\\*${pid}\\*\\*:" "$FIXTURE/PRODUCT.md"
done < <(grep -oE '<a id="(P-AUTH-[A-Z0-9-]+)">' "$FIXTURE/PRODUCT.md" | sed 's/<a id="//;s/">//')

echo "  [3] E-ANCHORS-E-ID-FORMAT: E-* IDs use HTML anchor + backlink"
while IFS= read -r eid; do
  assert_grep "E-ID ${eid} uses bold label" "\\*\\*${eid}\\*\\*:" "$FIXTURE/ERD.md"
  # Check backlink exists within 2 lines
  line_num=$(grep -n "<a id=\"${eid}\">" "$FIXTURE/ERD.md" | head -1 | cut -d: -f1)
  context=$(sed -n "${line_num},$((line_num + 2))p" "$FIXTURE/ERD.md")
  inc_test
  if echo "$context" | grep -qE '← \[P-'; then
    echo "    ✓ ${eid} has ← backlink"
  else
    echo "    ✗ ${eid} missing ← backlink"
    inc_fail
  fi
done < <(grep -oE '<a id="(E-AUTH-[A-Z0-9-]+)">' "$FIXTURE/ERD.md" | sed 's/<a id="//;s/">//')

echo "  [4] E-ANCHORS-DEP-ID-FORMAT: D-DEP-* uses section header + structured fields"
assert_grep "D-DEP uses section header format" '### D-DEP-' "$FIXTURE/DEPENDENCIES.md"
assert_grep "D-DEP has Used by field" '^\- \*\*Used by:\*\*' "$FIXTURE/DEPENDENCIES.md"
assert_grep "D-DEP has Where it runs field" '^\- \*\*Where it runs:\*\*' "$FIXTURE/DEPENDENCIES.md"
assert_grep "D-DEP has Why external field" '^\- \*\*Why external:\*\*' "$FIXTURE/DEPENDENCIES.md"

echo "  [5] Template P-ID and E-ID formats match documented convention"
# Templates should show the canonical format
assert_grep "PRODUCT template uses <a id> format" '<a id="P-' "$TEMPLATES_DIR/PRODUCT.md"
assert_grep "ERD template uses <a id> format" '<a id="E-' "$TEMPLATES_DIR/ERD.md"
assert_grep "ERD template shows ← backlink" '← \[P-' "$TEMPLATES_DIR/ERD.md"
assert_grep "DEPENDENCIES template uses ### D-DEP- format" '### D-DEP-' "$TEMPLATES_DIR/DEPENDENCIES.md"

finish_tests
