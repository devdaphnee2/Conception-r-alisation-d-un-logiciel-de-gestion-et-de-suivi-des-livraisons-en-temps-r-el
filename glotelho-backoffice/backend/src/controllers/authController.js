const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const prisma = require('../utils/prismaClient');

async function login(req, res) {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: 'Email et mot de passe requis.' });
        }

        const user = await prisma.users.findUnique({
            where: { email },
            include: { managers: true },
        });

        if (!user) {
            return res.status(401).json({ message: 'Identifiants incorrects.' });
        }

        const passwordMatch = await bcrypt.compare(password, user.password);

        if (!passwordMatch) {
            return res.status(401).json({ message: 'Identifiants incorrects.' });
        }

        if (user.role !== 'manager') {
            return res.status(403).json({ message: 'Accès réservé aux managers.' });
        }

        const token = jwt.sign({ id: user.id, email: user.email, role: user.role },
            process.env.JWT_SECRET, { expiresIn: '8h' }
        );

        res.json({
            message: 'Connexion réussie.',
            token,
            user: {
                id: user.id,
                first_name: user.first_name,
                last_name: user.last_name,
                email: user.email,
                role: user.role,
            },
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ message: 'Erreur serveur.', error: error.message });
    }
}

async function me(req, res) {
    try {
        const user = await prisma.users.findUnique({
            where: { id: req.user.id },
            select: {
                id: true,
                first_name: true,
                last_name: true,
                email: true,
                role: true,
            },
        });

        res.json(user);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur.', error: error.message });
    }
}

module.exports = { login, me };