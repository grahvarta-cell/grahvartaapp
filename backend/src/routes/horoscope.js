const router = require('express').Router();
const horoscopeController = require('../controllers/horoscopeController');
const { authenticate } = require('../middleware/auth');

router.get('/signs', horoscopeController.getAllSigns);
router.get('/my', authenticate, horoscopeController.getUserHoroscope);
router.get('/:sign/:period', horoscopeController.getHoroscope);
router.get('/compatibility/:sign1/:sign2', horoscopeController.getCompatibility);

module.exports = router;
