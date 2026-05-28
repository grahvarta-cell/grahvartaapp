const db = require('../config/database');
const axios = require('axios');
const { sendPushNotification } = require('./liveController');

const GEMINI_API_KEY = 'AIzaSyDEttTAsBBMvNivPbs8YPOCo-rInvQ5oyU';
const GEMINI_API_URL = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

const REPORT_PLANS = [
  { name: 'silver',  label: 'Silver',  actualPrice: 2999, price: 664, discount: 78, credits: 1 },
  { name: 'gold',    label: 'Gold',    actualPrice: 5999, price: 759, discount: 87, credits: 1 },
  { name: 'diamond', label: 'Diamond', actualPrice: 11900, price: 854, discount: 93, credits: 1 },
];

// ── AI content generation ─────────────────────────────────────────────────────
async function generateAiContent(reportName, inclusions, person, language = 'English') {
  const { name, date_of_birth, time_of_birth, birth_place } = person;
  const dob = date_of_birth ? new Date(date_of_birth).toDateString() : 'Not provided';
  const inclusionList = Array.isArray(inclusions) && inclusions.length
    ? inclusions.map((item, i) => `${i + 1}. ${item}`).join('\n')
    : null;

  const today = new Date().toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' });
  const prompt = `Vedic astrologer. Today is ${today}. Write "${reportName}" report for ${name} (DOB: ${dob}, Time: ${time_of_birth || 'unknown'}, Place: ${birth_place || 'unknown'}).

Sections (## heading each):
${inclusionList || `All aspects of ${reportName}`}

Rules: write entirely in ${language}, personalise with ${name}'s name, cite planets/houses, include specific upcoming dates and date ranges for key transits and predictions (e.g. "Venus enters Taurus from 12 May–6 June 2025"), 80-120 words per section, no repetition, concise premium tone.`;

  try {
    const response = await axios.post(
      `${GEMINI_API_URL}?key=${GEMINI_API_KEY}`,
      {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 8192, temperature: 0.8, thinkingConfig: { thinkingBudget: 0 } },
      },
      { headers: { 'Content-Type': 'application/json' }, timeout: 30000 }
    );
    return response.data.candidates[0].content.parts[0].text;
  } catch (err) {
    console.error('AI generation error:', err.message);
    return `## ${reportName} Report for ${name}\n\nYour personalized report is being prepared. Please check back shortly.`;
  }
}

