const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

const ZODIAC_SIGNS = [
  { name: 'Capricorn', start: [12, 22], end: [1, 19] },
  { name: 'Aquarius', start: [1, 20], end: [2, 18] },
  { name: 'Pisces', start: [2, 19], end: [3, 20] },
  { name: 'Aries', start: [3, 21], end: [4, 19] },
  { name: 'Taurus', start: [4, 20], end: [5, 20] },
  { name: 'Gemini', start: [5, 21], end: [6, 20] },
  { name: 'Cancer', start: [6, 21], end: [7, 22] },
  { name: 'Leo', start: [7, 23], end: [8, 22] },
  { name: 'Virgo', start: [8, 23], end: [9, 22] },
  { name: 'Libra', start: [9, 23], end: [10, 22] },
  { name: 'Scorpio', start: [10, 23], end: [11, 21] },
  { name: 'Sagittarius', start: [11, 22], end: [12, 21] },
];

function getSunSign(dob) {
  const date = new Date(dob);
  const month = date.getMonth() + 1;
  const day = date.getDate();

  for (const sign of ZODIAC_SIGNS) {
    const [sm, sd] = sign.start;
    const [em, ed] = sign.end;
    if (sm <= em) {
      if ((month === sm && day >= sd) || (month === em && day <= ed) || (month > sm && month < em)) return sign.name;
    } else {
      if ((month === sm && day >= sd) || (month === em && day <= ed) || month > sm || month < em) return sign.name;
    }
  }
  return 'Capricorn';
}

function generateToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '30d' });
}

exports.register = async (req, res) => {
  try {
    const { email, password, name, date_of_birth, time_of_birth, birth_place } = req.body;

    const existing = await db.query('SELECT id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const sunSign = date_of_birth ? getSunSign(date_of_birth) : null;

    const result = await db.query(
      `INSERT INTO users (email, password_hash, name, date_of_birth, time_of_birth, birth_place, sun_sign)
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id, email, name, sun_sign, subscription_plan, created_at`,
      [email, passwordHash, name, date_of_birth || null, time_of_birth || null, birth_place || null, sunSign]
    );

    const user = result.rows[0];
    const token = generateToken(user.id);

    res.status(201).json({ success: true, data: { user, token } });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password, login_as = 'user' } = req.body;

    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    // Role-based access control
    if (login_as === 'admin') {
      if (user.role !== 'admin') {
        return res.status(403).json({ success: false, message: 'Access denied. Admin credentials required.' });
      }
    } else if (login_as === 'astrologer') {
      const astroCheck = await db.query('SELECT id FROM astrologers WHERE user_id = $1', [user.id]);
      if (!astroCheck.rows.length) {
        return res.status(403).json({ success: false, message: 'No astrologer account found for this email.' });
      }
    } else {
      // login_as === 'user'
      if (user.role === 'admin') {
        return res.status(403).json({ success: false, message: 'Admin accounts must use the admin portal.' });
      }
      if (user.role === 'astrologer') {
        return res.status(403).json({ success: false, message: 'Astrologer accounts must use the astrologer portal.' });
      }
    }

    const token = generateToken(user.id);
    delete user.password_hash;

    res.json({ success: true, data: { user, token } });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT id, email, name, avatar_url, date_of_birth, time_of_birth, birth_place,
              sun_sign, moon_sign, rising_sign, subscription_plan, created_at
       FROM users WHERE id = $1`,
      [req.user.id]
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const { name, date_of_birth, time_of_birth, birth_place, avatar_url } = req.body;
    const sunSign = date_of_birth ? getSunSign(date_of_birth) : req.user.sun_sign;

    const result = await db.query(
      `UPDATE users SET name=$1, date_of_birth=$2, time_of_birth=$3, birth_place=$4, sun_sign=$5,
       avatar_url=COALESCE($6, avatar_url), updated_at=NOW()
       WHERE id=$7 RETURNING id, email, name, avatar_url, date_of_birth, time_of_birth, birth_place, sun_sign, subscription_plan`,
      [name, date_of_birth || null, time_of_birth || null, birth_place || null, sunSign, avatar_url || null, req.user.id]
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.uploadAvatar = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });

    const avatarUrl = `${process.env.BASE_URL || 'https://api.astrovaak.online'}/uploads/avatars/${req.file.filename}`;

    await db.query('UPDATE users SET avatar_url=$1, updated_at=NOW() WHERE id=$2', [avatarUrl, req.user.id]);
    // Keep astrologers table in sync so a.* returns the correct avatar
    await db.query('UPDATE astrologers SET avatar_url=$1 WHERE user_id=$2', [avatarUrl, req.user.id]);

    res.json({ success: true, avatar_url: avatarUrl });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
