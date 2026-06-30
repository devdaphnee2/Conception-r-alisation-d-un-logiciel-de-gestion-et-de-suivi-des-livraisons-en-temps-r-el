// src/controllers/authController.js
// Contrôleur d'authentification client (inspiré du backend manager)

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const pool = require('../config/db');
const {
  findUserByEmail,
  findUserById,
  createUserAndCustomer,
  getCustomerByUserId,
  updateFcmToken
} = require('../models/userModel');
const { createResetToken, findResetToken, deleteResetToken } = require('../models/passwordResetModel');

// ──────────────────────────────────────────────
// 1. INSCRIPTION (register)
// ──────────────────────────────────────────────
async function register(req, res) {
  try {
    const { last_name, first_name, email, password, phone, address, latitude, longitude, fcm_token } = req.body;

    // Vérifier que l'email n'est pas déjà utilisé
    const existing = await findUserByEmail(email);
    if (existing) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
    }

    // Hasher le mot de passe
    const hashedPassword = await bcrypt.hash(password, 10);

    // Créer l'utilisateur dans users + customers
    const userId = await createUserAndCustomer({
      last_name, first_name, email, password: hashedPassword, phone, address, latitude, longitude
    });

    // Enregistrer le token FCM si fourni
    if (fcm_token) {
      await updateFcmToken(userId, fcm_token);
    }

    // Générer le token JWT (24h)
    const token = jwt.sign(
      { id: userId, email, role: 'customer' },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Réponse (identique au format du backend manager)
    res.status(201).json({
      message: 'Compte client créé avec succès.',
      token,
      user: {
        id: userId,
        first_name,
        last_name,
        email,
        phone,
        address: address || null
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 2. CONNEXION (login)
// ──────────────────────────────────────────────
async function login(req, res) {
  try {
    const { email, password, fcm_token } = req.body;

    // Vérifier que l'email existe
    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ message: 'Identifiants incorrects.' });
    }

    // Vérifier le mot de passe
    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ message: 'Identifiants incorrects.' });
    }

    // Vérifier le rôle (client uniquement)
    if (user.role !== 'customer') {
      return res.status(403).json({ message: 'Accès réservé aux clients.' });
    }

    // Mettre à jour le token FCM
    if (fcm_token) {
      await updateFcmToken(user.id, fcm_token);
    }

    // Générer le token JWT
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    // Récupérer les infos complètes du client
    const customer = await getCustomerByUserId(user.id);

    res.json({
      message: 'Connexion réussie.',
      token,
      user: {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        phone: user.phone,
        address: customer?.address || null,
        latitude: customer?.latitude || null,
        longitude: customer?.longitude || null
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 3. PROFIL (me)
// ──────────────────────────────────────────────
async function me(req, res) {
  try {
    const customer = await getCustomerByUserId(req.user.id);
    if (!customer) {
      return res.status(404).json({ message: 'Client non trouvé.' });
    }
    res.json({
      id: customer.id,
      first_name: customer.first_name,
      last_name: customer.last_name,
      email: customer.email,
      phone: customer.phone,
      address: customer.address,
      latitude: customer.latitude,
      longitude: customer.longitude
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 4. MOT DE PASSE OUBLIÉ (forgotPassword)
// ──────────────────────────────────────────────
async function forgotPassword(req, res) {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email requis.' });
    }

    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(200).json({
        message: 'Si un compte existe avec cet email, un lien de réinitialisation vous a été envoyé.'
      });
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    await createResetToken(user.id, resetToken);

    // TODO: Envoyer l'email (nodemailer, SendGrid, etc.)
    // const resetLink = `http://localhost:3001/reset-password?token=${resetToken}`;

    res.status(200).json({
      message: 'Si un compte existe avec cet email, un lien de réinitialisation vous a été envoyé.'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 5. RÉINITIALISATION DU MOT DE PASSE (resetPassword)
// ──────────────────────────────────────────────
async function resetPassword(req, res) {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({ message: 'Token et nouveau mot de passe requis.' });
    }

    const resetEntry = await findResetToken(token);
    if (!resetEntry) {
      return res.status(400).json({ message: 'Token invalide ou expiré.' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE users SET password = ? WHERE id = ?', [hashedPassword, resetEntry.user_id]);
    await deleteResetToken(token);

    res.json({ message: 'Mot de passe réinitialisé avec succès.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 6. CONNEXION AVEC GOOGLE (googleLogin)
// ──────────────────────────────────────────────
async function googleLogin(req, res) {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: 'Token Google requis.' });
    }

    const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
    const payload = await response.json();

    if (!response.ok || !payload.email) {
      return res.status(401).json({ message: 'Token Google invalide.' });
    }

    const { email, given_name, family_name } = payload;

    let user = await findUserByEmail(email);

    if (!user) {
      const hashedPassword = await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10);
      const userId = await createUserAndCustomer({
        last_name: family_name || 'Google',
        first_name: given_name || 'User',
        email,
        password: hashedPassword,
        phone: 'Non renseigné',
        address: 'Non renseignée',
        latitude: null,
        longitude: null
      });
      user = await findUserById(userId);
    } else {
      if (user.role !== 'customer') {
        return res.status(403).json({ message: 'Accès réservé aux clients.' });
      }
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const customer = await getCustomerByUserId(user.id);

    res.json({
      message: 'Connexion avec Google réussie.',
      token,
      user: {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        email: user.email,
        phone: user.phone,
        address: customer?.address || null,
        latitude: customer?.latitude || null,
        longitude: customer?.longitude || null
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 7. MISE À JOUR FCM TOKEN (updateFcmToken)
// ──────────────────────────────────────────────
async function updateFcmTokenHandler(req, res) {
  try {
    const { fcm_token } = req.body;
    if (!fcm_token) {
      return res.status(400).json({ message: 'FCM token requis.' });
    }
    await updateFcmToken(req.user.id, fcm_token);
    res.json({ message: 'Token FCM mis à jour avec succès.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 8. DÉCONNEXION (logout)
// ──────────────────────────────────────────────
async function logout(req, res) {
  try {
    await updateFcmToken(req.user.id, null);
    res.json({ message: 'Déconnexion réussie.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

module.exports = {
  register,
  login,
  me,
  forgotPassword,
  resetPassword,
  googleLogin,
  updateFcmToken: updateFcmTokenHandler,
  logout
};