// ── Free status ───────────────────────────────────────────────────────────────
exports.getFreeStatus = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT COUNT(*) FROM report_unlocks WHERE user_id=$1 AND unlock_method='free'`,
      [req.user.id]
    );
    res.json({ success: true, data: { free_used: parseInt(result.rows[0].count) > 0 } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ── User credits summary ──────────────────────────────────────────────────────
exports.getCredits = async (req, res) => {
  try {
    const userId = req.user.id;
    const [freeResult, planResult, walletResult] = await Promise.all([
      db.query(`SELECT COUNT(*) FROM report_unlocks WHERE user_id=$1 AND unlock_method='free'`, [userId]),
      db.query(`SELECT COALESCE(SUM(credits_remaining),0) AS credits FROM report_plan_purchases WHERE user_id=$1 AND credits_remaining > 0`, [userId]),
      db.query(`SELECT COALESCE(balance, 0) AS balance FROM wallets WHERE user_id=$1`, [userId]),
    ]);
    const freeUsed = parseInt(freeResult.rows[0].count) > 0;
    const planCredits = parseInt(planResult.rows[0].credits);
    const walletBalance = parseFloat(walletResult.rows[0]?.balance ?? 0);
    res.json({
      success: true,
      data: {
        free_used: freeUsed,
        free_available: !freeUsed,
        plan_credits: planCredits,
        wallet_balance: walletBalance,
        can_unlock: !freeUsed || planCredits > 0,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ── List all reports ──────────────────────────────────────────────────────────
exports.listReports = async (req, res) => {
  try {
    const reports = await db.query(
      `SELECT DISTINCT ON (r.name) r.*,
        (SELECT json_build_object('reviewer_name', rr.reviewer_name, 'review_text', rr.review_text, 'rating', rr.rating)
         FROM report_reviews rr WHERE rr.report_id = r.id ORDER BY RANDOM() LIMIT 1) AS random_comment
       FROM reports r WHERE r.is_active = TRUE ORDER BY r.name, r.sort_order`
    );
    res.json({ success: true, data: reports.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ── Check unlock status ───────────────────────────────────────────────────────
exports.checkUnlockStatus = async (req, res) => {
  try {
    const { reportId } = req.params;
    const { family_member_id } = req.query;
    const userId = req.user.id;

    const unlockQuery = family_member_id
      ? 'SELECT id FROM report_unlocks WHERE user_id=$1 AND report_id=$2 AND family_member_id=$3'
      : 'SELECT id FROM report_unlocks WHERE user_id=$1 AND report_id=$2 AND family_member_id IS NULL';
    const unlockParams = family_member_id ? [userId, reportId, family_member_id] : [userId, reportId];
    const existing = await db.query(unlockQuery, unlockParams);

    const freeUsed = await db.query(
      `SELECT COUNT(*) FROM report_unlocks WHERE user_id=$1 AND unlock_method='free'`,
      [userId]
    );
    const planCredits = await db.query(
      `SELECT COALESCE(SUM(credits_remaining),0) AS credits FROM report_plan_purchases WHERE user_id=$1 AND credits_remaining > 0`,
      [userId]
    );
    const wallet = await db.query('SELECT balance FROM wallets WHERE user_id=$1', [userId]);

    res.json({
      success: true,
      data: {
        is_unlocked: existing.rows.length > 0,
        free_available: parseInt(freeUsed.rows[0].count) === 0,
        plan_credits: parseInt(planCredits.rows[0].credits),
        wallet_balance: wallet.rows[0]?.balance || 0,
      },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ── Unlock a report ───────────────────────────────────────────────────────────
exports.unlockReport = async (req, res) => {
  const client = await db.pool.connect();
  try {
    const { report_id, family_member_id, language } = req.body;
    const userId = req.user.id;

    if (!report_id) return res.status(400).json({ success: false, message: 'report_id is required' });

    // Check already unlocked
    const unlockQuery = family_member_id
      ? 'SELECT id, ai_content FROM report_unlocks WHERE user_id=$1 AND report_id=$2 AND family_member_id=$3'
      : 'SELECT id, ai_content FROM report_unlocks WHERE user_id=$1 AND report_id=$2 AND family_member_id IS NULL';
    const unlockParams = family_member_id ? [userId, report_id, family_member_id] : [userId, report_id];
    const existing = await client.query(unlockQuery, unlockParams);
    if (existing.rows.length > 0) {
      return res.json({ success: true, data: existing.rows[0], already_unlocked: true });
    }

    // Determine unlock method
    const freeUsed = await client.query(
      `SELECT COUNT(*) FROM report_unlocks WHERE user_id=$1 AND unlock_method='free'`, [userId]
    );
    const hasFree = parseInt(freeUsed.rows[0].count) === 0;

    let unlockMethod = null;
    let planPurchaseId = null;

    if (hasFree) {
      unlockMethod = 'free';
    } else {
      const planResult = await client.query(
        `SELECT id, credits_remaining FROM report_plan_purchases WHERE user_id=$1 AND credits_remaining > 0 ORDER BY created_at ASC LIMIT 1`,
        [userId]
      );
      if (planResult.rows.length > 0) {
        unlockMethod = 'plan';
        planPurchaseId = planResult.rows[0].id;
      }
    }

    if (!unlockMethod) {
      return res.status(402).json({ success: false, message: 'No credits available', code: 'NO_CREDITS' });
    }

    // Get report info
    const reportResult = await client.query('SELECT * FROM reports WHERE id=$1', [report_id]);
    if (reportResult.rows.length === 0) return res.status(404).json({ success: false, message: 'Report not found' });
    const report = reportResult.rows[0];

    // Get person details
    let person;
    if (family_member_id) {
      const fm = await client.query('SELECT * FROM family_members WHERE id=$1 AND user_id=$2', [family_member_id, userId]);
      if (fm.rows.length === 0) return res.status(404).json({ success: false, message: 'Family member not found' });
      person = {
        name: fm.rows[0].name,
        date_of_birth: fm.rows[0].date_of_birth,
        time_of_birth: fm.rows[0].time_of_birth,
        birth_place: fm.rows[0].birth_place,
      };
    } else {
      const user = await client.query('SELECT name, date_of_birth, time_of_birth, birth_place FROM users WHERE id=$1', [userId]);
      person = user.rows[0];
    }

    // Generate AI content
    const aiContent = await generateAiContent(report.name, report.inclusions, person, language || 'English');

    await client.query('BEGIN');

    // Insert unlock record
    const unlock = await client.query(
      `INSERT INTO report_unlocks (user_id, report_id, family_member_id, unlock_method, ai_content)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, report_id, family_member_id || null, unlockMethod, aiContent]
    );

    // Deduct plan credit if used
    if (planPurchaseId) {
      await client.query(
        'UPDATE report_plan_purchases SET credits_remaining = credits_remaining - 1 WHERE id=$1',
        [planPurchaseId]
      );
    }

    // Bump unlock count
    await client.query('UPDATE reports SET unlock_count = unlock_count + 1 WHERE id=$1', [report_id]);

    await client.query('COMMIT');

    const personName = person.name || 'You';
    sendPushNotification([userId], '✨ Your Report is Ready!', `${report.name} for ${personName} has been generated. Tap to read now.`, { type: 'report_ready', unlock_id: unlock.rows[0].id, report_id: report_id });

    res.status(201).json({ success: true, data: unlock.rows[0] });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  } finally {
    client.release();
  }
};

