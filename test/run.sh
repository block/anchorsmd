#!/bin/bash
# ANCHORS test runner
# Usage: ./test/run.sh [test_file...]
# If no arguments, runs all test_*.sh files in this directory.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
export REPO_ROOT

PASS=0
FAIL=0
ERRORS=()

run_test_file() {
  local file="$1"
  local name
  name="$(basename "$file" .sh)"
  echo "━━━ ${name} ━━━"
  if bash "$file"; then
    echo "  ✓ ${name} passed"
    PASS=$((PASS + 1))
  else
    echo "  ✗ ${name} FAILED"
    ERRORS+=("$name")
    FAIL=$((FAIL + 1))
  fi
  echo
}

if [[ $# -gt 0 ]]; then
  for f in "$@"; do run_test_file "$f"; done
else
  for f in "$SCRIPT_DIR"/test_*.sh; do
    run_test_file "$f"
  done
fi

echo "━━━━━━━━━━━━━━━━━━━━━━"
echo "Results: ${PASS} passed, ${FAIL} failed"
if [[ ${FAIL} -gt 0 ]]; then
  echo "Failures:"
  for e in "${ERRORS[@]}"; do echo "  - ${e}"; done
  exit 1
fi
