const fs = require('fs');
const path = require('path');
const { pool } = require('../src/config/database');
require('dotenv').config();

const migrations = [
  '001_initial.sql',
  '002_marketplace.sql',
  '003_family_members.sql',
  '003_fixes.sql',
  '004_reports.sql',
  '005_admin.sql',
  '006_community_moderation.sql',
  '003_chat_threads.sql',
  '007_withdrawals.sql',
  '008_push_token_app_type.sql',
  '009_clear_push_tokens.sql',
  '010_agent_hirings.sql',
  '011_hiring_token_status.sql',
  '013_recharge_offers.sql',
  '014_fix_wallet_orders_userid.sql',
  '016_hiring_about_me.sql',
  '017_hiring_converted.sql',
  '018_hiring_email_sent.sql',
];

async function runAll() {
  const client = await pool.connect();
  try {
    for (const file of migrations) {
      const filePath = path.join(__dirname, file);
      if (!fs.existsSync(filePath)) { console.warn(`Skipping missing: ${file}`); continue; }
      console.log(`Running ${file}...`);
      const sql = fs.readFileSync(filePath, 'utf8');
      await client.query(sql);
      console.log(`  ✓ ${file}`);
    }
    console.log('All migrations completed.');
  } catch (err) {
    console.error('Migration failed:', err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runAll();