// ── Get a single unlock (report detail) ──────────────────────────────────────
exports.getReportDetail = async (req, res) => {
  try {
    const { unlockId } = req.params;
    const result = await db.query(
      `SELECT ru.*, r.name AS report_name, r.icon, r.category, r.inclusions,
              fm.name AS family_member_name
       FROM report_unlocks ru
       JOIN reports r ON r.id = ru.report_id
       LEFT JOIN family_members fm ON fm.id = ru.family_member_id
       WHERE ru.id=$1 AND ru.user_id=$2`,
      [unlockId, req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ── Get user's unlocked reports ───────────────────────────────────────────────
exports.getUnlockedReports = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT ru.id, ru.report_id, ru.family_member_id, ru.created_at,
              r.name AS report_name, r.icon, r.category,
              fm.name AS family_member_name
       FROM report_unlocks ru
       JOIN reports r ON r.id = ru.report_id
       LEFT JOIN family_members fm ON fm.id = ru.family_member_id
       WHERE ru.user_id=$1 ORDER BY ru.created_at DESC`,
      [req.user.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ── Submit review ─────────────────────────────────────────────────────────────
exports.submitReview = async (req, res) => {
  try {
    const { report_id, rating, review_text } = req.body;
    if (!report_id || !rating) return res.status(400).json({ success: false, message: 'report_id and rating required' });

    const user = await db.query('SELECT name FROM users WHERE id=$1', [req.user.id]);
    const reviewerName = user.rows[0]?.name || 'Anonymous';

    await db.query(
      `INSERT INTO report_reviews (user_id, report_id, rating, review_text, reviewer_name)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (user_id, report_id) DO UPDATE SET rating=$3, review_text=$4`,
      [req.user.id, report_id, rating, review_text || null, reviewerName]
    );

    // Update avg rating on reports table
    await db.query(
      `UPDATE reports SET avg_rating = (SELECT AVG(rating) FROM report_reviews WHERE report_id=$1) WHERE id=$1`,
      [report_id]
    );

    res.json({ success: true, message: 'Review submitted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// ── Get plans ─────────────────────────────────────────────────────────────────
exports.getPlans = async (req, res) => {
  res.json({ success: true, data: REPORT_PLANS });
};

// ── Purchase a plan ───────────────────────────────────────────────────────────
exports.purchasePlan = async (req, res) => {
  const client = await db.pool.connect();
  try {
    const { plan_name } = req.body;
    const plan = REPORT_PLANS.find(p => p.name === plan_name);
    if (!plan) return res.status(400).json({ success: false, message: 'Invalid plan' });

    await client.query('BEGIN');

    const wallet = await client.query('SELECT id, COALESCE(balance, 0) AS balance FROM wallets WHERE user_id=$1 FOR UPDATE', [req.user.id]);
    if (wallet.rows.length === 0 || parseFloat(wallet.rows[0].balance) < plan.price) {
      await client.query('ROLLBACK');
      return res.status(402).json({ success: false, message: 'Insufficient wallet balance', code: 'INSUFFICIENT_BALANCE' });
    }

    const newBalance = parseFloat(wallet.rows[0].balance) - plan.price;
    await client.query('UPDATE wallets SET balance=$1 WHERE user_id=$2', [newBalance, req.user.id]);

    await client.query(
      `INSERT INTO wallet_transactions (user_id, type, amount, balance_after, description)
       VALUES ($1, 'debit', $2, $3, $4)`,
      [req.user.id, plan.price, newBalance, `${plan.label} Report Plan`]
    );

    const purchase = await client.query(
      `INSERT INTO report_plan_purchases (user_id, plan_name, amount_paid, report_credits, credits_remaining)
       VALUES ($1, $2, $3, $4, $4) RETURNING *`,
      [req.user.id, plan_name, plan.price, plan.credits]
    );

    await client.query('COMMIT');
    res.status(201).json({ success: true, data: purchase.rows[0], wallet_balance: newBalance });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  } finally {
    client.release();
  }
};
