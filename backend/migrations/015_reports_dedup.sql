-- Remove duplicate reports keeping the row with the lowest sort_order per name
WITH ranked AS (
  SELECT id,
         ROW_NUMBER() OVER (PARTITION BY name ORDER BY sort_order ASC, id ASC) AS rn
  FROM reports
)
DELETE FROM reports
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Add unique constraint (valid PostgreSQL idiom for IF NOT EXISTS on constraints)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'reports_name_unique'
  ) THEN
    ALTER TABLE reports ADD CONSTRAINT reports_name_unique UNIQUE (name);
  END IF;
END $$;
