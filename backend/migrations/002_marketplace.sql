-- ============================================================
-- Migration 002: Full Marketplace, Consultation, Wallet System
-- ============================================================

-- Astrologer profiles
CREATE TABLE IF NOT EXISTS astrologers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  display_name VARCHAR(255) NOT NULL,
  bio TEXT,
  avatar_url TEXT,
  experience_years INTEGER DEFAULT 0,
  languages VARCHAR(50)[] DEFAULT ARRAY['English'],
  specializations VARCHAR(100)[] DEFAULT ARRAY[]::VARCHAR[],
  expertise_areas VARCHAR(100)[] DEFAULT ARRAY[]::VARCHAR[],
  per_minute_rate_chat DECIMAL(10,2) DEFAULT 10.00,
  per_minute_rate_call DECIMAL(10,2) DEFAULT 15.00,
  per_minute_rate_video DECIMAL(10,2) DEFAULT 20.00,
  total_consultations INTEGER DEFAULT 0,
  total_minutes INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.00,
  review_count INTEGER DEFAULT 0,
  is_online BOOLEAN DEFAULT false,
  is_verified BOOLEAN DEFAULT false,
  is_available BOOLEAN DEFAULT true,
  verification_badge VARCHAR(50),
  queue_count INTEGER DEFAULT 0,
  wallet_balance DECIMAL(10,2) DEFAULT 0.00,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Astrologer availability slots
CREATE TABLE IF NOT EXISTS astrologer_availability (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  astrologer_id UUID REFERENCES astrologers(id) ON DELETE CASCADE,
  day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6),
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  is_active BOOLEAN DEFAULT true
);

-- Astrologer reviews
CREATE TABLE IF NOT EXISTS astrologer_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  astrologer_id UUID REFERENCES astrologers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  consultation_id UUID,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  is_anonymous BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(astrologer_id, user_id, consultation_id)
);

-- Consultations (chat/call/video sessions)
CREATE TABLE IF NOT EXISTS consultations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  astrologer_id UUID REFERENCES astrologers(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('chat', 'voice', 'video')),
  status VARCHAR(30) NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','queued','connecting','active','completed','cancelled','failed','refunded')),
  started_at TIMESTAMP,
  ended_at TIMESTAMP,
  duration_seconds INTEGER DEFAULT 0,
  per_minute_rate DECIMAL(10,2) NOT NULL,
  total_amount DECIMAL(10,2) DEFAULT 0.00,
  user_wallet_deducted DECIMAL(10,2) DEFAULT 0.00,
  astrologer_earning DECIMAL(10,2) DEFAULT 0.00,
  platform_fee DECIMAL(10,2) DEFAULT 0.00,
  session_token VARCHAR(255),
  webrtc_room_id VARCHAR(255),
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Chat messages inside consultations
CREATE TABLE IF NOT EXISTS consultation_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  consultation_id UUID REFERENCES consultations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES users(id),
  sender_type VARCHAR(20) NOT NULL CHECK (sender_type IN ('user','astrologer','system')),
  message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text','image','audio','system')),
  content TEXT,
  media_url TEXT,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Consultation queue
