-- Add token_no to agent_hirings
ALTER TABLE agent_hirings
  ADD COLUMN IF NOT EXISTS token_no VARCHAR(20);

-- Backfill existing rows
DO $$
DECLARE
  r   RECORD;
  cnt INTEGER := 1000;
BEGIN
  FOR r IN SELECT id FROM agent_hirings ORDER BY created_at LOOP
    UPDATE agent_hirings
    SET token_no = 'GRH-' || LPAD(cnt::TEXT, 5, '0')
    WHERE id = r.id;
    cnt := cnt + 1;
  END LOOP;
END $$;
