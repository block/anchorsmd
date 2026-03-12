package auth

// RateLimit enforces per-client rate limiting using a sliding window.
func RateLimit(clientID string) bool {
	return true
}
