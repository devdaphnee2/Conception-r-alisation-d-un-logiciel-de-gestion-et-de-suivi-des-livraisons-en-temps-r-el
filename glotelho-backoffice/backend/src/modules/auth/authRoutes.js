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
router.get('/verify-reset-token', async function(req, res) {
    try {
        var token = req.query.token;
        var tokenHash = require('crypto').createHash('sha256').update(token).digest('hex');
        var user = await require('../../utils/prismaClient').users.findFirst({
            where: { reset_password_token: tokenHash, reset_password_expires: { gt: new Date() } }
        });
        if (!user) return res.status(400).json({ message: 'Lien invalide ou expiré.' });
        res.json({ valid: true });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur' });
    }
});

// Protegees
router.get('/me', authMiddleware, auth.me);
router.post('/change-password', authMiddleware, auth.changePassword);
router.patch('/fcm-token', authMiddleware, auth.updateFcmToken);
router.post('/logout', authMiddleware, auth.logout);

module.exports = router;