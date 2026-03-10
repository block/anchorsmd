---
scope: Automated testing strategy — test pyramid, tooling, and coverage targets.
see-also:
  - PRODUCT.md — product requirements that define acceptance criteria.
  - ERD.md — technical requirements and interfaces under test.
---

# Auth: Testing Strategy

## Coverage Mapping

| Functional Area | Primary Layer | Secondary Layer |
|-----------------|---------------|-----------------|
| **Authentication** (P-AUTH-LOGIN, E-AUTH-HASH) | Unit (bcrypt) | Integration (login flow) |
| **Sessions** (P-AUTH-SESSION, E-AUTH-JWT) | Unit (JWT) | Integration (expiry) |
| **Logout** (P-AUTH-LOGOUT, E-AUTH-INVALIDATE) | Integration (revocation) | E2E (full logout) |
