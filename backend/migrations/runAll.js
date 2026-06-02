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
  '015_reports_dedup.sql',
  '016_hiring_about_me.sql',
  '017_hiring_converted.sql',
  '018_hiring_email_sent.sql',
  '019_astrologer_ban.sql',
  '020_must_change_password.sql',
  '021_sub_admins.sql',
  '022_hiring_temp_password.sql',
  '023_second_admin.sql',
];

async function runAll() {
  const client = await pool.connect();
  try {
    // Create migration tracking table
    await client.query(`
      CREATE TABLE IF NOT EXISTS _migrations (
        name VARCHAR(255) PRIMARY KEY,
        run_at TIMESTAMP DEFAULT NOW()
      )
    `);

    // Check if this is an existing deployment (users table already populated)
    // If the tracking table is brand new (empty) but users table has data,
    // pre-populate tracking with all previously-known migrations so we don't re-run them.
    const trackCount = await client.query('SELECT COUNT(*) FROM _migrations');
    if (parseInt(trackCount.rows[0].count) === 0) {
      const usersExist = await client.query(`
        SELECT EXISTS (
          SELECT 1 FROM information_schema.tables WHERE table_name = 'users'
        )
      `);
      if (usersExist.rows[0].exists) {
        const userCount = await client.query('SELECT COUNT(*) FROM users');
        if (parseInt(userCount.rows[0].count) > 0) {
          // Existing deployment — mark all migrations up to 022 as already applied
          console.log('Existing deployment detected — pre-marking migrations 001-022 as applied...');
          const alreadyApplied = migrations.filter(m => m !== '023_second_admin.sql');
          for (const m of alreadyApplied) {
            await client.query(
              'INSERT INTO _migrations (name) VALUES ($1) ON CONFLICT DO NOTHING',
              [m]
            );
          }
          console.log('  ✓ Pre-populated migration history');
        }
      }
    }

    // Run only migrations not yet tracked
    for (const file of migrations) {
      const filePath = path.join(__dirname, file);
      if (!fs.existsSync(filePath)) {
        console.warn(`Skipping missing file: ${file}`);
        continue;
      }

      const already = await client.query('SELECT 1 FROM _migrations WHERE name = $1', [file]);
      if (already.rows.length) {
        console.log(`  ✓ ${file} (already applied)`);
        continue;
      }

      console.log(`Running ${file}...`);
      const sql = fs.readFileSync(filePath, 'utf8');
      await client.query(sql);
      await client.query('INSERT INTO _migrations (name) VALUES ($1)', [file]);
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
