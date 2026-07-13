const express = require('express');
const router = express.Router();
const auth = require('./authController');
const authMiddleware = require('../../middlewares/authMiddleware');

// Publiques
router.post('/login', auth.login);
router.post('/login-mobile', auth.loginMobile);
router.post('/register', auth.register);
router.post('/forgot-password', auth.forgotPassword);
router.post('/reset-password', auth.resetPassword);
router.post('/google-login', auth.googleLogin);

// Protegees
router.get('/me', authMiddleware, auth.me);
router.post('/change-password', authMiddleware, auth.changePassword);
router.patch('/fcm-token', authMiddleware, auth.updateFcmToken);
router.post('/logout', authMiddleware, auth.logout);

module.exports = router;