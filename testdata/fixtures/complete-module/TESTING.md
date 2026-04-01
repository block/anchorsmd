---
scope: Automated testing strategy — test pyramid, tooling, and coverage targets.
see-also:
  - PRODUCT.md — product requirements that define acceptance criteria.
  - ENGINEERING.md — technical requirements and interfaces under test.
---

# Auth: Testing Strategy

## How We Test

Auth is tested at two layers: unit tests for cryptographic operations (hashing, JWT signing/verification) and integration tests for authentication flows (login, logout, session validation). Both layers run in CI on every push.

## Coverage Invariants

1. **Every requirement has a test.** All P-AUTH-* and E-AUTH-* requirements are covered by at least one test.
2. **Contract boundaries are tested from both sides.** JWT signing (creation) and verification (validation) are both tested.
3. **Trust boundaries are tested end-to-end.** Login and logout flows are tested as full request cycles.
4. **Every public API surface has a test.** Login, logout, and session endpoints have happy-path and error-path tests.
5. **Recovery paths are tested.** Expired token rejection and revoked session handling are tested at the integration layer.
6. **Every interface has its production implementation verified.** No test doubles mask missing implementations.

## Pyramid Shape

```
            ┌───────────┐
            │Integration│  Login/logout flows, session validation
        ┌───┴───────────┴───┐
        │       Unit        │  bcrypt hashing, JWT sign/verify
        └───────────────────┘
```

## Layer 1: Unit

| Test Area | What to Test |
|-----------|-------------|
| **Password hashing** | bcrypt hash generation and verification (E-AUTH-HASH) |
| **JWT operations** | Token signing, verification, and expiry detection (E-AUTH-JWT) |

## Layer 2: Integration

| Test Area | What to Test |
|-----------|-------------|
| **Login flow** | Valid credentials return session token; invalid credentials rejected (P-AUTH-LOGIN, E-AUTH-HASH) |
| **Logout flow** | Logout invalidates session; subsequent requests rejected (P-AUTH-LOGOUT, E-AUTH-INVALIDATE) |
| **Session expiry** | Tokens older than 24 hours are rejected (P-AUTH-SESSION, E-AUTH-JWT) |

## Test Infrastructure

```
test/
  auth_test.go       # Unit and integration tests
```

Tests use Go's `testing` package. No external test dependencies.

## Tooling

| Tool | Purpose |
|------|---------|
| `go test` | Test runner for unit and integration tests |

## Coverage Targets

| Layer | Target | Rationale |
|-------|--------|-----------|
| Unit | 100% of crypto operations | Hashing and JWT logic must be fully verified |
| Integration | 100% of auth flows | Every login/logout/session path must be exercised |

## What We Deliberately Don't Test

- **Transport-layer security (TLS).** Handled by the deployment environment, not the application.
- **Password strength validation.** A product decision not yet specified in requirements.
