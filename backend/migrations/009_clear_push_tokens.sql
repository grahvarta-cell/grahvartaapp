-- One-time cleanup: remove all stale push tokens.
-- Tokens registered with the old (revoked) Firebase key are invalid.
-- Users will re-register fresh tokens on next app open/login.
TRUNCATE TABLE push_tokens;
