-- Astro Talk Database Schema

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  avatar_url TEXT,
  date_of_birth DATE,
  time_of_birth TIME,
  birth_place VARCHAR(255),
  latitude DECIMAL(9,6),
  longitude DECIMAL(9,6),
  sun_sign VARCHAR(50),
  moon_sign VARCHAR(50),
  rising_sign VARCHAR(50),
  subscription_plan VARCHAR(50) DEFAULT 'free',
  subscription_expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Zodiac signs reference
CREATE TABLE IF NOT EXISTS zodiac_signs (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) NOT NULL,
  symbol VARCHAR(10),
  element VARCHAR(20),
  ruling_planet VARCHAR(50),
  date_range VARCHAR(50),
  traits TEXT[],
  created_at TIMESTAMP DEFAULT NOW()
);

-- Horoscopes table
CREATE TABLE IF NOT EXISTS horoscopes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  zodiac_sign VARCHAR(50) NOT NULL,
  period_type VARCHAR(20) NOT NULL CHECK (period_type IN ('daily', 'weekly', 'monthly', 'yearly')),
  period_date DATE NOT NULL,
  content TEXT NOT NULL,
  love_score INTEGER CHECK (love_score BETWEEN 0 AND 100),
  friendship_score INTEGER CHECK (friendship_score BETWEEN 0 AND 100),
  work_score INTEGER CHECK (work_score BETWEEN 0 AND 100),
  lucky_number INTEGER,
  lucky_color VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Birth chart data
CREATE TABLE IF NOT EXISTS birth_charts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  planet_positions JSONB NOT NULL DEFAULT '{}',
  house_positions JSONB NOT NULL DEFAULT '{}',
  aspects JSONB NOT NULL DEFAULT '[]',
  chart_svg TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Transits
CREATE TABLE IF NOT EXISTS transits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  planet VARCHAR(50) NOT NULL,
  aspect VARCHAR(50) NOT NULL,
  target_planet VARCHAR(50),
  zodiac_sign VARCHAR(50),
  start_date DATE NOT NULL,
  end_date DATE,
  description TEXT NOT NULL,
  category VARCHAR(20) CHECK (category IN ('love', 'friendship', 'work', 'general')),
  intensity VARCHAR(20) CHECK (intensity IN ('mild', 'moderate', 'strong')),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Sleep stories / Audio content
CREATE TABLE IF NOT EXISTS audio_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  category VARCHAR(50) NOT NULL,
  thumbnail_url TEXT,
  audio_url TEXT,
  duration_seconds INTEGER,
  planet_theme VARCHAR(50),
  zodiac_signs VARCHAR(50)[],
  is_premium BOOLEAN DEFAULT false,
  play_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Courses
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  thumbnail_url TEXT,
  total_lessons INTEGER DEFAULT 0,
  duration_minutes INTEGER,
  difficulty VARCHAR(20) CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
  category VARCHAR(50),
  is_premium BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Course lessons
CREATE TABLE IF NOT EXISTS course_lessons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  video_url TEXT,
  duration_minutes INTEGER,
  lesson_order INTEGER NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User progress on courses
CREATE TABLE IF NOT EXISTS user_course_progress (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  completed_lessons INTEGER DEFAULT 0,
  last_lesson_id UUID REFERENCES course_lessons(id),
  completed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);

-- Affirmations
CREATE TABLE IF NOT EXISTS affirmations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  content TEXT NOT NULL,
  zodiac_sign VARCHAR(50),
  category VARCHAR(50),
  week_start DATE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- User bookmarks
CREATE TABLE IF NOT EXISTS user_bookmarks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  content_type VARCHAR(50) NOT NULL,
  content_id UUID NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  body TEXT,
  type VARCHAR(50),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_horoscopes_sign_period ON horoscopes(zodiac_sign, period_type, period_date);
