const db = require('../config/database');
const admin = require('firebase-admin');

// Init Firebase Admin if credentials exist
let fcmEnabled = false;
if (process.env.FIREBASE_SERVICE_ACCOUNT) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)),
    });
    fcmEnabled = true;
  } catch (e) {
    console.warn('Firebase not configured — push notifications disabled');
  }
}

async function sendPushNotification(userIds, title, body, data = {}) {
  const type = data.type || 'general';

  // Always persist to DB so users see it in the notifications screen
  try {
    await Promise.all(userIds.map(uid =>
      db.query(
        'INSERT INTO user_notifications (user_id, title, body, type, data) VALUES ($1, $2, $3, $4, $5)',
        [uid, title, body, type, data]
      )
    ));
  } catch (err) {
    console.error('Notification DB insert error:', err);
  }

  if (!fcmEnabled) return;
  try {
    const tokens = await db.query('SELECT token FROM push_tokens WHERE user_id = ANY($1)', [userIds]);
    if (!tokens.rows.length) return;

    const tokenList = tokens.rows.map(r => r.token);
    await admin.messaging().sendEachForMulticast({
      tokens: tokenList,
      notification: { title, body },
      data: { ...data, click_action: 'FLUTTER_NOTIFICATION_CLICK' },
      android: { priority: 'high' },
      apns: { payload: { aps: { sound: 'default' } } },
    });
  } catch (err) {
    console.error('FCM error:', err);
  }
}

