// ============================================================
// Google OAuth2 — deux endpoints distincts
//   POST /api/auth/google-login    -> connexion (compte doit exister)
//   POST /api/auth/google-register -> creation de compte manager
// ============================================================
const { OAuth2Client } = require('google-auth-library');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const prisma = require('../utils/prismaClient');

const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

async function verifyGoogleToken(credential) {
    const ticket = await googleClient.verifyIdToken({
        idToken: credential,
        audience: process.env.GOOGLE_CLIENT_ID,
    });
    return ticket.getPayload();
}

// ──────────────────────────────────────────────────────────
// POST /api/auth/google-login
// Connexion via Google — le compte manager DOIT deja exister
// ──────────────────────────────────────────────────────────
async function googleLogin(req, res) {
    try {
        const { credential } = req.body;
        if (!credential) return res.status(400).json({ message: 'Token Google manquant.' });

        const payload = await verifyGoogleToken(credential);
        if (!payload.email_verified) return res.status(401).json({ message: 'Email Google non verifie.' });

        const user = await prisma.users.findUnique({ where: { email: payload.email } });

        if (!user) {
            return res.status(404).json({ message: 'Aucun compte trouve avec cet email Google. Creez d\'abord un compte.' });
        }
        if (user.role !== 'manager') {
            return res.status(403).json({ message: 'Ce compte n\'est pas autorise sur le back-office manager.' });
        }

        // Lier le google_id si pas encore fait
        let finalUser = user;
        if (!user.google_id) {
            finalUser = await prisma.users.update({
                where: { id: user.id },
                data: { google_id: payload.sub, photo_url: payload.picture || user.photo_url }
            });
        }

        const token = jwt.sign({ id: finalUser.id, email: finalUser.email, role: finalUser.role }, process.env.JWT_SECRET, { expiresIn: '8h' });

        res.json({
            token,
            user: { id: finalUser.id, first_name: finalUser.first_name, last_name: finalUser.last_name, email: finalUser.email, phone: finalUser.phone, role: finalUser.role, photo_url: finalUser.photo_url }
        });
    } catch (error) {
        console.error('Erreur Google login :', error.message);
        res.status(401).json({ message: 'Echec de la connexion Google. Token invalide ou expire.' });
    }
}

// ──────────────────────────────────────────────────────────
// POST /api/auth/google-register
// Creation de compte manager via Google — refuse si l'email existe deja
// ──────────────────────────────────────────────────────────
async function googleRegister(req, res) {
    try {
        const { credential } = req.body;
        if (!credential) return res.status(400).json({ message: 'Token Google manquant.' });

        const payload = await verifyGoogleToken(credential);
        if (!payload.email_verified) return res.status(401).json({ message: 'Email Google non verifie.' });

        const existing = await prisma.users.findUnique({ where: { email: payload.email } });
        if (existing) {
            return res.status(400).json({ message: 'Un compte existe deja avec cet email. Connectez-vous plutot.' });
        }

        // Mot de passe aleatoire genere (non utilise — connexion uniquement via Google)
        const randomPassword = crypto.randomBytes(24).toString('hex');
        const hashedPassword = await bcrypt.hash(randomPassword, 10);

        const user = await prisma.users.create({
            data: {
                first_name: payload.given_name || 'Manager',
                last_name: payload.family_name || '',
                email: payload.email,
                password: hashedPassword,
                phone: '',
                role: 'manager',
                google_id: payload.sub,
                photo_url: payload.picture || null,
            }
        });

        try {
            await prisma.managers.create({ data: { user_id: user.id } });
        } catch (e) {
            console.warn('Profil manager non cree automatiquement :', e.message);
        }

        const token = jwt.sign({ id: user.id, email: user.email, role: user.role }, process.env.JWT_SECRET, { expiresIn: '8h' });

        res.status(201).json({
            message: 'Compte manager cree avec succes via Google.',
            token,
            user: { id: user.id, first_name: user.first_name, last_name: user.last_name, email: user.email, phone: user.phone, role: user.role, photo_url: user.photo_url }
        });
    } catch (error) {
        console.error('Erreur Google register :', error.message);
        res.status(401).json({ message: 'Echec de l\'inscription Google. Token invalide ou expire.' });
    }
}

module.exports = { googleLogin, googleRegister };