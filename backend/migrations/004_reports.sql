-- ── Reports ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  category VARCHAR(100) NOT NULL,
  icon VARCHAR(10) NOT NULL DEFAULT '📄',
  description TEXT,
  inclusions TEXT[] DEFAULT '{}',
  avg_rating DECIMAL(3,2) DEFAULT 4.5,
  unlock_count INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE
);

-- ── Report unlocks ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS report_unlocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  family_member_id UUID REFERENCES family_members(id) ON DELETE SET NULL,
  unlock_method VARCHAR(20) NOT NULL DEFAULT 'plan', -- free | plan | wallet
  ai_content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Prevent duplicate unlocks: one per user+report for self, one per user+report+member
CREATE UNIQUE INDEX IF NOT EXISTS idx_report_unlocks_self
  ON report_unlocks(user_id, report_id) WHERE family_member_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_report_unlocks_family
  ON report_unlocks(user_id, report_id, family_member_id) WHERE family_member_id IS NOT NULL;

-- ── Report plan purchases ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS report_plan_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_name VARCHAR(50) NOT NULL,
  amount_paid DECIMAL(10,2) NOT NULL,
  report_credits INTEGER NOT NULL DEFAULT 1,
  credits_remaining INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Report reviews ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS report_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  report_id UUID NOT NULL REFERENCES reports(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  reviewer_name VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, report_id)
);

CREATE INDEX IF NOT EXISTS idx_report_unlocks_user ON report_unlocks(user_id);
CREATE INDEX IF NOT EXISTS idx_report_reviews_report ON report_reviews(report_id);
CREATE INDEX IF NOT EXISTS idx_report_plan_purchases_user ON report_plan_purchases(user_id, credits_remaining);

-- ── Ensure unique constraint exists (idempotent) ───────────────────────────
DO $$
BEGIN
  -- Deduplicate first so the constraint can be added without error
  WITH ranked AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY name ORDER BY sort_order ASC, id ASC) AS rn
    FROM reports
  )
  DELETE FROM reports WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

  -- Add unique constraint if it doesn't already exist
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'reports_name_unique'
  ) THEN
    ALTER TABLE reports ADD CONSTRAINT reports_name_unique UNIQUE (name);
  END IF;
END $$;

-- ── Seed reports ────────────────────────────────────────────────────────────
INSERT INTO reports (name, category, icon, description, inclusions, avg_rating, unlock_count, sort_order) VALUES
('Life Guidance',         'Understand Yourself',              '🌟', 'Discover your life purpose, soul mission, and the divine blueprint of your existence.',                    ARRAY['Life purpose & soul mission','Key life themes','Karmic lessons to overcome','Best life phases & timings','Spiritual path & growth'],          4.8, 3241, 1),
('Personality Traits',   'Understand Yourself',              '🪬', 'Uncover your true personality, hidden strengths, and the patterns that shape your life.',                   ARRAY['Core personality blueprint','Hidden strengths & talents','Emotional patterns','Social & communication style','Shadow traits to master'],        4.7, 2876, 2),
('Billionaire and Prosper','Get Rich and Prosper',            '💰', 'Unlock your wealth potential and discover the cosmic blueprint to financial abundance.',                     ARRAY['Wealth accumulation potential','Best investment sectors','Financial breakthrough timing','Money mindset analysis','Abundance activation tips'], 4.9, 1982, 3),
('Wealth',               'Get Rich and Prosper',              '💎', 'Deep dive into your wealth yogas and the financial destiny written in your stars.',                          ARRAY['Wealth yogas in chart','Income sources analysis','Property & assets timing','Financial planning guidance','Prosperity affirmations'],           4.6, 1543, 4),
('Career (Salaried Employee)','Plan Your Professional Roadmap','💼','Navigate your corporate journey with cosmic clarity — promotions, best companies and peak years.',          ARRAY['Best career fields for you','Promotion timings','Work relationship dynamics','Skills to sharpen','Career peak years'],                        4.7, 2104, 5),
('Government Job',       'Plan Your Professional Roadmap',    '🏛️','Decode your chances for a government career, best exam periods and department suitability.',                 ARRAY['Government job yogas','Favorable exam periods','Department suitability','Service longevity','Transfer & posting patterns'],                    4.6, 1328, 6),
('Career (Fresher)',      'Plan Your Professional Roadmap',   '🚀','Your first-job guide — best industries, entry timing, and 5-year career roadmap from the stars.',            ARRAY['First job timing','Best industries to enter','Skills that will shine','Early career challenges','5-year career roadmap'],                       4.5, 987,  7),
('Unemployed',           'Plan Your Professional Roadmap',    '🔍','Break the waiting cycle — discover your next breakthrough timing and hidden monetisable skills.',            ARRAY['Unemployment period analysis','Next job breakthrough timing','Hidden skills to monetise','Mindset shifts needed','Opportunities coming ahead'],  4.4, 654,  8),
('Business Owner',       'Growing Your Business',             '📈','Your complete business blueprint — success yogas, best sectors, partnership guidance and profit peaks.',     ARRAY['Business success yogas','Best business types for you','Partnership guidance','Profit peak periods','Expansion timing'],                         4.8, 1765, 9),
('Job vs Business',      'Growing Your Business',             '⚖️','The definitive cosmic answer — should you stay employed or take the entrepreneurial leap?',                  ARRAY['Planetary indicators for each path','Risk tolerance analysis','Financial stability comparison','Timeline for each path','Final recommendation'],   4.7, 2341, 10),
('Marriage',             'Everything About Your Marriage',    '💍','Your marriage blueprint — timing, spouse profile, harmony indicators and post-marriage life.',                ARRAY['Marriage timing','Spouse characteristics','Marital harmony analysis','Compatibility factors','Post-marriage life forecast'],                      4.9, 3102, 11),
('Love or Arrange Marriage','Everything About Your Marriage', '🌸','Discover whether love or arranged marriage is written in your stars — and when it will happen.',             ARRAY['Love or arrange indicators','How & where you meet your partner','Family approval patterns','Marriage success factors','Remedies for delays'],    4.8, 2654, 12),
('Love Navigator',       'The Story of Love',                 '❤️','Navigate your love life with cosmic clarity — attracting the right person and healing heartbreaks.',         ARRAY['Current love energy','Attracting the right partner','Relationship patterns','Heartbreak healing','Love timeline ahead'],                         4.7, 1876, 13),
('Life Partner',         'The Story of Love',                 '👫','A detailed profile of your soulmate — who they are, where you will meet and when.',                          ARRAY['Life partner profile','Where & how you will meet','Relationship compatibility','Soulmate indicators','Partnership timeline'],                     4.8, 2103, 14),
('Multiple Intelligence','Prepare Your Educational Journey',  '🧠','Discover your dominant intelligences and craft a learning path aligned with your cosmic design.',             ARRAY['Dominant intelligences','Your ideal learning style','Memory & concentration patterns','Academic strengths','Skill development path'],            4.6, 892,  15),
('Education',            'Prepare Your Educational Journey',  '🎓','Your full educational destiny — best study periods, higher education timing and scholarship chances.',        ARRAY['Educational success yogas','Best study periods','Higher education timing','Subject suitability','Scholarship & abroad chances'],                 4.5, 743,  16)
ON CONFLICT (name) DO NOTHING;
