const router = require('express').Router();
const ctrl = require('../controllers/hiringController');

router.post('/upload-photo', ctrl.upload.single('photo'), ctrl.uploadPhoto);
router.post('/apply', ctrl.submitApplication);
router.get('/status', ctrl.getStatus);

module.exports = router;
