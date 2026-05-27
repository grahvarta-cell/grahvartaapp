const db = require('../config/database');
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const fs = require('fs');

const VALID_STATUSES = ['pending', 'shortlisted', 'round1', 'round2', 'activated', 'rejected'];

const uploadDir = path.join(__dirname, '../../uploads/hirings');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) => cb(null, `${uuidv4()}${path.extname(file.originalname)}`),
});
exports.upload = multer({ storage, limits: { fileSize: 5 * 1024 * 1024 }, fileFilter: (_, f, cb) => cb(null, /image/.test(f.mimetype)) });

exports.uploadPhoto = async (req, res) => {
  if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });
  res.json({ success: true, data: { url: `/uploads/hirings/${req.file.filename}` } });
};

async function generateTokenNo() {
  const r = await db.query('SELECT COUNT(*) FROM agent_hirings');
  const n = parseInt(r.rows[0].count) + 1000 + 1;
  return 'GRH-' + String(n).padStart(5, '0');
}

exports.submitApplication = async (req, res) => {
  try {
    const { phone, name, dob, gender, languages, skills, profile_picture_url, phone_type, email, works_online, hours_available } = req.body;
    if (!phone) return res.status(400).json({ success: false, message: 'Phone number is required' });
    const existing = await db.query('SELECT id FROM agent_hirings WHERE phone = $1', [phone]);
    if (existing.rows.length) return res.status(409).json({ success: false, message: 'Application already submitted for this number' });
    const tokenNo = await generateTokenNo();
    const result = await db.query(
      `INSERT INTO agent_hirings (phone, name, dob, gender, languages, skills, profile_picture_url, phone_type, email, works_online, hours_available, token_no)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12) RETURNING *`,
      [phone, name, dob || null, gender, JSON.stringify(languages || []), JSON.stringify(skills || []), profile_picture_url, phone_type, email, works_online === true || works_online === 'true', parseInt(hours_available) || 0, tokenNo]
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
      'SELECT name, phone, token_no, status, profile_picture_url, admin_notes FROM agent_hirings WHERE phone = $1',
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
