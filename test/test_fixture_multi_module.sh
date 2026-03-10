#!/bin/bash
# Layer 2: Integration — Multi-module fixture
# Tests: E-ANCHORS-MONO-MODULE-DETECTION, E-ANCHORS-AUDIT-PREFIX-COLLISION,
#        E-ANCHORS-AUDIT-CROSS-RESOLVE
# Validates TESTING.md §2.5: cross-module references
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

FIXTURE="$FIXTURES_DIR/multi-module"

echo "  [2.5.1] Multi-module discovery"
modules=$(find "$FIXTURE" -name "ANCHORS.md" | sort)
module_count=$(echo "$modules" | wc -l | tr -d ' ')
assert_eq "Found 2 modules" "2" "$module_count"

echo "  [2.5.2] Unique prefixes"
prefixes=""
while IFS= read -r mod; do
  p=$(grep '^prefix:' "$mod" | sed 's/prefix: *//')
  prefixes="${prefixes}${p}\n"
done <<< "$modules"
unique_count=$(echo -e "$prefixes" | sort -u | grep -c '[A-Z]')
assert_eq "All prefixes unique" "$module_count" "$unique_count"

echo "  [2.5.3] Valid cross-module reference resolves"
# payments/ERD.md references ../auth/PRODUCT.md#P-MAUTH-LOGIN
cross_ref_file="$FIXTURE/payments/ERD.md"
# Extract the relative path from the cross-module backlink
ref_path=$(grep -oE '\.\./auth/PRODUCT\.md' "$cross_ref_file" | head -1)
inc_test
if [[ -n "$ref_path" ]]; then
  resolved="$FIXTURE/payments/$ref_path"
  if [[ -f "$resolved" ]]; then
    echo "    ✓ Cross-module path ../auth/PRODUCT.md resolves"
  else
    echo "    ✗ Cross-module path does not resolve to file"
    inc_fail
  fi
else
  echo "    ✗ No cross-module reference found in payments/ERD.md"
  inc_fail
fi

# Check that the anchor exists in the target file
inc_test
if grep -q 'P-MAUTH-LOGIN' "$FIXTURE/auth/PRODUCT.md"; then
  echo "    ✓ Cross-module anchor P-MAUTH-LOGIN exists in target"
else
  echo "    ✗ Cross-module anchor P-MAUTH-LOGIN not found in target"
  inc_fail
fi

echo "  [2.5.4] Broken cross-module references detectable"
BROKEN="$FIXTURES_DIR/broken-cross-refs"

# Broken path: ../moduleGone/PRODUCT.md does not exist
inc_test
ref_gone="$BROKEN/moduleB/../moduleGone/PRODUCT.md"
if [[ ! -f "$ref_gone" ]]; then
  echo "    ✓ Broken path ../moduleGone/PRODUCT.md correctly unresolvable"
else
  echo "    ✗ moduleGone should not exist"
  inc_fail
fi

# Broken anchor: file exists but P-BRKA-NONEXISTENT doesn't
inc_test
if ! grep -q 'P-BRKA-NONEXISTENT' "$BROKEN/moduleA/PRODUCT.md"; then
  echo "    ✓ Broken anchor P-BRKA-NONEXISTENT correctly absent from target"
else
  echo "    ✗ P-BRKA-NONEXISTENT should not exist in moduleA/PRODUCT.md"
  inc_fail
fi

# Valid reference still works
inc_test
if grep -q 'P-BRKA-THING' "$BROKEN/moduleA/PRODUCT.md"; then
  echo "    ✓ Valid cross-ref P-BRKA-THING exists in moduleA"
else
  echo "    ✗ P-BRKA-THING should exist in moduleA/PRODUCT.md"
  inc_fail
fi

finish_tests
