const db = require('../config/database');

exports.getAudioContent = async (req, res) => {
  try {
    const { category, planet } = req.query;
    let query = 'SELECT * FROM audio_content WHERE 1=1';
    const params = [];

    if (category) { query += ` AND category = $${params.length + 1}`; params.push(category); }
    if (planet) { query += ` AND planet_theme = $${params.length + 1}`; params.push(planet); }

    query += ' ORDER BY created_at DESC';
    const result = await db.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getAudioById = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM audio_content WHERE id = $1', [req.params.id]);
    if (result.rows.length === 0) return res.status(404).json({ success: false, message: 'Not found' });

    // Increment play count
    await db.query('UPDATE audio_content SET play_count = play_count + 1 WHERE id = $1', [req.params.id]);

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getCourses = async (req, res) => {
  try {
    const { category } = req.query;
    let query = `
      SELECT c.*,
             COALESCE(ucp.completed_lessons, 0) as user_completed_lessons,
             CASE WHEN ucp.completed_at IS NOT NULL THEN true ELSE false END as is_completed
      FROM courses c
      LEFT JOIN user_course_progress ucp ON c.id = ucp.course_id AND ucp.user_id = $1
    `;
    const params = [req.user.id];

    if (category) { query += ` WHERE c.category = $2`; params.push(category); }
    query += ' ORDER BY c.created_at DESC';

    const result = await db.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getCourseById = async (req, res) => {
  try {
    const courseResult = await db.query('SELECT * FROM courses WHERE id = $1', [req.params.id]);
    if (courseResult.rows.length === 0) return res.status(404).json({ success: false, message: 'Course not found' });

    const lessonsResult = await db.query(
      'SELECT * FROM course_lessons WHERE course_id = $1 ORDER BY lesson_order',
      [req.params.id]
    );

    const progressResult = await db.query(
      'SELECT * FROM user_course_progress WHERE course_id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );

    res.json({
      success: true,
      data: {
        course: courseResult.rows[0],
        lessons: lessonsResult.rows,
        progress: progressResult.rows[0] || null,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.updateCourseProgress = async (req, res) => {
  try {
    const { lesson_id, completed_lessons } = req.body;

    await db.query(
      `INSERT INTO user_course_progress (user_id, course_id, completed_lessons, last_lesson_id)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, course_id) DO UPDATE
       SET completed_lessons = $3, last_lesson_id = $4`,
      [req.user.id, req.params.id, completed_lessons, lesson_id]
    );

    res.json({ success: true, message: 'Progress updated' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getAffirmations = async (req, res) => {
  try {
    const { sign } = req.query;
    const userSign = sign || req.user.sun_sign;
    const today = new Date();
    const weekStart = new Date(today);
    weekStart.setDate(today.getDate() - today.getDay());
    const weekStartStr = weekStart.toISOString().split('T')[0];

    let result = await db.query(
      'SELECT * FROM affirmations WHERE (zodiac_sign = $1 OR zodiac_sign IS NULL) AND week_start = $2 LIMIT 5',
      [userSign, weekStartStr]
    );

    if (result.rows.length === 0) {
      // Seed affirmation
      const affirmations = [
        `I am aligned with the cosmic energy of the universe and ${userSign}'s powerful nature.`,
        `My intuition guides me toward love, abundance, and harmony.`,
        `I embrace the transformative power of the stars and shine brightly.`,
        `Every day I grow stronger, wiser, and more connected to my true self.`,
        `The universe supports my highest good in all areas of my life.`,
      ];

      for (const content of affirmations) {
        await db.query(
          'INSERT INTO affirmations (content, zodiac_sign, week_start) VALUES ($1, $2, $3)',
          [content, userSign, weekStartStr]
        );
      }

      result = await db.query(
        'SELECT * FROM affirmations WHERE zodiac_sign = $1 AND week_start = $2 LIMIT 5',
        [userSign, weekStartStr]
      );
    }

    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getDashboard = async (req, res) => {
  try {
    const sign = req.user.sun_sign || 'Aries';
    const today = new Date().toISOString().split('T')[0];

    const [horoscope, stories, courses, transits] = await Promise.all([
      db.query('SELECT * FROM horoscopes WHERE zodiac_sign = $1 AND period_type = $2 AND period_date = $3', [sign, 'daily', today]),
      db.query('SELECT * FROM audio_content ORDER BY play_count DESC LIMIT 3'),
      db.query(`SELECT c.*, COALESCE(ucp.completed_lessons, 0) as user_completed_lessons FROM courses c LEFT JOIN user_course_progress ucp ON c.id = ucp.course_id AND ucp.user_id = $1 ORDER BY c.created_at DESC LIMIT 3`, [req.user.id]),
      db.query(`SELECT * FROM transits WHERE start_date <= $1 AND (end_date IS NULL OR end_date >= $1) ORDER BY intensity DESC LIMIT 2`, [today]),
    ]);

    res.json({
      success: true,
      data: {
        user: req.user,
        horoscope: horoscope.rows[0] || null,
        featured_stories: stories.rows,
        recommended_courses: courses.rows,
        active_transits: transits.rows,
      }
    });
  } catch (err) {
    console.error('Dashboard error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
