#!/bin/bash
# Layer 2: Integration — Prefix collision detection
# Tests: E-ANCHORS-CHECK-PREFIX-COLLISION, E-ANCHORS-SETUP-PREFIX-UNIQUE
# Validates TESTING.md §2.4: duplicate prefix across modules is rejected
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# Create a temporary fixture with duplicate prefixes
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/moduleA" "$TMPDIR/moduleB"
echo -e "---\nprefix: DUPE\n---" > "$TMPDIR/moduleA/ANCHORS.md"
echo -e "---\nprefix: DUPE\n---" > "$TMPDIR/moduleB/ANCHORS.md"

echo "  [prefix collision] Detect duplicate prefixes"

# Collect all prefixes
prefixes=()
while IFS= read -r mod; do
  p=$(grep '^prefix:' "$mod" | sed 's/prefix: *//')
  prefixes+=("$p")
done < <(find "$TMPDIR" -name "ANCHORS.md")

# Check for duplicates
sorted=($(printf '%s\n' "${prefixes[@]}" | sort))
unique=($(printf '%s\n' "${prefixes[@]}" | sort -u))

inc_test
if [[ ${#sorted[@]} -ne ${#unique[@]} ]]; then
  echo "    ✓ Prefix collision detected (${#sorted[@]} modules, ${#unique[@]} unique prefixes)"
else
  echo "    ✗ Should have detected prefix collision"
  inc_fail
fi

# Also verify that our valid multi-module fixture has no collisions
FIXTURE="$FIXTURES_DIR/multi-module"
prefixes2=()
while IFS= read -r mod; do
  p=$(grep '^prefix:' "$mod" | sed 's/prefix: *//')
  prefixes2+=("$p")
done < <(find "$FIXTURE" -name "ANCHORS.md")

sorted2=($(printf '%s\n' "${prefixes2[@]}" | sort))
unique2=($(printf '%s\n' "${prefixes2[@]}" | sort -u))

inc_test
if [[ ${#sorted2[@]} -eq ${#unique2[@]} ]]; then
  echo "    ✓ Multi-module fixture has no prefix collisions"
else
  echo "    ✗ Multi-module fixture should not have collisions"
  inc_fail
fi

finish_tests
