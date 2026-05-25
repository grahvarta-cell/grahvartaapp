const db = require('../config/database');

// Static horoscope content for demo (replace with AI/API in production)
const HOROSCOPE_TEMPLATES = {
  Aries: {
    daily: "The stars align in your favor today, Aries. Your natural leadership shines bright as Mars energizes your ambitions. Love blossoms unexpectedly.",
    weekly: "This week brings powerful energy for new beginnings. Mercury's influence sharpens your communication skills.",
    yearly: "2024 marks a transformative year for Aries. Jupiter's transit through your 2nd house promises financial growth.",
  },
  Taurus: {
    daily: "Venus blesses your day with beauty and harmony, Taurus. Financial opportunities arise through unexpected channels.",
    weekly: "The week ahead favors stability and practical matters. Focus on long-term investments.",
    yearly: "Saturn's influence brings discipline and rewards for your patience throughout this year.",
  },
  Gemini: {
    daily: "Mercury, your ruling planet, keeps your mind razor-sharp today. Social connections bring surprising news.",
    weekly: "Communication and travel highlighted this week. Embrace the dual nature of opportunities.",
    yearly: "A year of intellectual growth and expanding horizons. New relationships transform your perspective.",
  },
  Cancer: {
    daily: "The Moon's energy deeply resonates with your intuition today. Home and family bring comfort.",
    weekly: "Emotional intelligence guides you through relationship dynamics this week.",
    yearly: "Significant home and family changes create a new foundation for your future.",
  },
  Leo: {
    daily: "The Sun, your ruler, illuminates your path with confidence and creativity today, Leo.",
    weekly: "Your charisma attracts amazing opportunities. Romance and creative projects flourish.",
    yearly: "A spotlight year for Leo. Recognition and achievement follow your authentic expression.",
  },
  Virgo: {
    daily: "Detail-oriented Mercury helps you solve complex problems with elegance today, Virgo.",
    weekly: "Health and work routines benefit from your analytical approach this week.",
    yearly: "Practical wisdom guides major life decisions. Your diligence pays off remarkably.",
  },
  Libra: {
    daily: "Venus brings harmony to all your relationships today, Libra. Balance is your superpower.",
    weekly: "Partnership and diplomacy create win-win situations. Beauty surrounds you.",
    yearly: "Relationships transform and deepen. Finding true balance leads to lasting happiness.",
  },
  Scorpio: {
    daily: "Pluto's transformative energy runs deep today, Scorpio. Trust your powerful intuition.",
    weekly: "Deep investigation reveals hidden truths. Financial and intimate matters intensify.",
    yearly: "A year of profound personal transformation and spiritual evolution.",
  },
  Sagittarius: {
    daily: "Jupiter expands your horizons in unexpected ways today, Sagittarius. Adventure calls!",
    weekly: "Philosophy, travel, and higher learning create exciting new pathways.",
    yearly: "Freedom and expansion define this year. International connections bring blessings.",
  },
  Capricorn: {
    daily: "Saturn rewards your discipline today, Capricorn. Professional matters advance steadily.",
    weekly: "Career ambitions crystallize into concrete plans. Authority figures notice your worth.",
    yearly: "Peak career achievement possible this year. Your patience and hard work are recognized.",
  },
  Aquarius: {
    daily: "Uranus sparks innovative ideas today, Aquarius. Your humanitarian vision inspires others.",
    weekly: "Technology and community connections open revolutionary doors this week.",
    yearly: "A breakthrough year for Aquarius. Your unique vision changes everything around you.",
  },
  Pisces: {
    daily: "Neptune deepens your spiritual connection today, Pisces. Creativity flows abundantly.",
    weekly: "Dreams and intuition guide you toward meaningful experiences this week.",
    yearly: "Spiritual awakening and artistic achievement mark this transformative year.",
  },
};

