const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const prisma = require('../../utils/prismaClient');
const { sendResetPasswordEmail } = require('../../utils/mailer');

function genToken(user, expiresIn) {
    return jwt.sign({ id: user.id, email: user.email, role: user.role, livreurId: user.livreurId },
        process.env.JWT_SECRET || 'glotelho_secret', { expiresIn: expiresIn || '30d' }
    );
}

// ── LOGIN MANAGER (back-office web) ──────────────────────────
async function login(req, res) {
    try {
        var email = req.body.email;
        var password = req.body.password;
        if (!email || !password) return res.status(400).json({ message: 'Email et mot de passe requis.' });

        var user = await prisma.users.findUnique({ where: { email: email } });
        if (!user) return res.status(401).json({ message: 'Identifiants incorrects.' });

        var valid = await bcrypt.compare(password, user.password);
        if (!valid) return res.status(401).json({ message: 'Identifiants incorrects.' });

        var token = genToken(user, '8h');
        res.json({
            token: token,
            user: { id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email, phone: user.phone, role: user.role, photo_url: user.photo_url }
        });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

async function googleLogin(req, res) {
    try {
        var { OAuth2Client } = require('google-auth-library');
        var client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
        var idToken = req.body.credential || req.body.idToken || req.body.token;
        if (!idToken) return res.status(400).json({ message: 'Token Google requis.' });

        var ticket = await client.verifyIdToken({ idToken: idToken, audience: process.env.GOOGLE_CLIENT_ID });
        var payload = ticket.getPayload();

        var user = await prisma.users.findUnique({ where: { email: payload.email } });
        if (!user) {
            var bcrypt = require('bcrypt');
            var crypto = require('crypto');
            user = await prisma.users.create({
                data: {
                    first_name: payload.given_name || '',
                    last_name: payload.family_name || '',
                    email: payload.email,
                    password: await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10),
                    phone: '',
                    role: 'manager',
                    google_id: payload.sub,
                    photo_url: payload.picture || null,
                }
            });
            try { await prisma.managers.create({ data: { user_id: user.id } }); } catch (e) {}
        }

        var token = genToken(user, '8h');
        res.json({
            token: token,
            user: { id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email, role: user.role, photo_url: user.photo_url }
        });
    } catch (err) {
        console.error('[googleLogin]', err.message);
        res.status(401).json({ message: 'Token Google invalide.', error: err.message });
    }
}

// ── LOGIN MOBILE (livreur par telephone ou email) ─────────────
async function loginMobile(req, res) {
    try {
        var telephone = req.body.telephone;
        var email = req.body.email;
        var password = req.body.password;
        var identifiant = telephone || email;

        if (!identifiant || !password) return res.status(400).json({ message: 'Identifiant et mot de passe requis.' });

        var user = await prisma.users.findFirst({
            where: { OR: [{ phone: identifiant }, { email: identifiant }] }
        });
        if (!user) return res.status(401).json({ message: 'Identifiants incorrects.' });

        var valid = await bcrypt.compare(password, user.password);
        if (!valid) return res.status(401).json({ message: 'Identifiants incorrects.' });

        // Recuperer l'id du profil livreur
        var livreur = await prisma.delivery_persons.findFirst({ where: { user_id: user.id } });
        var livreurId = livreur ? livreur.id : null;

        var token = genToken({...user, livreurId: livreurId }, '30d');
        res.json({
            token: token,
            user: { id: user.id, first_name: user.first_name, email: user.email, role: user.role }
        });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── REGISTER MANAGER ─────────────────────────────────────────
async function register(req, res) {
    try {
        var first_name = req.body.first_name;
        var last_name = req.body.last_name;
        var email = req.body.email;
        var phone = req.body.phone;
        var password = req.body.password;

        if (!first_name || !last_name || !email || !password) {
            return res.status(400).json({ message: 'Tous les champs obligatoires doivent etre remplis.' });
        }
        if (password.length < 8) return res.status(400).json({ message: 'Mot de passe minimum 8 caracteres.' });

        var existing = await prisma.users.findUnique({ where: { email: email } });
        if (existing) return res.status(400).json({ message: 'Un compte existe deja avec cet email.' });

        var hashed = await bcrypt.hash(password, 10);
        var user = await prisma.users.create({
            data: { first_name: first_name, last_name: last_name, email: email, phone: phone || '', password: hashed, role: 'manager' }
        });

        try {
            await prisma.managers.create({ data: { user_id: user.id } });
        } catch (e) {}

        var token = genToken(user, '8h');
        res.status(201).json({ message: 'Compte cree.', token: token, user: { id: user.id, first_name: user.first_name, email: user.email, role: user.role } });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── GET ME ────────────────────────────────────────────────────
async function me(req, res) {
    try {
        var user = await prisma.users.findUnique({ where: { id: req.user.id } });
        if (!user) return res.status(404).json({ message: 'Utilisateur introuvable.' });
        res.json({ id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email, phone: user.phone, role: user.role, photo_url: user.photo_url });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── FORGOT PASSWORD ──────────────────────────────────────────
async function forgotPassword(req, res) {
    try {
        var email = req.body.email;
        if (!email) return res.status(400).json({ message: 'Email requis.' });

        var user = await prisma.users.findUnique({ where: { email: email } });
        if (!user) return res.json({ message: 'Si ce compte existe, un email a ete envoye.' });

        var resetToken = crypto.randomBytes(32).toString('hex');
        var resetTokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');
        var resetExpires = new Date(Date.now() + 60 * 60 * 1000);

        await prisma.users.update({
            where: { id: user.id },
            data: { reset_password_token: resetTokenHash, reset_password_expires: resetExpires }
        });

        var resetUrl = (process.env.FRONTEND_URL || 'http://localhost:5173') + '/reset-password?token=' + resetToken;
        await sendResetPasswordEmail(user.email, resetUrl, user.first_name);

        res.json({ message: 'Email de reinitialisation envoye.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── RESET PASSWORD ────────────────────────────────────────────
async function resetPassword(req, res) {
    try {
        var token = req.body.token;
        var password = req.body.password || req.body.newPassword;
        if (!token || !password) return res.status(400).json({ message: 'Token et mot de passe requis.' });
        if (password.length < 6) return res.status(400).json({ message: 'Mot de passe minimum 6 caracteres.' });

        var tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        var user = await prisma.users.findFirst({
            where: { reset_password_token: tokenHash, reset_password_expires: { gt: new Date() } }
        });
        if (!user) return res.status(400).json({ message: 'Lien invalide ou expire.' });

        var hashed = await bcrypt.hash(password, 10);
        await prisma.users.update({
            where: { id: user.id },
            data: { password: hashed, reset_password_token: null, reset_password_expires: null }
        });

        // Supprimer aussi dans password_resets si existant
        try { await prisma.password_resets.deleteMany({ where: { user_id: user.id } }); } catch (e) {}

        res.json({ message: 'Mot de passe reinitialise avec succes.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── CHANGE PASSWORD ───────────────────────────────────────────
async function changePassword(req, res) {
    try {
        var oldPassword = req.body.old_password || req.body.current_password;
        var newPassword = req.body.new_password;
        if (!oldPassword || !newPassword) return res.status(400).json({ message: 'Ancien et nouveau mot de passe requis.' });

        var user = await prisma.users.findUnique({ where: { id: req.user.id } });
        var valid = await bcrypt.compare(oldPassword, user.password);
        if (!valid) return res.status(401).json({ message: 'Mot de passe actuel incorrect.' });

        var hashed = await bcrypt.hash(newPassword, 10);
        await prisma.users.update({ where: { id: user.id }, data: { password: hashed } });
        res.json({ message: 'Mot de passe modifie.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── FCM TOKEN ─────────────────────────────────────────────────
async function updateFcmToken(req, res) {
    try {
        var fcm_token = req.body.fcm_token;
        if (!fcm_token) return res.status(400).json({ message: 'fcm_token requis.' });
        await prisma.users.update({ where: { id: req.user.id }, data: { fcm_token: fcm_token } });
        res.json({ message: 'Token FCM mis a jour.', fcm_token: fcm_token });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

// ── LOGOUT ────────────────────────────────────────────────────
async function logout(req, res) {
    try {
        await prisma.users.update({ where: { id: req.user.id }, data: { fcm_token: null } });
        res.json({ message: 'Deconnecte.' });
    } catch (err) {
        res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
}

module.exports = { login, loginMobile, register, me, forgotPassword, resetPassword, changePassword, updateFcmToken, logout, googleLogin };