#!/bin/bash
# Layer 2: Integration — Multi-module fixture
# Tests: E-ANCHORS-MONO-MODULE-DETECTION, E-ANCHORS-CHECK-PREFIX-COLLISION,
#        E-ANCHORS-CHECK-CROSS-RESOLVE, E-ANCHORS-MONO-RELATIVE-PATHS,
#        E-ANCHORS-MONO-PARTIAL-MODULES
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

echo "  [2.5.5] E-ANCHORS-MONO-RELATIVE-PATHS: Cross-module refs use relative paths"
# The backlink in payments/ERD.md should use a relative path to ../auth/PRODUCT.md
assert_grep "Cross-ref uses relative path" '\.\./auth/PRODUCT\.md#P-MAUTH-LOGIN' "$FIXTURE/payments/ERD.md"
# Verify it's in a backlink context (← [...](relative path))
assert_grep "Cross-ref uses ← backlink format" '← \[P-MAUTH-LOGIN\]\(\.\./auth/PRODUCT\.md#P-MAUTH-LOGIN\)' "$FIXTURE/payments/ERD.md"

echo "  [2.5.6] E-ANCHORS-MONO-PARTIAL-MODULES: Modules without all 4 docs are valid"
# auth module has only PRODUCT.md and ERD.md (no TESTING.md, no DEPENDENCIES.md)
assert_file_exists "auth has ANCHORS.md" "$FIXTURE/auth/ANCHORS.md"
assert_file_exists "auth has PRODUCT.md" "$FIXTURE/auth/PRODUCT.md"
assert_file_exists "auth has ERD.md" "$FIXTURE/auth/ERD.md"
inc_test
if [[ ! -f "$FIXTURE/auth/TESTING.md" ]]; then
  echo "    ✓ auth module has no TESTING.md (partial module, valid)"
else
  echo "    ✗ auth should not have TESTING.md for this test"
  inc_fail
fi
inc_test
if [[ ! -f "$FIXTURE/auth/DEPENDENCIES.md" ]]; then
  echo "    ✓ auth module has no DEPENDENCIES.md (partial module, valid)"
else
  echo "    ✗ auth should not have DEPENDENCIES.md for this test"
  inc_fail
fi
# payments module also partial — only PRODUCT.md and ERD.md
inc_test
if [[ ! -f "$FIXTURE/payments/TESTING.md" ]]; then
  echo "    ✓ payments module has no TESTING.md (partial module, valid)"
else
  echo "    ✗ payments should not have TESTING.md for this test"
  inc_fail
fi

finish_tests
