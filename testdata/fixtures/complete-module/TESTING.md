---
scope: Automated testing strategy — test pyramid, tooling, and coverage targets.
see-also:
  - PRODUCT.md — product requirements that define acceptance criteria.
  - ERD.md — technical requirements and interfaces under test.
---

# Auth: Testing Strategy

## Test Layers

| Layer | Scope | Examples |
|-------|-------|----------|
| **Unit** | Individual functions, algorithms | bcrypt hashing, JWT signing |
| **Integration** | Component interactions, data flow | Login flow, session expiry |
| **E2E** | Full user workflows | Complete login-to-logout cycle |
