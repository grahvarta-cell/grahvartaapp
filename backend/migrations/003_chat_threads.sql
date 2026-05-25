-- Persistent chat thread per user<>astrologer pair
CREATE TABLE IF NOT EXISTS chat_threads (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  astrologer_id UUID NOT NULL REFERENCES astrologers(id) ON DELETE CASCADE,
  last_message  TEXT,
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  unread_count  INT DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id, astrologer_id)
);

-- All messages across all consultations, linked to thread
CREATE TABLE IF NOT EXISTS thread_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id       UUID NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE,
  consultation_id UUID REFERENCES consultations(id) ON DELETE SET NULL,
  sender_id       UUID NOT NULL REFERENCES users(id),
  sender_role     VARCHAR(20) NOT NULL,  -- 'user' | 'astrologer' | 'system'
  message         TEXT NOT NULL,
  message_type    VARCHAR(20) DEFAULT 'text',  -- 'text' | 'session_start' | 'session_end'
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_thread_messages_thread_id ON thread_messages(thread_id);
CREATE INDEX idx_thread_messages_created_at ON thread_messages(thread_id, created_at DESC);
CREATE INDEX idx_chat_threads_user ON chat_threads(user_id, last_message_at DESC);
