---
scope: External dependencies — tools and services that must be present in the environment.
see-also:
  - ERD.md — engineering requirements.
  - PRODUCT.md — product requirements.
---

# Auth: External Dependencies

## 1. All Environments

### D-DEP-POSTGRES: PostgreSQL

- **Used by:** Auth service
- **Where it runs:** All environments
- **Why external:** Stateful service, cannot be bundled