CREATE TABLE IF NOT EXISTS consultation_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  astrologer_id UUID REFERENCES astrologers(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  consultation_type VARCHAR(20) NOT NULL,
  position INTEGER NOT NULL,
  estimated_wait_minutes INTEGER,
  status VARCHAR(20) DEFAULT 'waiting' CHECK (status IN ('waiting','called','cancelled')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- User wallets
CREATE TABLE IF NOT EXISTS wallets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
  balance DECIMAL(10,2) DEFAULT 0.00,
  currency VARCHAR(10) DEFAULT 'INR',
  total_added DECIMAL(10,2) DEFAULT 0.00,
  total_spent DECIMAL(10,2) DEFAULT 0.00,
  total_refunded DECIMAL(10,2) DEFAULT 0.00,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Wallet transactions
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wallet_id UUID REFERENCES wallets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL CHECK (type IN ('credit','debit','refund','cashback','bonus')),
  amount DECIMAL(10,2) NOT NULL,
  balance_before DECIMAL(10,2),
  balance_after DECIMAL(10,2),
  description TEXT,
  reference_id VARCHAR(255),
  reference_type VARCHAR(50),
  payment_gateway VARCHAR(50),
  gateway_transaction_id VARCHAR(255),
  status VARCHAR(20) DEFAULT 'success' CHECK (status IN ('pending','success','failed','refunded')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Subscription plans
CREATE TABLE IF NOT EXISTS subscription_plans (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  duration_days INTEGER NOT NULL,
  features JSONB DEFAULT '[]',
  free_minutes INTEGER DEFAULT 0,
  discount_percent INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  plan_id UUID REFERENCES subscription_plans(id),
  starts_at TIMESTAMP NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  amount_paid DECIMAL(10,2),
  transaction_id UUID REFERENCES wallet_transactions(id),
  status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active','expired','cancelled')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Live streaming sessions
CREATE TABLE IF NOT EXISTS live_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  astrologer_id UUID REFERENCES astrologers(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  stream_key VARCHAR(255),
  stream_url TEXT,
  agora_channel VARCHAR(255),
  status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled','live','ended')),
  viewer_count INTEGER DEFAULT 0,
  peak_viewer_count INTEGER DEFAULT 0,
  total_tips DECIMAL(10,2) DEFAULT 0.00,
  scheduled_at TIMESTAMP,
  started_at TIMESTAMP,
  ended_at TIMESTAMP,
  duration_seconds INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Live session tips
CREATE TABLE IF NOT EXISTS live_tips (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  session_id UUID REFERENCES live_sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  amount DECIMAL(10,2) NOT NULL,
  message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Community posts
CREATE TABLE IF NOT EXISTS community_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  astrologer_id UUID REFERENCES astrologers(id),
  content TEXT NOT NULL,
  media_url TEXT,
  media_type VARCHAR(20),
  category VARCHAR(50),
  zodiac_sign VARCHAR(50),
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  is_pinned BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Community post likes
CREATE TABLE IF NOT EXISTS post_likes (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, post_id)
);

-- Community comments
CREATE TABLE IF NOT EXISTS post_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Push notification tokens
CREATE TABLE IF NOT EXISTS push_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform VARCHAR(20) CHECK (platform IN ('android','ios','web')),
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- User notifications log
CREATE TABLE IF NOT EXISTS user_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  body TEXT,
  type VARCHAR(50),
  data JSONB DEFAULT '{}',
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_astrologers_online ON astrologers(is_online, is_available);
CREATE INDEX IF NOT EXISTS idx_astrologers_rating ON astrologers(rating DESC);
CREATE INDEX IF NOT EXISTS idx_consultations_user ON consultations(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_consultations_astrologer ON consultations(astrologer_id, status);
CREATE INDEX IF NOT EXISTS idx_messages_consultation ON consultation_messages(consultation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_wallet_tx_user ON wallet_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_live_sessions_status ON live_sessions(status, scheduled_at);
CREATE INDEX IF NOT EXISTS idx_community_posts ON community_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON user_notifications(user_id, is_read);

-- Seed subscription plans
INSERT INTO subscription_plans (name, price, duration_days, features, free_minutes, discount_percent) VALUES
  ('Basic', 0, 0, '["5 free daily predictions","Basic horoscope","Community access"]', 0, 0),
  ('Silver', 299, 30, '["Unlimited horoscopes","5 free chat minutes/month","Priority queue","Ad-free"]', 5, 10),
  ('Gold', 599, 30, '["All Silver features","15 free chat minutes/month","10% call discount","Birth chart PDF"]', 15, 20),
  ('Platinum', 999, 30, '["All Gold features","30 free minutes/month","20% discount on all calls","Exclusive live sessions","Personal astrologer"]', 30, 30)
ON CONFLICT DO NOTHING;

-- Seed sample astrologers
INSERT INTO users (email, password_hash, name, sun_sign) VALUES
  ('astro1@astrotalk.com', '$2a$12$placeholder', 'Pandit Raj Sharma', 'Aries'),
  ('astro2@astrotalk.com', '$2a$12$placeholder', 'Dr. Priya Nair', 'Libra'),
  ('astro3@astrotalk.com', '$2a$12$placeholder', 'Acharya Vikram', 'Scorpio')
ON CONFLICT DO NOTHING;

-- Seed community posts
INSERT INTO community_posts (user_id, content, category, zodiac_sign)
SELECT id, 'Mercury retrograde ends this week! Time to move forward with clarity and confidence. ✨', 'astrology', 'Gemini'
FROM users WHERE email = 'astro1@astrotalk.com'
ON CONFLICT DO NOTHING;
