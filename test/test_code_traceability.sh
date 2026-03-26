#!/bin/bash
# Layer 2: Integration — Code and test traceability
# Tests: E-ANCHORS-CHECK-CODE-SEARCH, E-ANCHORS-CHECK-STALE-REFS,
#        E-ANCHORS-CHECK-TEST-GAP
# Validates TESTING.md §2.3: code traceability in well-formed repo
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

FIXTURE="$FIXTURES_DIR/complete-module"

# Collect known requirement IDs from documents
p_ids=$(grep -oE 'P-AUTH-[A-Z0-9-]+' "$FIXTURE/PRODUCT.md" | sort -u)
e_ids=$(grep -oE 'E-AUTH-[A-Z0-9-]+' "$FIXTURE/ERD.md" | sort -u)
all_ids=$(printf '%s\n%s\n' "$p_ids" "$e_ids" | sort -u)

echo "  [1] E-ANCHORS-CHECK-CODE-SEARCH: Find requirement IDs in source files"

# Search source files (non-test) for requirement references
src_refs=$(grep -rhoE '[EP]-AUTH-[A-Z0-9-]+' "$FIXTURE/src/" 2>/dev/null | sort -u || true)
src_count=$(echo "$src_refs" | grep -c '[A-Z]' || true)
assert_true "Found requirement refs in source files (${src_count})" [[ "$src_count" -gt 0 ]]

# Verify specific known refs exist
assert_grep "E-AUTH-HASH referenced in source" 'E-AUTH-HASH' "$FIXTURE/src/auth.go"
assert_grep "E-AUTH-INVALIDATE referenced in source" 'E-AUTH-INVALIDATE' "$FIXTURE/src/auth.go"
assert_grep "E-AUTH-JWT referenced in source" 'E-AUTH-JWT' "$FIXTURE/src/auth.go"

echo "  [2] E-ANCHORS-CHECK-CODE-SEARCH: Classify files as impl vs test"

# Source files should be classified as implementation
inc_test
if [[ -f "$FIXTURE/src/auth.go" ]] && [[ "$FIXTURE/src/auth.go" != *_test.go ]]; then
  echo "    ✓ src/auth.go classified as implementation (not *_test.go)"
else
  echo "    ✗ src/auth.go classification failed"
  inc_fail
fi

# Test files should be classified as test
inc_test
if [[ "$FIXTURE/test/auth_test.go" == *_test.go ]]; then
  echo "    ✓ test/auth_test.go classified as test (*_test.go pattern)"
else
  echo "    ✗ test/auth_test.go classification failed"
  inc_fail
fi

echo "  [3] E-ANCHORS-CHECK-STALE-REFS: Detect references to nonexistent IDs"

# Find all requirement-like IDs in code
code_refs=$(grep -rhoE '[EP]-AUTH-[A-Z0-9-]+' "$FIXTURE/src/" "$FIXTURE/test/" 2>/dev/null | sort -u || true)

# Check each code ref against known document IDs
stale_found=0
while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  if ! echo "$all_ids" | grep -qF "$ref"; then
    stale_found=$((stale_found + 1))
    stale_example="$ref"
  fi
done <<< "$code_refs"

inc_test
if [[ $stale_found -gt 0 ]]; then
  echo "    ✓ Detected ${stale_found} stale ref(s) (e.g., ${stale_example})"
else
  echo "    ✗ Should have detected stale ref E-AUTH-OLD-THING in src/auth.go"
  inc_fail
fi

# Verify the specific stale ref
assert_grep "E-AUTH-OLD-THING is in source code" 'E-AUTH-OLD-THING' "$FIXTURE/src/auth.go"
inc_test
if ! echo "$all_ids" | grep -qF "E-AUTH-OLD-THING"; then
  echo "    ✓ E-AUTH-OLD-THING is not in any document (confirmed stale)"
else
  echo "    ✗ E-AUTH-OLD-THING should not be in documents"
  inc_fail
fi

echo "  [4] E-ANCHORS-CHECK-TEST-GAP: Requirements in code but not in tests"

# Find refs in impl files only
impl_refs=$(grep -rhoE '[EP]-AUTH-[A-Z0-9-]+' "$FIXTURE/src/" 2>/dev/null | sort -u || true)
# Find refs in test files only
test_refs=$(grep -rhoE '[EP]-AUTH-[A-Z0-9-]+' "$FIXTURE/test/" 2>/dev/null | sort -u || true)

# Find refs in impl but not in tests (excluding stale refs)
gap_count=0
gap_example=""
while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  # Only count if it's a real document ID (not stale)
  if echo "$all_ids" | grep -qF "$ref"; then
    if ! echo "$test_refs" | grep -qF "$ref"; then
      gap_count=$((gap_count + 1))
      gap_example="$ref"
    fi
  fi
done <<< "$impl_refs"

inc_test
if [[ $gap_count -gt 0 ]]; then
  echo "    ✓ Detected ${gap_count} test gap(s) (e.g., ${gap_example})"
else
  echo "    ✗ Should have detected E-AUTH-JWT as in code but not in tests"
  inc_fail
fi

# Verify the specific gap: E-AUTH-JWT is in src but not in test
assert_grep "E-AUTH-JWT in source" 'E-AUTH-JWT' "$FIXTURE/src/auth.go"
assert_no_grep "E-AUTH-JWT NOT in tests" 'E-AUTH-JWT' "$FIXTURE/test/auth_test.go"

finish_tests
