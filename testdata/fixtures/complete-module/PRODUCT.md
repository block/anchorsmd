---
scope: Product requirements — observable behavior, outcomes, and qualities. No implementation approach.
see-also:
  - ERD.md — technical requirements derived from this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies the system cannot supply itself.
---

# Auth: Product Requirements

## 1. Authentication

- <a id="P-AUTH-LOGIN"></a>**P-AUTH-LOGIN**: Users can log in with email and password.

- <a id="P-AUTH-LOGOUT"></a>**P-AUTH-LOGOUT**: Users can log out, invalidating their session.

## 2. Sessions

- <a id="P-AUTH-SESSION"></a>**P-AUTH-SESSION**: Authenticated users receive a session token valid for 24 hours.

## Open Questions

(none)

## Resolved Questions
