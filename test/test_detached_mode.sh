#!/bin/bash
# Layer 2: Integration — Detached Mode
# Tests: E-ANCHORS-DETACHED-MODE-DETECTION, E-ANCHORS-DETACHED-FRONTMATTER,
#        E-ANCHORS-DETACHED-FORWARD-REF-FORMAT, E-ANCHORS-DETACHED-FORWARD-REF-VALIDATION,
#        E-ANCHORS-DETACHED-NO-INLINE-TAGS, E-ANCHORS-EMBED-PREREQ,
#        E-ANCHORS-EMBED-STRIP-FORWARD-REFS, E-ANCHORS-EMBED-STRIP-FRONTMATTER
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

DETACHED="$FIXTURES_DIR/detached-module"
TARGET="$FIXTURES_DIR/detached-target"
EMBEDDED="$FIXTURES_DIR/complete-module"

echo "  [1] E-ANCHORS-DETACHED-MODE-DETECTION: Detect mode from ANCHORS.md"
assert_grep "Detached module has repo field" '^repo:' "$DETACHED/ANCHORS.md"
assert_no_grep "Embedded module has no repo field" '^repo:' "$EMBEDDED/ANCHORS.md"

echo "  [2] E-ANCHORS-DETACHED-FRONTMATTER: Parse detached frontmatter fields"
assert_grep "Detached has prefix field" '^prefix:' "$DETACHED/ANCHORS.md"
assert_grep "Detached has repo field" '^repo:' "$DETACHED/ANCHORS.md"
assert_grep "Detached has ref field" '^ref:' "$DETACHED/ANCHORS.md"
assert_grep "Detached has path field" '^path:' "$DETACHED/ANCHORS.md"

echo "  [3] E-ANCHORS-DETACHED-FORWARD-REF-FORMAT: Forward refs use → file:symbol"
assert_grep "ERD has → forward reference" '→ ' "$DETACHED/ERD.md"
assert_grep "Forward ref uses backtick-wrapped file:symbol" '→ .*`[^`]*:[^`]*`' "$DETACHED/ERD.md"

echo "  [4] E-ANCHORS-DETACHED-FORWARD-REF-VALIDATION: Validate forward refs"
# Extract forward refs and check against target fixture
repo_path=$(grep '^repo:' "$DETACHED/ANCHORS.md" | sed 's/repo: *//')
target_dir="$DETACHED/$repo_path"

# Valid ref: src/auth/verify.go:VerifyToken should resolve
assert_file_exists "Target file verify.go exists" "$target_dir/src/auth/verify.go"
assert_grep "Symbol VerifyToken found in verify.go" 'VerifyToken' "$target_dir/src/auth/verify.go"

# Valid ref: src/auth/rate.go:RateLimit should resolve
assert_file_exists "Target file rate.go exists" "$target_dir/src/auth/rate.go"
assert_grep "Symbol RateLimit found in rate.go" 'RateLimit' "$target_dir/src/auth/rate.go"

# Broken ref: src/nonexistent.go should not resolve
assert_true "Broken ref file does not exist" "[[ ! -f '$target_dir/src/nonexistent.go' ]]"

echo "  [5] E-ANCHORS-DETACHED-NO-INLINE-TAGS: Target code has no inline req tags"
# In detached mode, the target codebase should not contain P-*/E-* tags
assert_no_grep "Target verify.go has no P-* tags" 'P-DAPI-' "$target_dir/src/auth/verify.go"
assert_no_grep "Target verify.go has no E-* tags" 'E-DAPI-' "$target_dir/src/auth/verify.go"
assert_no_grep "Target rate.go has no P-* tags" 'P-DAPI-' "$target_dir/src/auth/rate.go"
assert_no_grep "Target rate.go has no E-* tags" 'E-DAPI-' "$target_dir/src/auth/rate.go"

echo "  [6] E-ANCHORS-EMBED-PREREQ: Embedded module has no repo field to embed"
assert_no_grep "Embedded module cannot be embedded (no repo)" '^repo:' "$EMBEDDED/ANCHORS.md"

echo "  [7] E-ANCHORS-EMBED-STRIP-FORWARD-REFS: ERD has → lines to strip"
fwd_count=$(grep -c '→ ' "$DETACHED/ERD.md" || true)
assert_true "ERD has forward refs to strip" "[[ $fwd_count -gt 0 ]]"
assert_grep "ERD preserves ← backlinks" '← \[P-' "$DETACHED/ERD.md"

echo "  [8] E-ANCHORS-EMBED-STRIP-FRONTMATTER: Detached frontmatter has fields to strip"
assert_grep "Has repo to strip" '^repo:' "$DETACHED/ANCHORS.md"
assert_grep "Has ref to strip" '^ref:' "$DETACHED/ANCHORS.md"
assert_grep "Has path to strip" '^path:' "$DETACHED/ANCHORS.md"
assert_grep "Has prefix to preserve" '^prefix:' "$DETACHED/ANCHORS.md"

finish_tests