// Live Sessions
exports.getLiveSessions = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT ls.*, a.display_name as astrologer_name, a.specializations, u.avatar_url
      FROM live_sessions ls
      JOIN astrologers a ON ls.astrologer_id = a.id
      JOIN users u ON a.user_id = u.id
      WHERE ls.status IN ('scheduled','live','ended')
      ORDER BY CASE ls.status WHEN 'live' THEN 0 WHEN 'scheduled' THEN 1 ELSE 2 END, ls.scheduled_at ASC
      LIMIT 20
    `);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.createLiveSession = async (req, res) => {
  try {
    const { title, description, thumbnail_url, scheduled_at } = req.body;

    const astroResult = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [req.user.id]);
    if (!astroResult.rows.length) return res.status(403).json({ success: false, message: 'Not an astrologer' });

    const channel = `live_${astroResult.rows[0].id}_${Date.now()}`;
    const result = await db.query(`
      INSERT INTO live_sessions (astrologer_id, title, description, thumbnail_url, agora_channel, scheduled_at)
      VALUES ($1, $2, $3, $4, $5, $6) RETURNING *
    `, [astroResult.rows[0].id, title, description, thumbnail_url, channel, scheduled_at || new Date()]);

    // Notify followers
    const session = result.rows[0];
    const followers = await db.query('SELECT DISTINCT user_id FROM user_bookmarks WHERE content_type = $1', ['astrologer']);
    if (followers.rows.length) {
      const userIds = followers.rows.map(r => r.user_id);
      await sendPushNotification(userIds, `🔴 ${req.user.name} is going Live!`, title, { session_id: session.id, type: 'live_started' });
    }

    res.status(201).json({ success: true, data: session });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.startLiveSession = async (req, res) => {
  try {
    const result = await db.query(`
      UPDATE live_sessions SET status = 'live', started_at = NOW()
      WHERE id = $1 RETURNING *
    `, [req.params.id]);

    const session = result.rows[0];

    // Push to all users when live session actually starts
    const allUsers = await db.query('SELECT DISTINCT user_id FROM push_tokens');
    if (allUsers.rows.length) {
      const userIds = allUsers.rows.map(r => r.user_id);
      await sendPushNotification(
        userIds,
        '🔴 Live Session Started!',
        session.title,
        { type: 'live_started', session_id: session.id }
      );
    }

    res.json({ success: true, data: session });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.endLiveSession = async (req, res) => {
  try {
    const result = await db.query(`
      UPDATE live_sessions SET
        status = 'ended',
        ended_at = NOW(),
        duration_seconds = EXTRACT(EPOCH FROM (NOW() - started_at))::INTEGER
      WHERE id = $1 RETURNING *
    `, [req.params.id]);
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Community
exports.getCommunityPosts = async (req, res) => {
  try {
    const { category, zodiac_sign, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT cp.*, u.name as author_name, u.sun_sign as author_sign,
             a.display_name as astrologer_name, a.is_verified,
             EXISTS(SELECT 1 FROM post_likes pl WHERE pl.post_id = cp.id AND pl.user_id = $1) AS is_liked
      FROM community_posts cp
      JOIN users u ON cp.user_id = u.id
      LEFT JOIN astrologers a ON cp.astrologer_id = a.id
      WHERE (cp.status = 'approved' OR cp.user_id = $1)
    `;
    const params = [req.user.id];

    if (category) { query += ` AND cp.category = $${params.length + 1}`; params.push(category); }
    if (zodiac_sign) { query += ` AND cp.zodiac_sign = $${params.length + 1}`; params.push(zodiac_sign); }

    query += ` ORDER BY cp.is_pinned DESC, cp.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await db.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.createPost = async (req, res) => {
  try {
    const { content, category, zodiac_sign, media_url, media_type } = req.body;
    const result = await db.query(`
      INSERT INTO community_posts (user_id, content, category, zodiac_sign, media_url, media_type, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'pending') RETURNING *
    `, [req.user.id, content, category, zodiac_sign, media_url, media_type]);

    const post = result.rows[0];
    res.status(201).json({ success: true, data: post });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.deletePost = async (req, res) => {
  try {
    const result = await db.query(
      'DELETE FROM community_posts WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.post_id, req.user.id]
    );
    if (!result.rows.length) return res.status(403).json({ success: false, message: 'Not found or unauthorized' });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.toggleLike = async (req, res) => {
  try {
    const { post_id } = req.params;
    const existing = await db.query('SELECT 1 FROM post_likes WHERE user_id = $1 AND post_id = $2', [req.user.id, post_id]);

    if (existing.rows.length) {
      await db.query('DELETE FROM post_likes WHERE user_id = $1 AND post_id = $2', [req.user.id, post_id]);
      await db.query('UPDATE community_posts SET likes_count = likes_count - 1 WHERE id = $1', [post_id]);
      res.json({ success: true, liked: false });
    } else {
      await db.query('INSERT INTO post_likes (user_id, post_id) VALUES ($1, $2)', [req.user.id, post_id]);
      await db.query('UPDATE community_posts SET likes_count = likes_count + 1 WHERE id = $1', [post_id]);
      res.json({ success: true, liked: true });
    }
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getComments = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT pc.*, u.name as user_name, u.sun_sign
      FROM post_comments pc JOIN users u ON pc.user_id = u.id
      WHERE pc.post_id = $1 ORDER BY pc.created_at ASC
    `, [req.params.post_id]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.addComment = async (req, res) => {
  try {
    const result = await db.query(
      'INSERT INTO post_comments (post_id, user_id, content) VALUES ($1, $2, $3) RETURNING *',
      [req.params.post_id, req.user.id, req.body.content]
    );
    await db.query('UPDATE community_posts SET comments_count = comments_count + 1 WHERE id = $1', [req.params.post_id]);
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Notifications
exports.getNotifications = async (req, res) => {
  try {
    const result = await db.query(
      'SELECT * FROM user_notifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 50',
      [req.user.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.markAllRead = async (req, res) => {
  try {
    await db.query('UPDATE user_notifications SET is_read = true WHERE user_id = $1', [req.user.id]);
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.registerPushToken = async (req, res) => {
  try {
    const { token, platform } = req.body;
    await db.query(
      'INSERT INTO push_tokens (user_id, token, platform) VALUES ($1, $2, $3) ON CONFLICT (user_id, token) DO NOTHING',
      [req.user.id, token, platform]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Daily horoscope push — called by cron
exports.sendDailyHoroscopePush = async () => {
  if (!fcmEnabled) return;
  try {
    const users = await db.query('SELECT u.id, u.sun_sign, pt.token FROM users u JOIN push_tokens pt ON u.id = pt.user_id WHERE u.sun_sign IS NOT NULL');

    const bySign = {};
    users.rows.forEach(u => {
      if (!bySign[u.sun_sign]) bySign[u.sun_sign] = [];
      bySign[u.sun_sign].push(u.token);
    });

    for (const [sign, tokens] of Object.entries(bySign)) {
      await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title: `🔮 Your ${sign} daily prediction is ready`, body: 'Tap to see what the stars say today.' },
        data: { type: 'daily_horoscope', sign },
      });
    }
  } catch (err) {
    console.error('Daily push error:', err);
  }
};

module.exports.sendPushNotification = sendPushNotification;
