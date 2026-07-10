const express          = require('express');
const router           = express.Router();
const auth             = require('../controllers/authController');
const authMiddleware   = require('../middlewares/authMiddleware');
const { uploadFields } = require('../middlewares/upload');

// ── PUBLIQUES ──────────────────────────────────────────────────
router.post('/register',        uploadFields, auth.register);
router.post('/login',                         auth.login);
router.post('/auth/google',                   auth.googleAuth);
router.post('/forgot-password',               auth.forgotPassword);
router.post('/reset-password',                auth.resetPassword);

// ── PROTÉGÉES ──────────────────────────────────────────────────
router.get  ('/me',              authMiddleware,               auth.getMe);
router.put  ('/me',              authMiddleware, uploadFields, auth.updateMe);
router.post ('/logout',          authMiddleware,               auth.logout);
router.patch('/fcm-token',       authMiddleware,               auth.updateFcmToken);
router.patch('/change-password', authMiddleware,               auth.changePassword);

module.exports = router;