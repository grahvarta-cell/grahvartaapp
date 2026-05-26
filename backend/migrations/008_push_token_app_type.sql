-- Add app_type to push_tokens to distinguish user app vs astrologer app tokens.
-- Tokens from flutter_app (com.grahvarta.app) get 'user_app'.
-- Tokens from astrologer_app (com.grahvartaastrology.app) get 'astrologer_app'.

ALTER TABLE push_tokens
  ADD COLUMN IF NOT EXISTS app_type VARCHAR(30)
    CHECK (app_type IN ('user_app', 'astrologer_app'))
    DEFAULT 'user_app';

-- Existing tokens (all registered before the split) belong to the user app.
UPDATE push_tokens SET app_type = 'user_app' WHERE app_type IS NULL;

-- The unique constraint must now include app_type so the same device token
-- can appear once per app (an astrologer could install both apps).
ALTER TABLE push_tokens DROP CONSTRAINT IF EXISTS push_tokens_user_id_token_key;
ALTER TABLE push_tokens ADD CONSTRAINT push_tokens_user_id_token_app_key UNIQUE (user_id, token, app_type);

CREATE INDEX IF NOT EXISTS idx_push_tokens_app_type ON push_tokens(app_type);
