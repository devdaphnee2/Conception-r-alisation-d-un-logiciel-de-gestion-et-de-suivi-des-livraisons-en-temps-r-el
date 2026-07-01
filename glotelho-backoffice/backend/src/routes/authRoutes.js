const express = require('express');
const router = express.Router();
const authMiddleware = require('../middlewares/authMiddleware');
const {
    login,
    register,
    me,
    updateMe,
    changePassword,
    forgotPassword,
    verifyResetToken,
    resetPassword
} = require('../controllers/authController');
const { googleLogin, googleRegister } = require('../controllers/googleAuthController');

// ── Connexion (2 options) ───────────────────────────────────
router.post('/login', login); // Option B : username + mot de passe
router.post('/google-login', googleLogin); // Option A : Google (compte existant)

// ── Inscription (2 options) ─────────────────────────────────
router.post('/register', register); // Option B : formulaire complet
router.post('/google-register', googleRegister); // Option A : Google (creation auto)

// ── Mot de passe oublie ─────────────────────────────────────
router.post('/forgot-password', forgotPassword);
router.get('/verify-reset-token', verifyResetToken);
router.post('/reset-password', resetPassword);

// ── Routes protegees ────────────────────────────────────────
router.get('/me', authMiddleware, me);
router.put('/me', authMiddleware, updateMe);
router.post('/change-password', authMiddleware, changePassword);

module.exports = router;