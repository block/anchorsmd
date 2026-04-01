---
scope: Product requirements — observable behavior, outcomes, and qualities. No implementation approach.
see-also:
  - ENGINEERING.md — engineering architecture; must not contradict this document.
  - TESTING.md — testing strategy covering these requirements.
  - DEPENDENCIES.md — external dependencies the system cannot supply itself.
---

# Payments: Product Requirements

## 1. Checkout

- <a id="P-PAY-CART"></a>**P-PAY-CART**: Users can add items to a cart and proceed to checkout.

- <a id="P-PAY-CHARGE"></a>**P-PAY-CHARGE**: The system charges the user's payment method at checkout.

- <a id="P-PAY-RECEIPT"></a>**P-PAY-RECEIPT**: Users receive an email receipt after successful payment.

## Open Questions

- **OPEN-REFUND-FLOW**: How should partial refunds work?

## Resolved Questions
