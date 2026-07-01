// src/routes/authRoutes.js
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
  googleLogin
} = require('../controllers/authController');
const { authMiddleware, requireCustomer } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');

// Routes publiques
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/google', googleLogin);

// Routes protégées
router.get('/me', authMiddleware, requireCustomer, me);
router.post('/fcm-token', authMiddleware, requireCustomer, updateFcmToken);
router.post('/logout', authMiddleware, requireCustomer, logout);

// Upload photo de profil
router.patch('/me/avatar', authMiddleware, requireCustomer, upload.single('avatar'), uploadAvatar);

module.exports = router;