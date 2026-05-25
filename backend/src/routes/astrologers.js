const router = require('express').Router();
const ctrl = require('../controllers/astrologerController');
const { authenticate } = require('../middleware/auth');

// Specific routes BEFORE wildcard /:id
router.get('/', ctrl.listAstrologers);
router.post('/register', authenticate, ctrl.registerAsAstrologer);
router.patch('/availability', authenticate, ctrl.updateAvailability);
router.get('/me/dashboard', authenticate, ctrl.getAstrologerDashboard);
router.get('/me/wallet', authenticate, ctrl.getAstrologerWallet);
router.get('/me/transactions', authenticate, ctrl.getAstrologerTransactions);
router.get('/consultations/history', authenticate, ctrl.getConsultationHistory);
router.get('/consultations/:id/messages', authenticate, ctrl.getConsultationMessages);
router.get('/threads', authenticate, ctrl.getChatThreads);
router.get('/threads/:userId/messages', authenticate, ctrl.getUserThreadMessages);

// Wildcard routes LAST
router.get('/:id', ctrl.getAstrologer);
router.get('/:id/reviews', ctrl.getAstrologerReviews);
router.post('/:id/reviews', authenticate, ctrl.submitReview);

module.exports = router;
