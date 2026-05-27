const router = require('express').Router();
const { body } = require('express-validator');
const { authenticateAdmin } = require('../middleware/adminAuth');
const ctrl = require('../controllers/adminController');

// Auth (no middleware)
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').exists(),
], ctrl.login);

// All routes below require admin token
router.use(authenticateAdmin);

// Dashboard
router.get('/dashboard', ctrl.getDashboardStats);

// User Management
router.get('/users', ctrl.listUsers);
router.get('/users/:id', ctrl.getUser);
router.post('/users/:id/ban', ctrl.banUser);
router.post('/users/:id/unban', ctrl.unbanUser);

// Astrologer Management
router.get('/astrologers', ctrl.listAstrologers);
router.post('/astrologers/:id/approve', ctrl.approveAstrologer);
router.post('/astrologers/:id/reject', ctrl.rejectAstrologer);
router.put('/astrologers/:id/rates', ctrl.setAstrologerRates);
router.post('/astrologers/:id/toggle-online', ctrl.toggleAstrologerOnline);
router.get('/astrologers/:id/earnings', ctrl.getAstrologerEarnings);

// Reports Management
router.get('/reports', ctrl.listReports);
router.post('/reports', ctrl.createReport);
router.put('/reports/:id', ctrl.updateReport);
router.delete('/reports/:id', ctrl.deleteReport);
router.post('/reports/:id/toggle', ctrl.toggleReport);
router.get('/reports/:id/stats', ctrl.getReportStats);

// Wallet & Transactions
router.get('/transactions', ctrl.listTransactions);
router.post('/wallet/credit', [
  body('user_id').notEmpty(),
  body('amount').isFloat({ gt: 0 }),
], ctrl.manualCredit);
router.post('/wallet/debit', [
  body('user_id').notEmpty(),
  body('amount').isFloat({ gt: 0 }),
], ctrl.manualDebit);
router.post('/transactions/:id/refund', ctrl.refundTransaction);

// Withdrawal Requests
router.get('/withdrawals', ctrl.listWithdrawals);
router.post('/withdrawals/:id/approve', ctrl.approveWithdrawal);
router.post('/withdrawals/:id/reject', ctrl.rejectWithdrawal);

// Community Moderation
router.get('/community', ctrl.listCommunityPosts);
router.post('/community/:id/approve', ctrl.approvePost);
router.post('/community/:id/reject', ctrl.rejectPost);
router.delete('/community/:id', ctrl.deletePostAdmin);

// Push Notifications
router.post('/notifications/broadcast', [
  body('title').notEmpty(),
  body('body').notEmpty(),
], ctrl.sendBroadcastNotification);
router.post('/notifications/segment', [
  body('title').notEmpty(),
  body('body').notEmpty(),
], ctrl.sendSegmentedNotification);

const hiringCtrl = require('../controllers/hiringController');
router.get('/hirings', hiringCtrl.listApplications);
router.patch('/hirings/:id', hiringCtrl.updateStatus);

// Recharge Offers Management
const walletCtrl = require('../controllers/walletController');
router.get('/recharge-offers', walletCtrl.adminListOffers);
router.post('/recharge-offers', walletCtrl.adminCreateOffer);
router.put('/recharge-offers/:id', walletCtrl.adminUpdateOffer);
router.delete('/recharge-offers/:id', walletCtrl.adminDeleteOffer);

module.exports = router;
