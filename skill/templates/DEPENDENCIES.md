---
scope: External dependencies — tools and services that must be present in the environment because the system cannot supply them itself.
boundary: >
  A dependency belongs here if the system has no way to install, build, or bundle it.
  If the system can supply a tool — via a package manager, by building from source,
  or by embedding it — that tool is an ERD requirement, not an external dependency.
  ERD.md owns the "how we supply it" requirements; this document owns the
  "we can't supply it, so it must already be there" constraints.
see-also:
  - ERD.md — engineering requirements, including managed toolchains that eliminate would-be dependencies.
  - PRODUCT.md — product requirements that drive deployment modes.
---

# [Project Name]: External Dependencies

This document enumerates the true external dependencies of the system — tools, services, and runtimes that must be present in the environment because the system cannot provide them itself.

---

## 1. All Environments

<!-- Dependencies required regardless of deployment mode. -->

### D-DEP-EXAMPLE: [tool or service name]

- **Used by:** [Which components depend on it]
- **Where it runs:** [Which environments require it]
- **Why external:** [Why the system cannot bundle, build, or install it]

---

## 2. [Environment-Specific Section]

<!-- Group additional dependencies by deployment mode or environment.
     Examples: "Production", "Development", "CI", "Cloud Mode", "Local Mode".
     Only include sections that add dependencies beyond "All Environments". -->

### D-DEP-EXAMPLE2: [tool or service name]

- **Used by:** [Components]
- **Where it runs:** [Environments]
- **Why external:** [Reason]

---

## Resolved Questions

<!-- Track decisions about what is/isn't an external dependency.
     Format: **~~OPEN-NAME~~**: Resolution text. -->
