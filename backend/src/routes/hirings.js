const router = require('express').Router();
const ctrl = require('../controllers/hiringController');

router.post('/upload-photo', (req, res, next) => {
  ctrl.upload.single('photo')(req, res, (err) => {
    if (err) return res.status(400).json({ success: false, message: err.message });
    next();
  });
}, ctrl.uploadPhoto);
router.post('/apply', ctrl.submitApplication);
router.get('/status', ctrl.getStatus);

module.exports = router;
