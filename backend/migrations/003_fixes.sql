-- Add consultation_id to queue table
ALTER TABLE consultation_queue
  ADD COLUMN IF NOT EXISTS consultation_id UUID REFERENCES consultations(id) ON DELETE CASCADE;
