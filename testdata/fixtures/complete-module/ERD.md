---
scope: Engineering requirements — how the system achieves the product requirements. Technical decisions, mechanisms, and interfaces. Derived from product requirements.
see-also:
  - PRODUCT.md — product requirements that drive the technical decisions in this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies that the system cannot supply itself.
---

# Auth: Engineering Requirements

## 1. Authentication

- <a id="E-AUTH-HASH"></a>**E-AUTH-HASH**: Passwords are hashed with bcrypt (cost 12) before storage.
  ← [P-AUTH-LOGIN](PRODUCT.md#P-AUTH-LOGIN)

- <a id="E-AUTH-INVALIDATE"></a>**E-AUTH-INVALIDATE**: Logout adds the session token to a revocation list checked on every request.
  ← [P-AUTH-LOGOUT](PRODUCT.md#P-AUTH-LOGOUT)

## 2. Sessions

- <a id="E-AUTH-JWT"></a>**E-AUTH-JWT**: Sessions use signed JWTs with 24-hour expiry.
  ← [P-AUTH-SESSION](PRODUCT.md#P-AUTH-SESSION)

## Open Questions

(none)

## Resolved Questions
