---
scope: Automated testing strategy — test pyramid, tooling, and coverage targets.
see-also:
  - PRODUCT.md — product requirements that define acceptance criteria.
  - ERD.md — technical requirements and interfaces under test.
---

# Automated Testing Strategy

## Source of Truth Hierarchy

<!-- TESTING.md sits between the requirement documents and the tests themselves in
     the ANCHORS truth hierarchy. It defines HOW requirements are verified — which
     test layers cover which requirements, what the coverage invariants are, and
     what is deliberately excluded.

     Key implications: -->

- **External contracts are truthier than everything.** When the ERD describes an external interface (API responses, file formats, CLI behavior), the external source is authoritative. If the external system's actual behavior differs from the ERD, fix the ERD.
- **Tests are truthier than implementation.** When a test and the implementation disagree, the test is assumed correct — until proven otherwise by checking the PRD and ERD.
- **The PRD and ERD are truthier than tests.** If a test encodes behavior that contradicts PRODUCT.md or ERD.md, the test is wrong.

In practice: a failing test means "the implementation is probably broken." A passing test means "the behavior matches what the test author believed was correct." The PRD, ERD, and external contracts are the reference for resolving that belief.

---

## Coverage Invariants

<!-- These are the rules that determine whether test coverage is sufficient.
     They are non-negotiable. Restate the ANCHORS invariants here so TESTING.md
     is self-contained, and add any project-specific invariants below. -->

### Invariant 1: Every product and engineering requirement has a test

Every requirement in PRODUCT.md and ERD.md must be covered by at least one test at the most natural layer. A requirement without a test is a coverage gap.

### Invariant 2: Contract boundaries are tested from both sides

<!-- Identify your system's contract boundaries (external APIs, CLIs, file formats,
     message protocols) and list them here. Each must have:
     - Reading side: Tests verify parsers correctly interpret the external system's output
     - Writing side: Tests verify the system produces correct inputs/commands -->

### Invariant 3: Trust boundaries are tested end-to-end

<!-- If your system has actions requiring human approval vs. automatic actions,
     each side needs an E2E test. Remove this section if not applicable. -->

### Invariant 4: Every public API surface has a test

Every endpoint, event type, or public interface has at least one happy-path and one error-path test.

### Invariant 5: Recovery paths are tested

Crash recovery, restart behavior, and reconnection logic are tested at the integration layer or above.

### Invariant 6: Every interface has its production implementation verified

When test doubles are used, at least one test verifies the production implementation exists and is wired in.

---

## Coverage Mapping: Requirements to Test Layers

<!-- Map functional areas to their primary and secondary test layers.
     Primary carries the bulk of coverage; secondary provides additional confidence.
     This table is how TESTING.md connects P-*/E-* requirements to concrete tests. -->

| Functional Area | Primary Layer | Secondary Layer |
|-----------------|---------------|-----------------|
| **[Area 1]** | Unit ([what]) | Integration ([what]) |
| **[Area 2]** | Integration ([what]) | E2E ([what]) |
| **[Contract boundary]** | Unit (parsers + builders) | Integration ([boundary test]) |
| **[Recovery]** | Integration ([restart scenario]) | E2E ([kill + restart]) |

---

## Pyramid Shape

<!-- Describe and justify your project's test pyramid shape. Most projects
     benefit from a wide unit base, moderate integration layer, and thin E2E layer.
     Explain where bugs are most likely to live in your system. -->

```
                    ┌─────────┐
                    │  E2E    │   [What's real at this layer]
                    │ (smoke) │
                ┌───┴─────────┴───┐
                │  Integration    │   [What's real, what's faked]
                │  (boundaries)   │
        ┌───────┴─────────────────┴───────┐
        │         Unit Tests              │   [What's tested here]
        │  (parsing, state, domain logic) │
        └─────────────────────────────────┘
```

---

## Layer 1: Unit Tests

<!-- Pure logic tests. No I/O. Fast enough to run on every save.
     Organize by component with tables showing test areas and what to test. -->

### 1.1 [Component] — [Concern]

| Test Area | What to Test |
|-----------|-------------|
| **[Parser/builder/logic]** | [Specific scenarios and edge cases] |
| **Malformed input** | [Truncated data, empty files, missing fields, forward compat] |

---

## Layer 2: Integration Tests

<!-- Test component boundaries with real I/O. Each test exercises one boundary
     while faking the other side. Describe your test setup/harness. -->

### 2.1 [Boundary Name]

**Setup:** [How the test environment is configured — temp dirs, fakes, real servers, etc.]

| Test Area | What to Test |
|-----------|-------------|
| **[Happy path]** | [Expected behavior] |
| **[Error cases]** | [Failure modes] |

---

## Layer 3: E2E Tests

<!-- Full stack smoke tests. Validate that layers connect, not that every feature works.
     If you need a simulator for an external dependency, describe it here. -->

| Test | Scenario |
|------|----------|
| **[Workflow name]** | [Start -> middle -> expected end state] |

---

## Test Infrastructure

<!-- Describe reusable test infrastructure:
     - Fixture management (where fixtures live, how they're captured/maintained)
     - Fake/mock implementations and their interfaces
     - Test harnesses (temp dirs, servers, clients)
     - Helper utilities -->

### Fixture Management

```
testdata/
  fixtures/
    [category]/
      [scenario].json
```

---

## Tooling

| Tool | Purpose |
|------|---------|
| [test runner] | [What layers it covers] |
| [linter] | [Static analysis] |
| [coverage tool] | [Coverage reporting] |

---

## Coverage Targets

| Layer | Target | Rationale |
|-------|--------|-----------|
| Unit | [target] | [Why this target for this layer] |
| Integration | [target] | [Why] |
| E2E | [target] | [Why] |

---

## What We Deliberately Don't Test

<!-- Explicitly scope what's out. This prevents agents and contributors from
     writing unnecessary tests. Common exclusions:
     - External systems' correctness (you test your integration, not their behavior)
     - Visual rendering fidelity
     - Performance under load (if single-user)
     - Third-party library internals -->

- **[External system]:** We test our integration with its contract, not its internals.
- **[Other exclusion]:** [Reason.]