CREATE INDEX IF NOT EXISTS idx_transits_dates ON transits(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_user_course_progress_user ON user_course_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_audio_content_category ON audio_content(category);

-- Seed zodiac signs
INSERT INTO zodiac_signs (name, symbol, element, ruling_planet, date_range, traits) VALUES
  ('Aries', '♈', 'Fire', 'Mars', 'Mar 21 - Apr 19', ARRAY['Courageous', 'Energetic', 'Enthusiastic']),
  ('Taurus', '♉', 'Earth', 'Venus', 'Apr 20 - May 20', ARRAY['Reliable', 'Patient', 'Practical']),
  ('Gemini', '♊', 'Air', 'Mercury', 'May 21 - Jun 20', ARRAY['Adaptable', 'Witty', 'Communicative']),
  ('Cancer', '♋', 'Water', 'Moon', 'Jun 21 - Jul 22', ARRAY['Intuitive', 'Nurturing', 'Protective']),
  ('Leo', '♌', 'Fire', 'Sun', 'Jul 23 - Aug 22', ARRAY['Generous', 'Creative', 'Charismatic']),
  ('Virgo', '♍', 'Earth', 'Mercury', 'Aug 23 - Sep 22', ARRAY['Analytical', 'Practical', 'Diligent']),
  ('Libra', '♎', 'Air', 'Venus', 'Sep 23 - Oct 22', ARRAY['Diplomatic', 'Fair', 'Social']),
  ('Scorpio', '♏', 'Water', 'Pluto', 'Oct 23 - Nov 21', ARRAY['Intense', 'Passionate', 'Resourceful']),
  ('Sagittarius', '♐', 'Fire', 'Jupiter', 'Nov 22 - Dec 21', ARRAY['Adventurous', 'Optimistic', 'Philosophical']),
  ('Capricorn', '♑', 'Earth', 'Saturn', 'Dec 22 - Jan 19', ARRAY['Ambitious', 'Disciplined', 'Patient']),
  ('Aquarius', '♒', 'Air', 'Uranus', 'Jan 20 - Feb 18', ARRAY['Original', 'Independent', 'Humanitarian']),
  ('Pisces', '♓', 'Water', 'Neptune', 'Feb 19 - Mar 20', ARRAY['Empathetic', 'Artistic', 'Intuitive'])
ON CONFLICT DO NOTHING;

-- Seed sample sleep stories
INSERT INTO audio_content (title, description, category, thumbnail_url, duration_seconds, planet_theme, is_premium) VALUES
  ('Journey to the Moon', 'A calming journey through lunar energy to help you sleep deeply', 'sleep_story', '/assets/moon.jpg', 1800, 'Moon', false),
  ('Journey to Jupiter', 'Expand your consciousness with this Jupiter meditation', 'sleep_story', '/assets/jupiter.jpg', 2100, 'Jupiter', false),
  ('Journey to Mars', 'Channel Mars energy for deep rejuvenating sleep', 'sleep_story', '/assets/mars.jpg', 1500, 'Mars', true),
  ('Venus Dream', 'A love-filled journey through Venusian energy', 'sleep_story', '/assets/venus.jpg', 2400, 'Venus', true),
  ('Saturn Meditation', 'Ground yourself with Saturn''s stabilizing energy', 'meditation', '/assets/saturn.jpg', 1200, 'Saturn', false)
ON CONFLICT DO NOTHING;

-- Seed sample courses
INSERT INTO courses (title, description, total_lessons, duration_minutes, difficulty, category, is_premium) VALUES
  ('Become the Transit Moon Surfer', 'Master the art of reading and working with moon transits', 10, 120, 'beginner', 'transits', false),
  ('Intro to Astrological Rising Signs', 'Deep dive into ascendant signs and their meaning', 8, 90, 'beginner', 'birth_chart', false),
  ('Intro to Kundalini Energy', 'Discover the connection between astrology and kundalini', 12, 150, 'intermediate', 'spirituality', true),
  ('Advanced Birth Chart Reading', 'Learn to interpret complex birth chart configurations', 15, 200, 'advanced', 'birth_chart', true),
  ('Planetary Aspects Masterclass', 'Understand all major and minor planetary aspects', 10, 130, 'intermediate', 'planets', true)
ON CONFLICT DO NOTHING;
