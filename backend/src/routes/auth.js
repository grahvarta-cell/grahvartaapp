const router = require('express').Router();
const { body } = require('express-validator');
const multer = require('multer');
const path = require('path');
const authController = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

const avatarStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const dir = path.join(__dirname, '../../uploads/avatars');
    require('fs').mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '.jpg';
    cb(null, `user_${req.user.id}_${Date.now()}${ext}`);
  },
});
const uploadAvatar = multer({ storage: avatarStorage, limits: { fileSize: 5 * 1024 * 1024 } });

router.post('/register', [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 6 }),
  body('name').trim().isLength({ min: 2 }),
], authController.register);

router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').exists(),
], authController.login);

router.get('/profile', authenticate, authController.getProfile);
router.put('/profile', authenticate, authController.updateProfile);
router.post('/avatar', authenticate, uploadAvatar.single('avatar'), authController.uploadAvatar);
router.post('/change-password', authenticate, authController.changePassword);

module.exports = router;
