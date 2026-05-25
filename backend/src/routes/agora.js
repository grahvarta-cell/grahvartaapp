const router = require('express').Router();
const { authenticate } = require('../middleware/auth');

const APP_ID = process.env.AGORA_APP_ID || 'cfc5ddec9cdd48f09a301aba96991a25';
const APP_CERT = process.env.AGORA_APP_CERTIFICATE || '';

router.get('/token', authenticate, (req, res) => {
  const { channel, uid = 0 } = req.query;
  if (!channel) return res.status(400).json({ success: false, message: 'channel is required' });

  let token = null;
  if (APP_CERT) {
    try {
      const { RtcTokenBuilder, RtcRole } = require('agora-access-token');
      const expiry = Math.floor(Date.now() / 1000) + 3600;
      token = RtcTokenBuilder.buildTokenWithUid(APP_ID, APP_CERT, channel, parseInt(uid), RtcRole.PUBLISHER, expiry);
    } catch (e) {
      console.error('Agora token error:', e.message);
    }
  }

  res.json({ success: true, token, app_id: APP_ID, channel, uid: parseInt(uid) });
});

module.exports = router;
