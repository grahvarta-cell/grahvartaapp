const router = require('express').Router();
const ctrl = require('../controllers/withdrawalController');
const { authenticate } = require('../middleware/auth');

router.get('/payout-details', authenticate, ctrl.getPayoutDetails);
router.post('/payout-details', authenticate, ctrl.savePayoutDetails);
router.post('/request', authenticate, ctrl.requestWithdrawal);
router.get('/history', authenticate, ctrl.getWithdrawalHistory);
router.post('/complaint', authenticate, ctrl.submitComplaint);

module.exports = router;
