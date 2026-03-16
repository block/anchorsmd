#!/bin/bash
# Shared test helpers
# Source this from test files: source "$(dirname "$0")/helpers.sh"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
SKILL_FILE="$REPO_ROOT/skill/SKILL.md"
FIXTURES_DIR="$REPO_ROOT/testdata/fixtures"

_test_count=0
_fail_count=0

# Arithmetic increment that doesn't fail under set -e when value is 0
inc_test() { _test_count=$((_test_count + 1)); }
inc_fail() { _fail_count=$((_fail_count + 1)); }

assert_true() {
  local desc="$1"
  shift
  inc_test
  if eval "$*" >/dev/null 2>&1; then
    echo "    ✓ ${desc}"
  else
    echo "    ✗ ${desc}"
    inc_fail
  fi
}

assert_false() {
  local desc="$1"
  shift
  inc_test
  if "$@" >/dev/null 2>&1; then
    echo "    ✗ ${desc} (expected failure but succeeded)"
    inc_fail
  else
    echo "    ✓ ${desc}"
  fi
}

assert_file_exists() {
  local desc="$1"
  local path="$2"
  inc_test
  if [[ -f "$path" ]]; then
    echo "    ✓ ${desc}"
  else
    echo "    ✗ ${desc} (file not found: ${path})"
    inc_fail
  fi
}

assert_grep() {
  local desc="$1"
  local pattern="$2"
  local file="$3"
  inc_test
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "    ✓ ${desc}"
  else
    echo "    ✗ ${desc} (pattern '${pattern}' not found in ${file})"
    inc_fail
  fi
}

assert_no_grep() {
  local desc="$1"
  local pattern="$2"
  local file="$3"
  inc_test
  if grep -qE "$pattern" "$file" 2>/dev/null; then
    echo "    ✗ ${desc} (pattern '${pattern}' unexpectedly found in ${file})"
    inc_fail
  else
    echo "    ✓ ${desc}"
  fi
}

assert_eq() {
  local desc="$1"
  local expected="$2"
  local actual="$3"
  inc_test
  if [[ "$expected" == "$actual" ]]; then
    echo "    ✓ ${desc}"
  else
    echo "    ✗ ${desc} (expected '${expected}', got '${actual}')"
    inc_fail
  fi
}

finish_tests() {
  echo "  ${_test_count} assertions, ${_fail_count} failures"
  [[ $_fail_count -eq 0 ]]
}
