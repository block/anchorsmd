---
scope: Engineering requirements for detached API fixture.
see-also:
  - PRODUCT.md — product requirements that drive the technical decisions in this document.
---

# Detached API: Engineering Requirements

- <a id="E-DAPI-TOKEN-VERIFY"></a>**E-DAPI-TOKEN-VERIFY**: Tokens are verified via HMAC-SHA256 signature check.
  ← [P-DAPI-AUTH](PRODUCT.md#P-DAPI-AUTH)
  → `src/auth/verify.go:VerifyToken`

- <a id="E-DAPI-RATE-MIDDLEWARE"></a>**E-DAPI-RATE-MIDDLEWARE**: Rate limiting is enforced by middleware using a sliding window counter.
  ← [P-DAPI-RATE-LIMIT](PRODUCT.md#P-DAPI-RATE-LIMIT)
  → `src/auth/rate.go:RateLimit`

- <a id="E-DAPI-BROKEN-REF"></a>**E-DAPI-BROKEN-REF**: This requirement has a broken forward ref for testing.
  ← [P-DAPI-AUTH](PRODUCT.md#P-DAPI-AUTH)
  → `src/nonexistent.go:MissingFunc`

## Open Questions

(none)

## Resolved Questions
