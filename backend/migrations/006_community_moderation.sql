-- Add moderation status to community posts
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'approved';

-- Any rows that somehow have NULL get approved so they stay visible
UPDATE community_posts SET status = 'approved' WHERE status IS NULL;

CREATE INDEX IF NOT EXISTS idx_community_posts_status ON community_posts(status, created_at DESC);
