const router = require('express').Router();
const ctrl = require('../controllers/liveController');
const { authenticate } = require('../middleware/auth');

// Live sessions
router.get('/sessions', authenticate, ctrl.getLiveSessions);
router.post('/sessions', authenticate, ctrl.createLiveSession);
router.patch('/sessions/:id/start', authenticate, ctrl.startLiveSession);
router.patch('/sessions/:id/end', authenticate, ctrl.endLiveSession);

// Community
router.get('/community', authenticate, ctrl.getCommunityPosts);
router.post('/community', authenticate, ctrl.createPost);
router.delete('/community/:post_id', authenticate, ctrl.deletePost);
router.post('/community/:post_id/like', authenticate, ctrl.toggleLike);
router.get('/community/:post_id/comments', authenticate, ctrl.getComments);
router.post('/community/:post_id/comments', authenticate, ctrl.addComment);

// Notifications
router.get('/notifications', authenticate, ctrl.getNotifications);
router.patch('/notifications/read-all', authenticate, ctrl.markAllRead);
router.post('/push-token', authenticate, ctrl.registerPushToken);

module.exports = router;
