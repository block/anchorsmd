---
scope: Engineering requirements — technical design, interfaces, and implementation constraints. Derived from product requirements.
see-also:
  - PRODUCT.md — product requirements that drive the technical decisions in this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies that the system cannot supply itself.
---

# Payments: Engineering Requirements

## 1. Checkout

- <a id="E-PAY-STRIPE"></a>**E-PAY-STRIPE**: Payments are processed via Stripe Charges API.
  ← [P-PAY-CHARGE](PRODUCT.md#P-PAY-CHARGE)

- <a id="E-PAY-IDEMPOTENT"></a>**E-PAY-IDEMPOTENT**: Charge requests use idempotency keys to prevent double-charging.

- <a id="E-PAY-LOG-FORMAT"></a>**E-PAY-LOG-FORMAT**: Payment events are logged in structured JSON format.
  ← [P-PAY-CHARGE](PRODUCT.md#P-PAY-CHARGE)

## Open Questions

(none)

## Resolved Questions
