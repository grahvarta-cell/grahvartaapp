-- Remove duplicate reports keeping the row with the lowest sort_order per name
WITH ranked AS (
  SELECT id,
         ROW_NUMBER() OVER (PARTITION BY name ORDER BY sort_order ASC, id ASC) AS rn
  FROM reports
)
DELETE FROM reports
WHERE id IN (SELECT id FROM ranked WHERE rn > 1);

-- Add unique constraint so the seed never duplicates again
ALTER TABLE reports ADD CONSTRAINT IF NOT EXISTS reports_name_unique UNIQUE (name);
