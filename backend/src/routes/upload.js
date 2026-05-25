const router = require('express').Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { authenticate } = require('../middleware/auth');

// ── Storage factory ───────────────────────────────────────────────────────────
function makeStorage(subdir) {
  return multer.diskStorage({
    destination: (req, file, cb) => {
      const dir = path.join(__dirname, '../../uploads', subdir);
      fs.mkdirSync(dir, { recursive: true });
      cb(null, dir);
    },
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase() || '.bin';
      cb(null, `${subdir}_${req.user.id}_${Date.now()}${ext}`);
    },
  });
}

function imageFilter(req, file, cb) {
  const allowed = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
  const ext = path.extname(file.originalname).toLowerCase();
  if (allowed.includes(ext)) cb(null, true);
  else cb(new Error('Only image files are allowed'));
}

function documentFilter(req, file, cb) {
  const allowed = ['.jpg', '.jpeg', '.png', '.pdf'];
  const ext = path.extname(file.originalname).toLowerCase();
  if (allowed.includes(ext)) cb(null, true);
  else cb(new Error('Only JPG, PNG and PDF files are allowed'));
}

const uploaders = {
  avatar:    multer({ storage: makeStorage('avatars'),   fileFilter: imageFilter,    limits: { fileSize: 5  * 1024 * 1024 } }),
  chat:      multer({ storage: makeStorage('chat'),      fileFilter: imageFilter,    limits: { fileSize: 10 * 1024 * 1024 } }),
  community: multer({ storage: makeStorage('community'), fileFilter: imageFilter,    limits: { fileSize: 10 * 1024 * 1024 } }),
  document:  multer({ storage: makeStorage('documents'), fileFilter: documentFilter, limits: { fileSize: 10 * 1024 * 1024 } }),
  thumbnail: multer({ storage: makeStorage('thumbnails'),fileFilter: imageFilter,    limits: { fileSize: 5  * 1024 * 1024 } }),
};

const BASE_URL = process.env.BASE_URL || 'https://api.astrovaak.online';

function buildUrl(subdir, filename) {
  return `${BASE_URL}/uploads/${subdir}/${filename}`;
}

// ── POST /api/upload/avatar ───────────────────────────────────────────────────
// Uploads a profile avatar for the logged-in user and syncs the astrologers row.
router.post('/avatar', authenticate, uploaders.avatar.single('file'), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });
    const db = require('../config/database');
    const url = buildUrl('avatars', req.file.filename);
    await db.query('UPDATE users SET avatar_url=$1, updated_at=NOW() WHERE id=$2', [url, req.user.id]);
    await db.query('UPDATE astrologers SET avatar_url=$1 WHERE user_id=$2', [url, req.user.id]);
    res.json({ success: true, url });
  } catch (err) {
    console.error('Avatar upload error:', err);
    res.status(500).json({ success: false, message: 'Upload failed' });
  }
});

// ── POST /api/upload/chat ─────────────────────────────────────────────────────
// Uploads an image to be shared in a consultation chat.
// Returns the public URL; the caller then sends it via the send_message socket
// event with message_type: 'image' and media_url set to this URL.
router.post('/chat', authenticate, uploaders.chat.single('file'), (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });
    const url = buildUrl('chat', req.file.filename);
    res.json({ success: true, url });
  } catch (err) {
    console.error('Chat upload error:', err);
    res.status(500).json({ success: false, message: 'Upload failed' });
  }
});

// ── POST /api/upload/community ────────────────────────────────────────────────
// Uploads an image for a community post.
router.post('/community', authenticate, uploaders.community.single('file'), (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });
    const url = buildUrl('community', req.file.filename);
    res.json({ success: true, url });
  } catch (err) {
    console.error('Community upload error:', err);
    res.status(500).json({ success: false, message: 'Upload failed' });
  }
});

// ── POST /api/upload/thumbnail ────────────────────────────────────────────────
// Uploads a thumbnail for a live session.
router.post('/thumbnail', authenticate, uploaders.thumbnail.single('file'), (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ success: false, message: 'No file uploaded' });
    const url = buildUrl('thumbnails', req.file.filename);
    res.json({ success: true, url });
  } catch (err) {
    console.error('Thumbnail upload error:', err);
    res.status(500).json({ success: false, message: 'Upload failed' });
  }
});

// ── POST /api/upload/document ─────────────────────────────────────────────────
// Uploads a verification document for astrologer registration (ID proof, certificate, etc.).
// Accepts: jpg, png, pdf. Returns URL stored in the astrologers.documents JSONB column.
router.post('/document', authenticate, uploaders.document.array('files', 5), async (req, res) => {
  try {
    if (!req.files || req.files.length === 0) return res.status(400).json({ success: false, message: 'No files uploaded' });
    const db = require('../config/database');
    const urls = req.files.map(f => buildUrl('documents', f.filename));

    // Append to existing documents array in astrologers table (if row exists)
    await db.query(
      `UPDATE astrologers
       SET documents = COALESCE(documents, '[]'::jsonb) || $1::jsonb
       WHERE user_id = $2`,
      [JSON.stringify(urls), req.user.id]
    ).catch(() => {}); // ignore if astrologer row doesn't exist yet

    res.json({ success: true, urls });
  } catch (err) {
    console.error('Document upload error:', err);
    res.status(500).json({ success: false, message: 'Upload failed' });
  }
});

// ── Multer error handler ──────────────────────────────────────────────────────
router.use((err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') return res.status(400).json({ success: false, message: 'File too large' });
    return res.status(400).json({ success: false, message: err.message });
  }
  if (err) return res.status(400).json({ success: false, message: err.message });
  next();
});

module.exports = router;
