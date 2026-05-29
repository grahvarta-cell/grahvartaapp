const db = require('../config/database');

exports.listAstrologers = async (req, res) => {
  try {
    const { specialization, language, type, sort = 'rating', online_only, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT a.*,
             u.name, u.email,
             (SELECT COUNT(*) FROM astrologer_reviews ar WHERE ar.astrologer_id = a.id) AS review_count_live
      FROM astrologers a
      JOIN users u ON a.user_id = u.id
      WHERE a.is_banned = FALSE OR a.is_banned IS NULL
    `;
    const params = [];

    if (online_only === 'true') { query += ` AND a.is_online = true`; }
    if (specialization) { query += ` AND $${params.length + 1} = ANY(a.specializations)`; params.push(specialization); }
    if (language) { query += ` AND $${params.length + 1} = ANY(a.languages)`; params.push(language); }

    const sortMap = { rating: 'a.rating DESC', experience: 'a.experience_years DESC', price_low: 'a.per_minute_rate_chat ASC', price_high: 'a.per_minute_rate_chat DESC', popular: 'a.total_consultations DESC' };
    query += ` ORDER BY ${sortMap[sort] || 'a.rating DESC'} LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await db.query(query, params);

    const countResult = await db.query('SELECT COUNT(*) FROM astrologers a WHERE a.is_banned = FALSE OR a.is_banned IS NULL');
    res.json({ success: true, data: result.rows, total: parseInt(countResult.rows[0].count), page: parseInt(page), limit: parseInt(limit) });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getAstrologer = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT a.*, u.name, u.email, u.sun_sign, u.avatar_url,
             COALESCE(json_agg(DISTINCT ar.*) FILTER (WHERE ar.id IS NOT NULL), '[]') AS reviews
      FROM astrologers a
      JOIN users u ON a.user_id = u.id
      LEFT JOIN astrologer_reviews ar ON ar.astrologer_id = a.id
      WHERE a.id = $1
      GROUP BY a.id, u.name, u.email, u.sun_sign, u.avatar_url
    `, [req.params.id]);

    if (!result.rows.length) return res.status(404).json({ success: false, message: 'Astrologer not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getAstrologerReviews = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT ar.*, u.name as user_name, u.sun_sign
      FROM astrologer_reviews ar
      JOIN users u ON ar.user_id = u.id
      WHERE ar.astrologer_id = $1
      ORDER BY ar.created_at DESC LIMIT 50
    `, [req.params.id]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.submitReview = async (req, res) => {
  try {
    const { rating, review_text, consultation_id, is_anonymous } = req.body;

    await db.query(`
      INSERT INTO astrologer_reviews (astrologer_id, user_id, consultation_id, rating, review_text, is_anonymous)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (astrologer_id, user_id, consultation_id) DO UPDATE
      SET rating = $4, review_text = $5
    `, [req.params.id, req.user.id, consultation_id, rating, review_text, is_anonymous || false]);

    // Update astrologer aggregate rating
    await db.query(`
      UPDATE astrologers SET
        rating = (SELECT AVG(rating) FROM astrologer_reviews WHERE astrologer_id = $1),
        review_count = (SELECT COUNT(*) FROM astrologer_reviews WHERE astrologer_id = $1)
      WHERE id = $1
    `, [req.params.id]);

    res.json({ success: true, message: 'Review submitted' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getConsultationHistory = async (req, res) => {
  try {
    const astroResult = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });
    const result = await db.query(
      `SELECT c.*, u.name as user_name FROM consultations c
       JOIN users u ON c.user_id = u.id
       WHERE c.astrologer_id = $1
       ORDER BY c.created_at DESC LIMIT 50`,
      [astroResult.rows[0].id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getConsultationMessages = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT * FROM consultation_messages WHERE consultation_id = $1 ORDER BY created_at ASC`,
      [req.params.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.registerAsAstrologer = async (req, res) => {
  try {
    const { display_name, bio, experience_years, languages, specializations, expertise_areas,
            per_minute_rate_chat, per_minute_rate_call, per_minute_rate_video } = req.body;

    const existing = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (existing.rows.length) return res.status(409).json({ success: false, message: 'Already registered as astrologer' });

    const result = await db.query(`
      INSERT INTO astrologers (user_id, display_name, bio, experience_years, languages, specializations,
        expertise_areas, per_minute_rate_chat, per_minute_rate_call, per_minute_rate_video)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *
    `, [req.user.id, display_name, bio, experience_years, languages, specializations, expertise_areas,
        per_minute_rate_chat || 10, per_minute_rate_call || 15, per_minute_rate_video || 20]);

    // Mark user role as astrologer so login enforcement works
    await db.query(`UPDATE users SET role = 'astrologer' WHERE id = $1`, [req.user.id]);

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.updateAvailability = async (req, res) => {
  try {
    const { is_available } = req.body;
    const astro = await db.query('SELECT id, status FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astro.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });
    if (astro.rows[0].status !== 'approved') {
      return res.status(403).json({ success: false, message: 'Your account is pending approval' });
    }
    await db.query('UPDATE astrologers SET is_available = $1, is_online = $1 WHERE user_id = $2', [is_available, req.user.id]);
    res.json({ success: true, message: 'Availability updated' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getAstrologerDashboard = async (req, res) => {
  try {
    const astroResult = await db.query('SELECT * FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(404).json({ success: false, message: 'Not an astrologer' });
    const astro = astroResult.rows[0];

    const [stats, recent, earnings] = await Promise.all([
      db.query(`SELECT
                  COUNT(*) as total,
                  AVG(duration_seconds) as avg_duration,
                  SUM(astrologer_earning) as total_revenue
                FROM consultations
                WHERE astrologer_id = $1 AND status = 'completed'`, [astro.id]),
      db.query(`SELECT c.*, u.name as user_name FROM consultations c JOIN users u ON c.user_id = u.id
                WHERE c.astrologer_id = $1 ORDER BY c.created_at DESC LIMIT 10`, [astro.id]),
      db.query(`SELECT DATE(c.created_at) as date, SUM(c.astrologer_earning) as daily_earning
                FROM consultations c
                WHERE c.astrologer_id = $1
                  AND c.status = 'completed'
                  AND c.created_at > NOW() - INTERVAL '30 days'
                GROUP BY DATE(c.created_at)
                ORDER BY date`, [astro.id]),
    ]);

    res.json({
      success: true,
      data: {
        astrologer: astro,
        stats: stats.rows[0],
        recent_consultations: recent.rows,
        earnings_chart: earnings.rows,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getAstrologerWallet = async (req, res) => {
  try {
    const astroResult = await db.query('SELECT * FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(404).json({ success: false, message: 'Not an astrologer' });
    const astro = astroResult.rows[0];
    const [totalEarned, thisMonth, thisWeek, today] = await Promise.all([
      db.query(`SELECT COALESCE(SUM(astrologer_earning), 0) as total FROM consultations WHERE astrologer_id = $1 AND astrologer_earning > 0`, [astro.id]),
      db.query(`SELECT COALESCE(SUM(astrologer_earning), 0) as amount FROM consultations WHERE astrologer_id = $1 AND astrologer_earning > 0 AND created_at >= DATE_TRUNC('month', NOW())`, [astro.id]),
      db.query(`SELECT COALESCE(SUM(astrologer_earning), 0) as amount FROM consultations WHERE astrologer_id = $1 AND astrologer_earning > 0 AND created_at >= DATE_TRUNC('week', NOW())`, [astro.id]),
      db.query(`SELECT COALESCE(SUM(astrologer_earning), 0) as amount FROM consultations WHERE astrologer_id = $1 AND astrologer_earning > 0 AND created_at >= DATE_TRUNC('day', NOW())`, [astro.id]),
    ]);
    res.json({ success: true, data: {
      wallet: { balance: parseFloat(astro.wallet_balance || 0), total_earned: parseFloat(totalEarned.rows[0].total) },
      stats: { this_month: parseFloat(thisMonth.rows[0].amount), this_week: parseFloat(thisWeek.rows[0].amount), today: parseFloat(today.rows[0].amount) },
    }});
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getAstrologerTransactions = async (req, res) => {
  try {
    const astroResult = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(404).json({ success: false, message: 'Not an astrologer' });
    const astroId = astroResult.rows[0].id;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    const result = await db.query(`
      SELECT c.id, c.created_at, c.duration_seconds, c.astrologer_earning as amount,
             c.type, u.name as user_name, 'credit' as type_label
      FROM consultations c JOIN users u ON c.user_id = u.id
      WHERE c.astrologer_id = $1 AND c.astrologer_earning > 0
      ORDER BY c.created_at DESC LIMIT $2 OFFSET $3
    `, [astroId, limit, offset]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getChatThreads = async (req, res) => {
  try {
    const astroResult = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });
    const astroId = astroResult.rows[0].id;

    const result = await db.query(`
      SELECT
        ct.id AS thread_id,
        ct.user_id,
        ct.last_message,
        ct.last_message_at,
        u.name AS user_name,
        u.avatar_url AS user_avatar
      FROM chat_threads ct
      JOIN users u ON u.id = ct.user_id
      WHERE ct.astrologer_id = $1
      ORDER BY ct.last_message_at DESC NULLS LAST
    `, [astroId]);

    res.json({ success: true, threads: result.rows });
  } catch (err) {
    console.error('[getChatThreads]', err.message);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getUserThreadMessages = async (req, res) => {
  try {
    const astroResult = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });
    const astroId = astroResult.rows[0].id;

    const userId = req.params.userId;
    const limit = Math.min(parseInt(req.query.limit) || 50, 100);
    const before = req.query.before;

    const threadResult = await db.query(
      'SELECT id FROM chat_threads WHERE astrologer_id = $1 AND user_id = $2',
      [astroId, userId]
    );
    if (!threadResult.rows.length) {
      return res.json({ success: true, messages: [], has_more: false });
    }
    const threadId = threadResult.rows[0].id;

    const params = [threadId, limit];
    const beforeClause = before ? `AND tm.created_at < $${params.push(before)}` : '';

    const result = await db.query(`
      SELECT * FROM (
        SELECT tm.id, tm.thread_id, tm.consultation_id, tm.sender_id, tm.sender_role,
               tm.message, tm.message_type, tm.created_at
        FROM thread_messages tm
        WHERE tm.thread_id = $1
          ${beforeClause}
        ORDER BY tm.created_at DESC
        LIMIT $2
      ) sub ORDER BY created_at ASC
    `, params);

    const countParams = [threadId];
    const countBefore = before ? `AND tm.created_at < $${countParams.push(before)}` : '';
    const countResult = await db.query(
      `SELECT COUNT(*) FROM thread_messages tm WHERE tm.thread_id = $1 ${countBefore}`,
      countParams
    );

    res.json({
      success: true,
      messages: result.rows,
      has_more: parseInt(countResult.rows[0].count) > limit,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
