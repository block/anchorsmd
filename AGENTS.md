## ANCHORS — REQUIRED FOR ALL CHANGES

This repo uses ANCHORS for requirements-driven development. **You MUST load the anchors skill (`/anchors`) before making any code changes.**

When adding or modifying features, you must update ALL THREE documents before writing code:
1. **PRODUCT.md** — Add a P-* requirement (user-facing behavior only)
2. **ENGINEERING.md** — Add an E-* requirement with `←` backlink to the P-* ID
3. **TESTING.md** — Update the testing strategy so every new/changed requirement has coverage in the appropriate layer sections and coverage invariants. Always verify the document reflects the current scope.

Implementation and test code must include inline requirement ID comments (e.g., `// E-FEATURE-NAME`).
