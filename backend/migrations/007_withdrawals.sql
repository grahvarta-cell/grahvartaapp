-- Astrologer payout details
CREATE TABLE IF NOT EXISTS astrologer_payout_details (
  id                        SERIAL PRIMARY KEY,
  astrologer_id             INTEGER NOT NULL UNIQUE REFERENCES astrologers(id) ON DELETE CASCADE,
  method                    VARCHAR(20) NOT NULL CHECK (method IN ('upi','paytm','bank')),
  upi_id                    VARCHAR(100),
  paytm_number              VARCHAR(20),
  bank_account_number       VARCHAR(30),
  bank_ifsc                 VARCHAR(20),
  bank_account_name         VARCHAR(100),
  bank_name                 VARCHAR(100),
  razorpay_contact_id       VARCHAR(50),
  razorpay_fund_account_id  VARCHAR(50),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Withdrawal requests
CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id                    SERIAL PRIMARY KEY,
  astrologer_id         INTEGER NOT NULL REFERENCES astrologers(id) ON DELETE CASCADE,
  amount                NUMERIC(12,2) NOT NULL,
  method                VARCHAR(20) NOT NULL,
  status                VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','rejected')),
  process_after         TIMESTAMPTZ NOT NULL,
  processed_at          TIMESTAMPTZ,
  razorpay_payout_id    VARCHAR(50),
  remarks               TEXT,
  requested_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_astrologer ON withdrawal_requests(astrologer_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status_process ON withdrawal_requests(status, process_after);

-- Consultation complaints
CREATE TABLE IF NOT EXISTS consultation_complaints (
  id                SERIAL PRIMARY KEY,
  consultation_id   INTEGER NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
  user_id           INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason            TEXT NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add missing columns to astrologers (safe, ignored if already exist)
ALTER TABLE astrologers ADD COLUMN IF NOT EXISTS wallet_balance   NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE astrologers ADD COLUMN IF NOT EXISTS on_hold_amount   NUMERIC(12,2) NOT NULL DEFAULT 0;
ALTER TABLE astrologers ADD COLUMN IF NOT EXISTS last_withdrawal_at TIMESTAMPTZ;

-- Add astrologer_earning to consultations if missing
ALTER TABLE consultations ADD COLUMN IF NOT EXISTS astrologer_earning NUMERIC(12,2) DEFAULT 0;
