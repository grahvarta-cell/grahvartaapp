const router = require('express').Router();
const ctrl = require('../controllers/walletController');
const { authenticate } = require('../middleware/auth');

router.get('/recharge-offers', ctrl.getRechargeOffers);
router.get('/', authenticate, ctrl.getWallet);
router.get('/stats', authenticate, ctrl.getWalletStats);
router.get('/transactions', authenticate, ctrl.getTransactions);
router.post('/add-money/order', authenticate, ctrl.createAddMoneyOrder);
router.post('/add-money/verify', authenticate, ctrl.verifyAndCredit);
router.get('/plans', ctrl.getSubscriptionPlans);
router.post('/subscribe', authenticate, ctrl.purchaseSubscription);

module.exports = router;
