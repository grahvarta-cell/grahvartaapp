-- Fix wallet_orders.user_id from INTEGER to VARCHAR to support UUID user IDs
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'wallet_orders' AND column_name = 'user_id' AND data_type = 'integer'
  ) THEN
    ALTER TABLE wallet_orders ALTER COLUMN user_id TYPE VARCHAR(100) USING user_id::VARCHAR;
  END IF;
END $$;
