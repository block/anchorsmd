#!/bin/bash
# Layer 1: Unit / Static — Template Integrity
# Tests: E-ANCHORS-FRONTMATTER, E-ANCHORS-INIT-TEMPLATE-COPY
# Validates TESTING.md §1.1: frontmatter, placeholders, anchor format, no stale IDs
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

TEMPLATES=("PRODUCT.md" "ERD.md" "TESTING.md" "DEPENDENCIES.md")

echo "  [1.1] Template frontmatter"
for tmpl in "${TEMPLATES[@]}"; do
  file="$TEMPLATES_DIR/$tmpl"
  assert_file_exists "${tmpl} exists" "$file"
  assert_grep "${tmpl} has YAML frontmatter open" "^---" "$file"
  assert_grep "${tmpl} has scope field" "^scope:" "$file"
  assert_grep "${tmpl} has see-also field" "^see-also:" "$file"
done

echo "  [1.2] Placeholder substitution"
for tmpl in "${TEMPLATES[@]}"; do
  file="$TEMPLATES_DIR/$tmpl"
  assert_grep "${tmpl} contains [Project Name] placeholder" '\[Project Name\]' "$file"
done

echo "  [1.3] Anchor format in templates"
# PRODUCT.md and ERD.md templates should have example anchors in the correct format
assert_grep "PRODUCT.md has anchor format example" '<a id="P-' "$TEMPLATES_DIR/PRODUCT.md"
assert_grep "ERD.md has anchor format example" '<a id="E-' "$TEMPLATES_DIR/ERD.md"
assert_grep "DEPENDENCIES.md has D-DEP example" 'D-DEP-' "$TEMPLATES_DIR/DEPENDENCIES.md"

echo "  [1.4] No real requirement IDs in templates"
# Templates should only have generic/example IDs, not IDs scoped to a real prefix
# Real IDs would look like P-AUTH-*, E-PAY-*, etc. Template IDs use AREA/AREA2/EXAMPLE
for tmpl in "${TEMPLATES[@]}"; do
  file="$TEMPLATES_DIR/$tmpl"
  # Should not contain the ANCHORS project's own requirement IDs
  assert_no_grep "${tmpl} has no ANCHORS-prefixed P-IDs" 'P-ANCHORS-' "$file"
  assert_no_grep "${tmpl} has no ANCHORS-prefixed E-IDs" 'E-ANCHORS-' "$file"
done

echo "  [1.5] ERD template has backlink example"
assert_grep "ERD.md template shows ← backlink syntax" '← \[P-' "$TEMPLATES_DIR/ERD.md"

finish_tests
