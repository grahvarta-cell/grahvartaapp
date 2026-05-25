const router = require('express').Router();
const ctrl = require('../controllers/reportController');
const { authenticate } = require('../middleware/auth');

router.get('/',                         authenticate, ctrl.listReports);
router.get('/free-status',              authenticate, ctrl.getFreeStatus);
router.get('/credits',                  authenticate, ctrl.getCredits);
router.get('/unlocked',                 authenticate, ctrl.getUnlockedReports);
router.get('/plans',                    authenticate, ctrl.getPlans);
router.post('/plans/purchase',          authenticate, ctrl.purchasePlan);
router.get('/:reportId/unlock-status',  authenticate, ctrl.checkUnlockStatus);
router.post('/unlock',                  authenticate, ctrl.unlockReport);
router.get('/unlocked/:unlockId',       authenticate, ctrl.getReportDetail);
router.post('/review',                  authenticate, ctrl.submitReview);

module.exports = router;
