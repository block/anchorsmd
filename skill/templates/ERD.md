---
scope: Engineering requirements — technical design, interfaces, and implementation constraints. Derived from product requirements.
see-also:
  - PRODUCT.md — product requirements that drive the technical decisions in this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies that the system cannot supply itself.
---

# [Project Name]: Engineering Requirements

This document defines the technical requirements for [project]. These are derived from the [product requirements](PRODUCT.md).

<!-- State the key architectural principle(s) up front. Example:
     "The server treats the CLI as a black box — it interacts exclusively through
      its public interface." -->

---

## 1. [First Technical Area]

<!-- Organize by technical concern, not by product area. ERD sections often
     regroup product requirements around implementation boundaries.

     Every requirement gets:
     - An <a id="E-..."></a> HTML anchor for cross-linking
     - An E- prefixed ID (scoped by the prefix in ANCHORS.md)
     - A ← backlink to the P-* requirement it satisfies

     The backlink is NOT optional. Every E-* must trace to a P-*. -->

- <a id="E-AREA-THING"></a>**E-AREA-THING**: [Technical requirement — how something is implemented, what interfaces it uses, what constraints apply.]
  ← [P-AREA-THING](PRODUCT.md#P-AREA-THING)

- <a id="E-AREA-OTHER"></a>**E-AREA-OTHER**: [Another technical requirement.]
  ← [P-AREA-OTHER](PRODUCT.md#P-AREA-OTHER)

---

## 2. [Second Technical Area]

<!-- Common technical areas:
     - External system contracts (APIs, CLIs, file formats)
     - Internal architecture (server, data model, state management)
     - API surface (endpoints, events, protocols)
     - Security and trust boundaries
     - Recovery and resilience
     - Observability -->

- <a id="E-AREA2-THING"></a>**E-AREA2-THING**: [Technical requirement.]
  ← [P-AREA2-THING](PRODUCT.md#P-AREA2-THING)

---

<!-- Repeat sections as needed. -->

## Open Questions

<!-- Track unresolved engineering decisions here. Same convention as PRODUCT.md. -->

## Resolved Questions

<!-- **~~OPEN-NAME~~**: Resolution text. -->
