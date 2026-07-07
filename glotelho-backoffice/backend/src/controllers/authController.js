const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const prisma = require('../utils/prismaClient');
const { sendResetPasswordEmail } = require('../utils/mailer');

// ──────────────────────────────────────────────────────────
// LOGIN
// ──────────────────────────────────────────────────────────
async function login(req, res) {
    try {
        const { email, password } = req.body;
        if (!email || !password) return res.status(400).json({ message: 'Email et mot de passe requis.' });

        const user = await prisma.users.findUnique({ where: { email } });
        if (!user) return res.status(401).json({ message: 'Identifiants incorrects.' });

        const valid = await bcrypt.compare(password, user.password);
        if (!valid) return res.status(401).json({ message: 'Identifiants incorrects.' });

        /*if (user.role !== 'manager') {
        return res.status(403).json({ message: 'Ce compte n\'est pas autorise sur le back-office manager.' });
        }*/

        const token = jwt.sign({ id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET, { expiresIn: '8h' }
        );

        res.json({
            token,
            user: { id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email, phone: user.phone, role: user.role, photo_url: user.photo_url }
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// REGISTER — Creation compte manager classique
// ──────────────────────────────────────────────────────────
async function register(req, res) {
    try {
        const { first_name, last_name, email, phone, password, confirm_password } = req.body;

        if (!first_name || !last_name || !email || !password) {
            return res.status(400).json({ message: 'Tous les champs obligatoires doivent etre remplis.' });
        }
        if (password !== confirm_password) {
            return res.status(400).json({ message: 'Les mots de passe ne correspondent pas.' });
        }
        if (password.length < 8) {
            return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 8 caracteres.' });
        }

        const existing = await prisma.users.findUnique({ where: { email } });
        if (existing) {
            return res.status(400).json({ message: 'Un compte existe deja avec cet email.' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const user = await prisma.users.create({
            data: { first_name, last_name, email, phone: phone || '', password: hashedPassword, role: 'manager' }
        });

        try {
            await prisma.managers.create({ data: { user_id: user.id } });
        } catch (e) {
            console.warn('Profil manager non cree automatiquement :', e.message);
        }

        const token = jwt.sign({ id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET, { expiresIn: '8h' }
        );

        res.status(201).json({
            message: 'Compte manager cree avec succes.',
            token,
            user: { id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email, phone: user.phone, role: user.role }
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// GET /api/auth/me
// ──────────────────────────────────────────────────────────
async function me(req, res) {
    try {
        const user = await prisma.users.findUnique({ where: { id: req.user.id } });
        if (!user) return res.status(404).json({ message: 'Utilisateur introuvable.' });
        res.json({ id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email, phone: user.phone, role: user.role, photo_url: user.photo_url });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// PUT /api/auth/me
// ──────────────────────────────────────────────────────────
async function updateMe(req, res) {
    try {
        const { first_name, last_name, email, phone } = req.body;
        if (email) {
            const existing = await prisma.users.findUnique({ where: { email } });
            if (existing && existing.id !== req.user.id) {
                return res.status(400).json({ message: 'Cet email est deja utilise par un autre compte.' });
            }
        }
        const updated = await prisma.users.update({
            where: { id: req.user.id },
            data: { first_name, last_name, email, phone }
        });
        res.json({ message: 'Profil mis a jour.', user: { id: updated.id, first_name: updated.first_name, last_name: updated.last_name, email: updated.email, phone: updated.phone, role: updated.role } });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/auth/change-password
// ──────────────────────────────────────────────────────────
async function changePassword(req, res) {
    try {
        const { current_password, new_password } = req.body;
        if (!current_password || !new_password) return res.status(400).json({ message: 'Mot de passe actuel et nouveau requis.' });
        if (new_password.length < 8) return res.status(400).json({ message: 'Le nouveau mot de passe doit contenir au moins 8 caracteres.' });

        const user = await prisma.users.findUnique({ where: { id: req.user.id } });
        const valid = await bcrypt.compare(current_password, user.password);
        if (!valid) return res.status(401).json({ message: 'Mot de passe actuel incorrect.' });

        const hashedPassword = await bcrypt.hash(new_password, 10);
        await prisma.users.update({ where: { id: req.user.id }, data: { password: hashedPassword } });
        res.json({ message: 'Mot de passe modifie avec succes.' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/auth/forgot-password
// Genere un token et envoie un VRAI email via Nodemailer
// ──────────────────────────────────────────────────────────
async function forgotPassword(req, res) {
    try {
        const { email } = req.body;
        if (!email) return res.status(400).json({ message: 'Email requis.' });

        const user = await prisma.users.findUnique({ where: { email } });

        // Toujours repondre succes meme si email inconnu (securite)
        if (!user) return res.json({ message: 'Si ce compte existe, un email de reinitialisation a ete envoye.' });

        // Generer token securise + expiration 1h
        const resetToken = crypto.randomBytes(32).toString('hex');
        const resetTokenHash = crypto.createHash('sha256').update(resetToken).digest('hex');
        const resetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1h

        await prisma.users.update({
            where: { id: user.id },
            data: { reset_password_token: resetTokenHash, reset_password_expires: resetExpires }
        });

        const resetUrl = (process.env.FRONTEND_URL || 'http://localhost:5173') + '/reset-password?token=' + resetToken;

        // Envoi du vrai email via Nodemailer
        await sendResetPasswordEmail(user.email, resetUrl, user.first_name);

        res.json({ message: 'Email de reinitialisation envoye a ' + user.email + '. Verifiez votre boite de reception.' });
    } catch (error) {
        console.error('Erreur forgot-password :', error.message);
        // Si l'email echoue, on informe sans bloquer
        if (error.message.includes('sendMail') || error.message.includes('EAUTH') || error.message.includes('credentials')) {
            return res.status(500).json({ message: 'Erreur d\'envoi email. Verifiez EMAIL_USER et EMAIL_PASS dans .env du backend.' });
        }
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// GET /api/auth/verify-reset-token
// ──────────────────────────────────────────────────────────
async function verifyResetToken(req, res) {
    try {
        const { token } = req.query;
        if (!token) return res.status(400).json({ message: 'Token requis.' });

        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        const user = await prisma.users.findFirst({
            where: { reset_password_token: tokenHash, reset_password_expires: { gt: new Date() } }
        });

        if (!user) return res.status(400).json({ message: 'Lien invalide ou expire.' });
        res.json({ valid: true });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/auth/reset-password
// ──────────────────────────────────────────────────────────
async function resetPassword(req, res) {
    try {
        const { token, password } = req.body;
        if (!token || !password) return res.status(400).json({ message: 'Token et mot de passe requis.' });
        if (password.length < 8) return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 8 caracteres.' });

        const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
        const user = await prisma.users.findFirst({
            where: { reset_password_token: tokenHash, reset_password_expires: { gt: new Date() } }
        });

        if (!user) return res.status(400).json({ message: 'Lien invalide ou expire. Veuillez en redemander un.' });

        const hashedPassword = await bcrypt.hash(password, 10);
        await prisma.users.update({
            where: { id: user.id },
            data: { password: hashedPassword, reset_password_token: null, reset_password_expires: null }
        });

        res.json({ message: 'Mot de passe reinitialise avec succes. Vous pouvez vous connecter.' });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}
async function loginMobile(req, res) {
    try {
        const { email, password } = req.body;
        if (!email || !password) return res.status(400).json({ message: 'Email et mot de passe requis.' });
        const user = await prisma.users.findUnique({ where: { email } });
        if (!user) return res.status(401).json({ message: 'Identifiants incorrects.' });
        const valid = await bcrypt.compare(password, user.password);
        if (!valid) return res.status(401).json({ message: 'Identifiants incorrects.' });
        const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, process.env.JWT_SECRET, { expiresIn: '8h' });
        res.json({ token, user: { id: user.id, first_name: user.first_name, email: user.email, role: user.role } });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error: error.message });
    }
}

module.exports = { login, loginMobile, register, me, updateMe, changePassword, forgotPassword, verifyResetToken, resetPassword };