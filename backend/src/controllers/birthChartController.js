const db = require('../config/database');

// Planet positions simulation (in production use a proper astrology library like swisseph)
const PLANETS = ['Sun', 'Moon', 'Mercury', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'Uranus', 'Neptune', 'Pluto'];
const ZODIAC = ['Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', 'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces'];

function calculatePlanetPositions(dob) {
  // Simplified calculation - in production use Swiss Ephemeris
  const date = new Date(dob);
  const dayOfYear = Math.floor((date - new Date(date.getFullYear(), 0, 0)) / 86400000);
  const positions = {};

  PLANETS.forEach((planet, idx) => {
    const offset = (dayOfYear + idx * 30) % 360;
    const sign = ZODIAC[Math.floor(offset / 30)];
    const degree = offset % 30;
    positions[planet] = { sign, degree: Math.round(degree * 100) / 100, retrograde: Math.random() < 0.2 };
  });

  return positions;
}

function calculateHouses(dob, lat, lon) {
  const houses = {};
  for (let i = 1; i <= 12; i++) {
    const baseAngle = ((i - 1) * 30 + (lat || 0) * 0.1) % 360;
    houses[`House${i}`] = ZODIAC[Math.floor(baseAngle / 30)];
  }
  return houses;
}

function calculateAspects(positions) {
  const aspects = [];
  const planetList = Object.entries(positions);
  const ASPECT_TYPES = [
    { name: 'Conjunction', degrees: 0, orb: 8 },
    { name: 'Sextile', degrees: 60, orb: 6 },
    { name: 'Square', degrees: 90, orb: 8 },
    { name: 'Trine', degrees: 120, orb: 8 },
    { name: 'Opposition', degrees: 180, orb: 8 },
  ];

  for (let i = 0; i < planetList.length; i++) {
    for (let j = i + 1; j < planetList.length; j++) {
      const [p1, pos1] = planetList[i];
      const [p2, pos2] = planetList[j];
      const angle1 = ZODIAC.indexOf(pos1.sign) * 30 + pos1.degree;
      const angle2 = ZODIAC.indexOf(pos2.sign) * 30 + pos2.degree;
      const diff = Math.abs(angle1 - angle2);
      const normalDiff = diff > 180 ? 360 - diff : diff;

      for (const aspect of ASPECT_TYPES) {
        if (Math.abs(normalDiff - aspect.degrees) <= aspect.orb) {
          aspects.push({
            planet1: p1, planet2: p2,
            aspect: aspect.name,
            exact_degrees: Math.round(normalDiff * 100) / 100,
          });
        }
      }
    }
  }
  return aspects;
}

exports.getBirthChart = async (req, res) => {
  try {
    // Check cache
    const cached = await db.query('SELECT * FROM birth_charts WHERE user_id = $1', [req.user.id]);
    if (cached.rows.length > 0) {
      return res.json({ success: true, data: cached.rows[0] });
    }

    // Get user DOB
    const userResult = await db.query('SELECT date_of_birth, latitude, longitude FROM users WHERE id = $1', [req.user.id]);
    const user = userResult.rows[0];

    if (!user.date_of_birth) {
      return res.status(400).json({ success: false, message: 'Date of birth required to generate birth chart' });
    }

    const planetPositions = calculatePlanetPositions(user.date_of_birth);
    const housePositions = calculateHouses(user.date_of_birth, user.latitude, user.longitude);
    const aspects = calculateAspects(planetPositions);

    const result = await db.query(
      `INSERT INTO birth_charts (user_id, planet_positions, house_positions, aspects)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [req.user.id, JSON.stringify(planetPositions), JSON.stringify(housePositions), JSON.stringify(aspects)]
    );

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Birth chart error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getTransits = async (req, res) => {
  try {
    const { category } = req.query;
    const today = new Date().toISOString().split('T')[0];

    let query = `SELECT * FROM transits WHERE start_date <= $1 AND (end_date IS NULL OR end_date >= $1)`;
    const params = [today];

    if (category && category !== 'all') {
      query += ` AND category = $2`;
      params.push(category);
    }

    query += ' ORDER BY start_date DESC LIMIT 20';

    const result = await db.query(query, params);

    if (result.rows.length === 0) {
      // Seed some sample transits
      await db.query(`
        INSERT INTO transits (planet, aspect, target_planet, zodiac_sign, start_date, end_date, description, category, intensity)
        VALUES
          ('Mercury', 'conjunct', 'Venus', 'Libra', $1, $2, 'Mercury conjunct Venus in Libra brings harmony to communications and relationships. Express your feelings with grace.', 'love', 'moderate'),
          ('Mars', 'trine', 'Jupiter', 'Sagittarius', $1, $2, 'Mars trine Jupiter creates expansive energy for career ambitions. Bold actions lead to significant rewards.', 'work', 'strong'),
          ('Moon', 'sextile', 'Saturn', 'Aquarius', $1, $2, 'Moon sextile Saturn supports building stable, meaningful friendships. Connect with those who share your values.', 'friendship', 'mild'),
          ('Venus', 'opposition', 'Neptune', 'Pisces', $1, $2, 'Venus opposite Neptune heightens romantic idealism. Keep dreams grounded in reality.', 'love', 'strong'),
          ('Sun', 'trine', 'Pluto', 'Capricorn', $1, $2, 'Sun trine Pluto empowers personal transformation. Step into your authentic power.', 'general', 'moderate')
        ON CONFLICT DO NOTHING
      `, [today, new Date(Date.now() + 14 * 86400000).toISOString().split('T')[0]]);

      const fresh = await db.query(`SELECT * FROM transits WHERE start_date <= $1 ORDER BY start_date DESC LIMIT 20`, [today]);
      return res.json({ success: true, data: fresh.rows });
    }

    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('Transits error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
