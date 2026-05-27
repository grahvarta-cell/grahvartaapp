CREATE TABLE IF NOT EXISTS agent_hirings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(20) NOT NULL UNIQUE,
  name VARCHAR(100),
  dob DATE,
  gender VARCHAR(20),
  languages JSONB DEFAULT '[]',
  skills JSONB DEFAULT '[]',
  profile_picture_url TEXT,
  phone_type VARCHAR(20),
  email VARCHAR(200),
  works_online BOOLEAN DEFAULT false,
  hours_available INTEGER,
  status VARCHAR(20) DEFAULT 'pending',
  admin_notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_agent_hirings_status ON agent_hirings(status);
CREATE INDEX IF NOT EXISTS idx_agent_hirings_created ON agent_hirings(created_at DESC);
