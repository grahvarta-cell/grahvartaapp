const router = require('express').Router();
const contentController = require('../controllers/contentController');
const birthChartController = require('../controllers/birthChartController');
const { authenticate } = require('../middleware/auth');

// Dashboard
router.get('/dashboard', authenticate, contentController.getDashboard);

// Birth Chart
router.get('/birth-chart', authenticate, birthChartController.getBirthChart);

// Transits
router.get('/transits', authenticate, birthChartController.getTransits);

// Audio / Sleep Stories
router.get('/audio', authenticate, contentController.getAudioContent);
router.get('/audio/:id', authenticate, contentController.getAudioById);

// Courses
router.get('/courses', authenticate, contentController.getCourses);
router.get('/courses/:id', authenticate, contentController.getCourseById);
router.post('/courses/:id/progress', authenticate, contentController.updateCourseProgress);

// Affirmations
router.get('/affirmations', authenticate, contentController.getAffirmations);

module.exports = router;