exports.getHoroscope = async (req, res) => {
  try {
    const { sign, period } = req.params;
    const validSign = sign.charAt(0).toUpperCase() + sign.slice(1).toLowerCase();
    const validPeriod = ['daily', 'weekly', 'monthly', 'yearly'].includes(period) ? period : 'daily';

    const today = new Date().toISOString().split('T')[0];

    // Check DB first
    let result = await db.query(
      `SELECT * FROM horoscopes WHERE zodiac_sign = $1 AND period_type = $2 AND period_date = $3`,
      [validSign, validPeriod, today]
    );

    if (result.rows.length > 0) {
      return res.json({ success: true, data: result.rows[0] });
    }

    // Generate and cache
    const template = HOROSCOPE_TEMPLATES[validSign];
    const content = template
      ? template[validPeriod] || template.daily
      : `The stars have a special message for ${validSign} today. Embrace the cosmic energy flowing through your life.`;

    const scores = {
      love_score: Math.floor(Math.random() * 30) + 60,
      friendship_score: Math.floor(Math.random() * 30) + 60,
      work_score: Math.floor(Math.random() * 30) + 60,
    };

    const inserted = await db.query(
      `INSERT INTO horoscopes (zodiac_sign, period_type, period_date, content, love_score, friendship_score, work_score, lucky_number, lucky_color)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) RETURNING *`,
      [validSign, validPeriod, today, content, scores.love_score, scores.friendship_score, scores.work_score,
       Math.floor(Math.random() * 99) + 1, ['Gold', 'Orange', 'Red', 'Purple', 'Blue'][Math.floor(Math.random() * 5)]]
    );

    res.json({ success: true, data: inserted.rows[0] });
  } catch (err) {
    console.error('Horoscope error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getUserHoroscope = async (req, res) => {
  try {
    const { period } = req.query;
    const sign = req.user.sun_sign || 'Aries';
    const validPeriod = period || 'daily';

    req.params = { sign, period: validPeriod };
    return exports.getHoroscope(req, res);
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getAllSigns = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM zodiac_signs ORDER BY id');
    res.json({ success: true, data: result.rows });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

exports.getCompatibility = async (req, res) => {
  try {
    const { sign1, sign2 } = req.params;

    const ELEMENTS = {
      Fire: ['Aries', 'Leo', 'Sagittarius'],
      Earth: ['Taurus', 'Virgo', 'Capricorn'],
      Air: ['Gemini', 'Libra', 'Aquarius'],
      Water: ['Cancer', 'Scorpio', 'Pisces'],
    };

    let score = 50;
    let description = '';

    const getElement = (sign) => Object.keys(ELEMENTS).find(el => ELEMENTS[el].includes(sign));
    const el1 = getElement(sign1);
    const el2 = getElement(sign2);

    if (el1 === el2) { score = 90; description = 'Exceptional compatibility! Same element signs deeply understand each other.'; }
    else if ((el1 === 'Fire' && el2 === 'Air') || (el1 === 'Air' && el2 === 'Fire')) { score = 85; description = 'Fire and Air create an exciting, stimulating connection.'; }
    else if ((el1 === 'Earth' && el2 === 'Water') || (el1 === 'Water' && el2 === 'Earth')) { score = 85; description = 'Earth and Water create a nurturing, stable partnership.'; }
    else if ((el1 === 'Fire' && el2 === 'Earth') || (el1 === 'Earth' && el2 === 'Fire')) { score = 60; description = 'Fire and Earth can work with patience and understanding.'; }
    else { score = 55; description = 'This pairing requires conscious effort and communication.'; }

    res.json({
      success: true,
      data: {
        sign1, sign2,
        element1: el1, element2: el2,
        compatibility_score: score,
        description,
        love: score + Math.floor(Math.random() * 10) - 5,
        friendship: score + Math.floor(Math.random() * 10) - 5,
        work: score + Math.floor(Math.random() * 10) - 5,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
