const db = require('../config/database');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const { sendAstrologerWelcome } = require('../utils/mailer');

const VALID_STATUSES = ['pending', 'shortlisted', 'round1', 'round2', 'activated', 'rejected'];

const uploadDir = path.join(__dirname, '../../uploads/hirings');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) => cb(null, `${uuidv4()}${path.extname(file.originalname)}`),
});
exports.upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_, file, cb) => {
    // Accept image/* plus application/octet-stream (some Android pickers send this)
    if (/image/.test(file.mimetype) || file.mimetype === 'application/octet-stream') {
      cb(null, true);
    } else {
      cb(new Error(`Unsupported file type: ${file.mimetype}`));
    }
  },
});

exports.uploadPhoto = async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'No file received. Ensure field name is "photo" and file is an image.' });
  res.json({ success: true, data: { url: `/uploads/hirings/${req.file.filename}` } });
};

async function generateTokenNo() {
  const r = await db.query('SELECT COUNT(*) FROM agent_hirings');
  const n = parseInt(r.rows[0].count) + 1000 + 1;
  return 'GRH-' + String(n).padStart(5, '0');
}

exports.submitApplication = async (req, res) => {
  try {
    const { phone, name, dob, gender, languages, skills, profile_picture_url, phone_type, email, works_online, hours_available, about_me } = req.body;
    if (!phone) return res.status(400).json({ success: false, message: 'Phone number is required' });
    const existing = await db.query('SELECT id FROM agent_hirings WHERE phone = $1', [phone]);
    if (existing.rows.length) return res.status(409).json({ success: false, message: 'Application already submitted for this number' });
    const tokenNo = await generateTokenNo();
    const result = await db.query(
      `INSERT INTO agent_hirings (phone, name, dob, gender, languages, skills, profile_picture_url, phone_type, email, works_online, hours_available, about_me, token_no)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`,
      [phone, name, dob || null, gender, JSON.stringify(languages || []), JSON.stringify(skills || []), profile_picture_url, phone_type, email, works_online === true || works_online === 'true', parseInt(hours_available) || 0, about_me || null, tokenNo]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('Hiring submission error:', err);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// App: check status by phone
exports.getStatus = async (req, res) => {
  try {
    const { phone } = req.query;
    if (!phone) return res.status(400).json({ success: false, message: 'Phone required' });
    const r = await db.query(
      'SELECT name, phone, token_no, status, profile_picture_url, admin_notes, welcome_email_sent, converted_to_astrologer FROM agent_hirings WHERE phone = $1',
      [phone]
    );
    if (!r.rows.length) return res.status(404).json({ success: false, message: 'Application not found' });
    res.json({ success: true, data: r.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Admin: list
exports.listApplications = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;
    let q = 'SELECT * FROM agent_hirings';
    const params = [];
    if (status) { q += ' WHERE status = $1'; params.push(status); }
    q += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);
    const countQ = status ? 'SELECT COUNT(*) FROM agent_hirings WHERE status = $1' : 'SELECT COUNT(*) FROM agent_hirings';
    const [rows, count] = await Promise.all([db.query(q, params), db.query(countQ, status ? [status] : [])]);
    res.json({ success: true, data: rows.rows, total: parseInt(count.rows[0].count) });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Admin: activate as astrologer
exports.activateAsAstrologer = async (req, res) => {
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');

    const { id } = req.params;
    const hiring = await client.query('SELECT * FROM agent_hirings WHERE id = $1', [id]);
    if (!hiring.rows.length) return res.status(404).json({ success: false, message: 'Application not found' });

    const app = hiring.rows[0];
    if (app.status !== 'activated') return res.status(400).json({ success: false, message: 'Application must be activated first' });
    if (app.converted_to_astrologer) return res.status(409).json({ success: false, message: 'Already added as astrologer' });
    if (!app.email) return res.status(400).json({ success: false, message: 'Agent has no email address' });

    // Generate temp password
    const tempPassword = Math.random().toString(36).slice(-8).toUpperCase();
    const passwordHash = await bcrypt.hash(tempPassword, 10);

    // Create user account
    const userResult = await client.query(
      `INSERT INTO users (email, password_hash, name, avatar_url, role, must_change_password)
       VALUES ($1, $2, $3, $4, 'astrologer', TRUE) RETURNING id`,
      [app.email, passwordHash, app.name || 'Astrologer', app.profile_picture_url || null]
    );
    const userId = userResult.rows[0].id;

    // Create wallet for the user
    await client.query(
      `INSERT INTO wallets (user_id, balance) VALUES ($1, 0) ON CONFLICT DO NOTHING`,
      [userId]
    );

    // Create astrologer profile
    const langs = Array.isArray(app.languages) ? app.languages : (app.languages ? JSON.parse(app.languages) : ['English']);
    const skills = Array.isArray(app.skills) ? app.skills : (app.skills ? JSON.parse(app.skills) : []);
    await client.query(
      `INSERT INTO astrologers (user_id, display_name, bio, avatar_url, languages, specializations, status)
       VALUES ($1, $2, $3, $4, $5, $6, 'approved')`,
      [userId, app.name, app.about_me || '', app.profile_picture_url || null,
       langs, skills]
    );

    // Mark hiring as converted
    await client.query(
      `UPDATE agent_hirings SET converted_to_astrologer = TRUE, astrologer_user_id = $1, updated_at = NOW() WHERE id = $2`,
      [userId, id]
    );

    await client.query('COMMIT');

    // Send welcome email (non-fatal — DB changes already committed)
    let emailSent = false;
    try {
      await sendAstrologerWelcome({
        to: app.email,
        name: app.name || 'Astrologer',
        email: app.email,
        password: tempPassword,
      });
      emailSent = true;
      await db.query(
        'UPDATE agent_hirings SET welcome_email_sent = TRUE WHERE id = $1',
        [id]
      );
    } catch (mailErr) {
      console.error('Welcome email failed (non-fatal):', mailErr.message);
    }

    res.json({
      success: true,
      message: emailSent
        ? 'Astrologer account created and welcome email sent'
        : 'Astrologer account created but email failed — please resend manually',
      email_sent: emailSent,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('activateAsAstrologer error:', err);
    res.status(500).json({ success: false, message: err.message || 'Server error' });
  } finally {
    client.release();
  }
};

// Admin: resend welcome email
exports.resendWelcomeEmail = async (req, res) => {
  try {
    const { id } = req.params;
    const hiring = await db.query('SELECT * FROM agent_hirings WHERE id = $1', [id]);
    if (!hiring.rows.length) return res.status(404).json({ success: false, message: 'Application not found' });

    const app = hiring.rows[0];
    if (!app.converted_to_astrologer) return res.status(400).json({ success: false, message: 'Astrologer account not created yet' });
    if (app.welcome_email_sent) return res.status(409).json({ success: false, message: 'Welcome email already sent' });
    if (!app.email) return res.status(400).json({ success: false, message: 'No email address on file' });

    // Get the user to generate a new temp password
    const userResult = await db.query('SELECT id FROM users WHERE id = $1', [app.astrologer_user_id]);
    if (!userResult.rows.length) return res.status(404).json({ success: false, message: 'Astrologer user account not found' });

    // Generate and set a new temp password
    const tempPassword = Math.random().toString(36).slice(-8).toUpperCase();
    const passwordHash = await bcrypt.hash(tempPassword, 10);
    await db.query('UPDATE users SET password_hash = $1 WHERE id = $2', [passwordHash, app.astrologer_user_id]);

    await sendAstrologerWelcome({
      to: app.email,
      name: app.name || 'Astrologer',
      email: app.email,
      password: tempPassword,
    });

    await db.query('UPDATE agent_hirings SET welcome_email_sent = TRUE WHERE id = $1', [id]);

    res.json({ success: true, message: `Welcome email resent to ${app.email}` });
  } catch (err) {
    console.error('resendWelcomeEmail error:', err);
    res.status(500).json({ success: false, message: err.message || 'Failed to resend email' });
  }
};

// Admin: update status
exports.updateStatus = async (req, res) => {
  try {
    const { status, admin_notes } = req.body;
    if (!VALID_STATUSES.includes(status)) return res.status(400).json({ success: false, message: 'Invalid status' });
    const result = await db.query(
      `UPDATE agent_hirings SET status = $1, admin_notes = $2, updated_at = NOW() WHERE id = $3 RETURNING *`,
      [status, admin_notes || null, req.params.id]
    );
    if (!result.rows.length) return res.status(404).json({ success: false, message: 'Application not found' });
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
