// src/routes/authRoutes.js
// Routes d'authentification client

const express = require('express');
const router = express.Router();
const {
  register,
  login,
  me,
  forgotPassword,
  resetPassword,
  googleLogin,
  updateFcmToken,
  logout
} = require('../controllers/authController');
const { authMiddleware, requireCustomer } = require('../middlewares/authMiddleware');

// Routes publiques
router.post('/register', register);
router.post('/login', login);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/google', googleLogin);

// Routes protégées (authentification + rôle customer)
router.get('/me', authMiddleware, requireCustomer, me);
router.post('/fcm-token', authMiddleware, requireCustomer, updateFcmToken);
router.post('/logout', authMiddleware, requireCustomer, logout);

module.exports = router;