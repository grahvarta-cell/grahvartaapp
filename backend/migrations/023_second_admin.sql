-- Second admin account
-- Default password: Admin@1234  (bcrypt hash below)
-- IMPORTANT: change this password after first login
INSERT INTO users (email, password_hash, name, role)
VALUES (
  'admin2@grahvarta.com',
  '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lihO',
  'Admin 2',
  'admin'
) ON CONFLICT (email) DO NOTHING;
