// src/routes/authRoutes.js
// Routes d'authentification client — version complète

const express = require('express');
const router = express.Router();
const {
  register,
  login,
  me,
  uploadAvatar,
  updateFcmToken,
  logout,
  forgotPassword,
  resetPassword,
  googleLogin,
  changePassword
} = require('../controllers/authController');
const { authMiddleware, requireCustomer } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

// ── Routes publiques (sans authentification) ──────────────────
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/google', googleLogin);

// ── Routes protégées (token + rôle customer requis) ───────────
router.get('/me', authMiddleware, requireCustomer, me);
router.post('/fcm-token', authMiddleware, requireCustomer, updateFcmToken);
router.post('/logout', authMiddleware, requireCustomer, logout);
router.patch('/me/avatar', authMiddleware, requireCustomer, upload.single('avatar'), uploadAvatar);
router.patch('/change-password', authMiddleware, requireCustomer, changePassword);

module.exports = router;