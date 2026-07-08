const express        = require('express');
const router         = express.Router();
const auth           = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware');
const { uploadFields } = require('../middlewares/upload');

// ── ROUTES PUBLIQUES (sans authentification) ───────────────────
router.post('/register',    uploadFields, auth.register);
router.post('/login',                     auth.login);
router.post('/auth/google',               auth.googleAuth);

// ── ROUTES PROTÉGÉES (authentification requise) ────────────────
router.get('/me', authMiddleware,               auth.getMe);
router.put('/me', authMiddleware, uploadFields, auth.updateMe);

// ── AJOUTS (alignés avec authController.js) ────────────────────
router.post('/logout', authMiddleware, auth.logout);           // ✅ Déconnexion
router.patch('/fcm-token', authMiddleware, auth.updateFcmToken); // ✅ Token FCM

module.exports = router;