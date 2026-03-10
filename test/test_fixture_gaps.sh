#!/bin/bash
# Layer 2: Integration — Gaps module fixture
# Tests: E-ANCHORS-AUDIT-BACKLINK-CHECK, E-ANCHORS-AUDIT-PRD-COVERAGE,
#        E-ANCHORS-AUDIT-OPEN-SCAN
# Validates TESTING.md §2.4: audit on repo with gaps
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

FIXTURE="$FIXTURES_DIR/gaps-module"

echo "  [2.4.1] Detect missing backlinks"
# E-PAY-IDEMPOTENT has no ← backlink (deliberate gap)
eid="E-PAY-IDEMPOTENT"
line_num=$(grep -n "<a id=\"${eid}\">" "$FIXTURE/ERD.md" | head -1 | cut -d: -f1)
context=$(sed -n "${line_num},$((line_num + 2))p" "$FIXTURE/ERD.md")
inc_test
if echo "$context" | grep -qE '← \[P-'; then
  echo "    ✗ ${eid} should NOT have a backlink (test fixture is wrong)"
  inc_fail
else
  echo "    ✓ ${eid} correctly missing backlink (gap detected)"
fi

echo "  [2.4.2] Detect uncovered PRD requirements"
# P-PAY-CART and P-PAY-RECEIPT have no E-* coverage
inc_test
if grep -qE 'P-PAY-CART' "$FIXTURE/ERD.md"; then
  echo "    ✗ P-PAY-CART should NOT be in ERD (test fixture is wrong)"
  inc_fail
else
  echo "    ✓ P-PAY-CART correctly uncovered (gap detected)"
fi

inc_test
if grep -qE 'P-PAY-RECEIPT' "$FIXTURE/ERD.md"; then
  echo "    ✗ P-PAY-RECEIPT should NOT be in ERD (test fixture is wrong)"
  inc_fail
else
  echo "    ✓ P-PAY-RECEIPT correctly uncovered (gap detected)"
fi

echo "  [2.4.3] Detect open questions"
inc_test
if grep -qE 'OPEN-REFUND-FLOW' "$FIXTURE/PRODUCT.md"; then
  echo "    ✓ OPEN-REFUND-FLOW detected in PRODUCT.md"
else
  echo "    ✗ OPEN-REFUND-FLOW should be present in fixture"
  inc_fail
fi

echo "  [2.4.4] Missing documents detectable"
# gaps-module has no TESTING.md or DEPENDENCIES.md
inc_test
if [[ ! -f "$FIXTURE/TESTING.md" ]]; then
  echo "    ✓ TESTING.md correctly absent (gap detected)"
else
  echo "    ✗ TESTING.md should NOT exist in gaps fixture"
  inc_fail
fi

inc_test
if [[ ! -f "$FIXTURE/DEPENDENCIES.md" ]]; then
  echo "    ✓ DEPENDENCIES.md correctly absent (gap detected)"
else
  echo "    ✗ DEPENDENCIES.md should NOT exist in gaps fixture"
  inc_fail
fi

finish_tests
