const router = require('express').Router();
const db = require('../config/database');
const { authenticate } = require('../middleware/auth');

router.patch('/:id/end', authenticate, async (req, res) => {
  try {
    await db.query(
      `UPDATE consultations SET status = 'completed', ended_at = NOW() WHERE id = $1 AND user_id = $2 AND status != 'completed'`,
      [req.params.id, req.user.id]
    );
    await db.query(
      `UPDATE consultation_queue SET status = 'cancelled' WHERE consultation_id = $1`,
      [req.params.id]
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Server error' });
  }
});

module.exports = router;
