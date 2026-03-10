package auth

// HashPassword hashes a plaintext password for storage.
// E-AUTH-HASH: bcrypt with cost 12.
func HashPassword(plain string) (string, error) {
	return "", nil
}

// InvalidateSession adds a token to the revocation list.
// E-AUTH-INVALIDATE: revocation checked on every request.
func InvalidateSession(token string) error {
	return nil
}

// CreateSession issues a signed JWT.
// E-AUTH-JWT: 24-hour expiry.
func CreateSession(userID string) (string, error) {
	return "", nil
}

// LegacyCleanup references a removed requirement.
// E-AUTH-OLD-THING: this ID no longer exists in any document.
func LegacyCleanup() {}
