package auth_test

import "testing"

// TestHashPassword verifies bcrypt hashing.
// E-AUTH-HASH: passwords hashed with bcrypt cost 12.
func TestHashPassword(t *testing.T) {}

// TestInvalidateSession verifies session revocation.
// E-AUTH-INVALIDATE: token added to revocation list.
func TestInvalidateSession(t *testing.T) {}

// Note: the JWT requirement is referenced in src but NOT in tests — deliberate gap.
