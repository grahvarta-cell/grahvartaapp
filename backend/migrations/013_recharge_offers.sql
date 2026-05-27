CREATE TABLE IF NOT EXISTS recharge_offers (
  id SERIAL PRIMARY KEY,
  amount DECIMAL(10,2) NOT NULL,
  bonus_percent INTEGER NOT NULL DEFAULT 0,
  label VARCHAR(50),
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO recharge_offers (amount, bonus_percent, label, sort_order) VALUES
  (50,   50, '50% Extra', 1),
  (100,  50, '50% Extra', 2),
  (200,  25, '25% Extra', 3),
  (500,  20, '20% Extra', 4),
  (1000, 15, '15% Extra', 5)
ON CONFLICT DO NOTHING;

CREATE TABLE IF NOT EXISTS wallet_orders (
  id SERIAL PRIMARY KEY,
  order_id VARCHAR(100) UNIQUE NOT NULL,
  user_id VARCHAR(100) NOT NULL,
  amount_paid DECIMAL(10,2) NOT NULL,
  wallet_credit DECIMAL(10,2) NOT NULL,
  bonus_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT NOW()
);
