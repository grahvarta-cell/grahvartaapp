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

exports.list = async (req, res) => {
  try {
    const result = await db.query(
      'SELECT * FROM family_members WHERE user_id = $1 ORDER BY created_at ASC',
      [req.user.id]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.create = async (req, res) => {
  try {
    const { name, date_of_birth, time_of_birth, birth_place, relationship } = req.body;
    if (!name || !date_of_birth) {
      return res.status(400).json({ success: false, message: 'Name and date of birth are required' });
    }
    const sunSign = getSunSign(date_of_birth);
    const result = await db.query(
      `INSERT INTO family_members (user_id, name, date_of_birth, time_of_birth, birth_place, sun_sign, relationship)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [req.user.id, name, date_of_birth, time_of_birth || null, birth_place || null, sunSign, relationship || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.update = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, date_of_birth, time_of_birth, birth_place, relationship } = req.body;

    const existing = await db.query(
      'SELECT id FROM family_members WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Family member not found' });
    }

    const sunSign = date_of_birth ? getSunSign(date_of_birth) : undefined;

    const result = await db.query(
      `UPDATE family_members SET
        name = COALESCE($1, name),
        date_of_birth = COALESCE($2, date_of_birth),
        time_of_birth = COALESCE($3, time_of_birth),
        birth_place = COALESCE($4, birth_place),
        relationship = COALESCE($5, relationship),
        sun_sign = COALESCE($6, sun_sign),
        updated_at = NOW()
       WHERE id = $7 AND user_id = $8
       RETURNING *`,
      [name || null, date_of_birth || null, time_of_birth || null, birth_place || null, relationship || null, sunSign || null, id, req.user.id]
    );
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

exports.remove = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(
      'DELETE FROM family_members WHERE id = $1 AND user_id = $2 RETURNING id',
      [id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Family member not found' });
    }
    res.json({ success: true, message: 'Family member removed' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Internal server error' });
  }
};
