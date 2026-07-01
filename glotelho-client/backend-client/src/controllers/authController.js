// src/controllers/authController.js
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const pool = require('../config/db');
const {
  findUserByEmail,
  findUserById,
  createUserAndCustomer,
  getCustomerByUserId,
  updateFcmToken,
  updateAvatarUrl
} = require('../models/userModel');
const { createResetToken, findResetToken, deleteResetToken } = require('../models/passwordResetModel');

// ──────────────────────────────────────────────
// 1. INSCRIPTION
// ──────────────────────────────────────────────
async function register(req, res) {
  try {
    const { full_name, email, password, phone, address, latitude, longitude, fcm_token } = req.body;

    if (!full_name || !email || !password || !phone) {
      return res.status(400).json({ message: 'Nom complet, email, mot de passe et téléphone requis.' });
    }

    const existing = await findUserByEmail(email);
    if (existing) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = await createUserAndCustomer({
      full_name, email, password: hashedPassword, phone, address, latitude, longitude
    });

    if (fcm_token) await updateFcmToken(userId, fcm_token);

    const token = jwt.sign(
      { id: userId, email, role: 'customer' },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.status(201).json({
      message: 'Compte client créé avec succès.',
      token,
      user: {
        id: userId,
        full_name,
        email,
        phone,
        address: address || null,
        avatar_url: null
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 2. CONNEXION
// ──────────────────────────────────────────────
async function login(req, res) {
  try {
    const { email, password, fcm_token } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email et mot de passe requis.' });
    }

    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(401).json({ message: 'Identifiants incorrects.' });
    }

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ message: 'Identifiants incorrects.' });
    }

    if (user.role !== 'customer') {
      return res.status(403).json({ message: 'Accès réservé aux clients.' });
    }

    if (fcm_token) await updateFcmToken(user.id, fcm_token);

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    const customer = await getCustomerByUserId(user.id);
    const full_name = [user.first_name, user.last_name].filter(Boolean).join(' ').trim();

    res.json({
      message: 'Connexion réussie.',
      token,
      user: {
        id: user.id,
        full_name,
        email: user.email,
        phone: user.phone,
        address: customer?.address || null,
        latitude: customer?.latitude || null,
        longitude: customer?.longitude || null,
        avatar_url: user.avatar_url || null
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 3. PROFIL
// ──────────────────────────────────────────────
async function me(req, res) {
  try {
    const customer = await getCustomerByUserId(req.user.id);
    if (!customer) {
      return res.status(404).json({ message: 'Client non trouvé.' });
    }

    const full_name = [customer.first_name, customer.last_name].filter(Boolean).join(' ').trim();

    res.json({
      id: customer.id,
      full_name,
      email: customer.email,
      phone: customer.phone,
      address: customer.address,
      latitude: customer.latitude,
      longitude: customer.longitude,
      avatar_url: customer.avatar_url || null
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 4. UPLOAD PHOTO DE PROFIL (PATCH /api/v1/users/me/avatar)
// ──────────────────────────────────────────────
async function uploadAvatar(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Aucun fichier envoyé.' });
    }

    // Construire l'URL publique du fichier
    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const avatarUrl = `${baseUrl}/uploads/${req.file.filename}`;

    await updateAvatarUrl(req.user.id, avatarUrl);

    res.json({
      message: 'Photo de profil mise à jour avec succès.',
      avatar_url: avatarUrl
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 5. MISE À JOUR FCM TOKEN
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
// 6. DÉCONNEXION
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

// ──────────────────────────────────────────────
// 7. MOT DE PASSE OUBLIÉ
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

    res.status(200).json({
      message: 'Si un compte existe avec cet email, un lien de réinitialisation vous a été envoyé.'
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 8. RÉINITIALISATION DU MOT DE PASSE
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
// 9. CONNEXION AVEC GOOGLE
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
    const full_name = [given_name, family_name].filter(Boolean).join(' ').trim() || 'Utilisateur Google';

    let user = await findUserByEmail(email);

    if (!user) {
      const hashedPassword = await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10);
      const userId = await createUserAndCustomer({
        full_name, email, password: hashedPassword,
        phone: 'Non renseigné', address: null, latitude: null, longitude: null
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
    const userName = [user.first_name, user.last_name].filter(Boolean).join(' ').trim();

    res.json({
      message: 'Connexion avec Google réussie.',
      token,
      user: {
        id: user.id,
        full_name: userName || full_name,
        email: user.email,
        phone: user.phone,
        address: customer?.address || null,
        latitude: customer?.latitude || null,
        longitude: customer?.longitude || null,
        avatar_url: user.avatar_url || null
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

module.exports = {
  register,
  login,
  me,
  uploadAvatar,
  updateFcmToken: updateFcmTokenHandler,
  logout,
  forgotPassword,
  resetPassword,
  googleLogin
};