#!/bin/bash
# Layer 2: Integration — Detached Mode
# Tests: E-ANCHORS-DETACHED-ISOLATION, E-ANCHORS-DETACHED-LIFECYCLE
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

DETACHED="$FIXTURES_DIR/detached-module"
INREPO="$FIXTURES_DIR/inrepo-detached/anchors"
TARGET="$FIXTURES_DIR/detached-target"
EMBEDDED="$FIXTURES_DIR/complete-module"

echo "  [1] E-ANCHORS-DETACHED-ISOLATION: Detect mode from mode: detached field"
assert_grep "Detached module has mode: detached" '^mode: detached' "$DETACHED/ANCHORS.md"
assert_no_grep "Embedded module has no mode: detached" '^mode: detached' "$EMBEDDED/ANCHORS.md"

echo "  [2] E-ANCHORS-DETACHED-ISOLATION: External detached has repo, ref, path"
assert_grep "External has prefix" '^prefix:' "$DETACHED/ANCHORS.md"
assert_grep "External has mode: detached" '^mode: detached' "$DETACHED/ANCHORS.md"
assert_grep "External has repo" '^repo:' "$DETACHED/ANCHORS.md"
assert_grep "External has ref" '^ref:' "$DETACHED/ANCHORS.md"
assert_grep "External has path" '^path:' "$DETACHED/ANCHORS.md"

echo "  [3] E-ANCHORS-DETACHED-ISOLATION: In-repo detached has path, no repo/ref"
assert_grep "In-repo has mode: detached" '^mode: detached' "$INREPO/ANCHORS.md"
assert_grep "In-repo has path" '^path:' "$INREPO/ANCHORS.md"
assert_no_grep "In-repo has no repo" '^repo:' "$INREPO/ANCHORS.md"
assert_no_grep "In-repo has no ref" '^ref:' "$INREPO/ANCHORS.md"

echo "  [4] E-ANCHORS-DETACHED-ISOLATION: In-repo path resolves relative to ANCHORS.md"
inrepo_path=$(grep '^path:' "$INREPO/ANCHORS.md" | sed 's/path: *//')
inrepo_target="$INREPO/$inrepo_path"
assert_file_exists "In-repo path resolves to code dir" "$inrepo_target/src/api/handler.go"

echo "  [5] E-ANCHORS-DETACHED-ISOLATION: Forward refs use → file:symbol"
assert_grep "ENGINEERING.md has → forward reference" '→ ' "$DETACHED/ENGINEERING.md"
assert_grep "Forward ref uses backtick-wrapped file:symbol" '→ .*`[^`]*:[^`]*`' "$DETACHED/ENGINEERING.md"

echo "  [6] E-ANCHORS-DETACHED-LIFECYCLE: Validate forward refs with path scoping"
repo_path=$(grep '^repo:' "$DETACHED/ANCHORS.md" | sed 's/repo: *//')
sub_path=$(grep '^path:' "$DETACHED/ANCHORS.md" | sed 's/path: *//')
repo_dir="$DETACHED/$repo_path"
target_dir="$repo_dir/$sub_path"

# Verify path scoping works (files are under app/, not repo root)
assert_true "External path is not root" "[[ '$sub_path' != '/' ]]"
assert_file_exists "Target dir exists at scoped path" "$target_dir/src/auth/verify.go"

# Valid refs (relative to the path-scoped directory)
assert_file_exists "Target file verify.go exists" "$target_dir/src/auth/verify.go"
assert_grep "Symbol VerifyToken found in verify.go" 'VerifyToken' "$target_dir/src/auth/verify.go"
assert_file_exists "Target file rate.go exists" "$target_dir/src/auth/rate.go"
assert_grep "Symbol RateLimit found in rate.go" 'RateLimit' "$target_dir/src/auth/rate.go"
# Broken ref: missing file
assert_true "Broken ref file does not exist" "[[ ! -f '$target_dir/src/nonexistent.go' ]]"
# Broken ref: file exists but symbol missing
assert_file_exists "Broken symbol ref file exists" "$target_dir/src/auth/verify.go"
assert_no_grep "NonexistentSymbol not in verify.go" 'NonexistentSymbol' "$target_dir/src/auth/verify.go"

echo "  [7] E-ANCHORS-DETACHED-ISOLATION: Target code has no inline req tags"
assert_no_grep "Target verify.go has no P-* tags" 'P-DAPI-' "$target_dir/src/auth/verify.go"
assert_no_grep "Target verify.go has no E-* tags" 'E-DAPI-' "$target_dir/src/auth/verify.go"
assert_no_grep "Target rate.go has no P-* tags" 'P-DAPI-' "$target_dir/src/auth/rate.go"
assert_no_grep "Target rate.go has no E-* tags" 'E-DAPI-' "$target_dir/src/auth/rate.go"

echo "  [8] E-ANCHORS-DETACHED-LIFECYCLE: Embedded module has no mode: detached"
assert_no_grep "Embedded module cannot be embedded (no mode: detached)" '^mode: detached' "$EMBEDDED/ANCHORS.md"

echo "  [9] E-ANCHORS-DETACHED-LIFECYCLE: ENGINEERING.md has → lines to strip"
fwd_count=$(grep -c '→ ' "$DETACHED/ENGINEERING.md" || true)
assert_true "ENGINEERING.md has forward refs to strip" "[[ $fwd_count -gt 0 ]]"
assert_grep "ENGINEERING.md preserves ← backlinks" '← \[P-' "$DETACHED/ENGINEERING.md"

echo "  [10] E-ANCHORS-DETACHED-LIFECYCLE: Detached frontmatter has fields to strip"
assert_grep "Has mode to strip" '^mode:' "$DETACHED/ANCHORS.md"
assert_grep "Has prefix to preserve" '^prefix:' "$DETACHED/ANCHORS.md"

finish_tests
