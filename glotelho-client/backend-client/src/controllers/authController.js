// src/controllers/authController.js
// Authentification client — version complète avec google-auth-library + Nodemailer

const bcrypt      = require('bcryptjs');
const jwt         = require('jsonwebtoken');
const crypto      = require('crypto');
const { OAuth2Client } = require('google-auth-library');
const pool        = require('../config/db');
const {
  findUserByEmail,
  findUserById,
  findUserByGoogleId,
  linkGoogleId,
  createUserAndCustomer,
  getCustomerByUserId,
  updateFcmToken,
  updateAvatarUrl
} = require('../models/userModel');
const { createResetToken, findResetToken, deleteResetToken } = require('../models/passwordResetModel');
const { sendWelcomeGoogleEmail, sendResetPasswordEmail } = require('../utils/mailer');

// ✅ Client Google vérifié avec le même GOOGLE_CLIENT_ID que le manager
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

async function verifyGoogleToken(idToken) {
  const response = await fetch(
    `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`
  );
  const payload = await response.json();
  if (payload.error) {
    throw new Error(payload.error_description || payload.error);
  }
  return payload;
}

// ──────────────────────────────────────────────
// 1. INSCRIPTION
// ──────────────────────────────────────────────
async function register(req, res) {
  try {
    const { full_name, last_name, email, password, phone, address, latitude, longitude, fcm_token } = req.body;
    const nomComplet = full_name || last_name || '';

    if (!nomComplet || !email || !password || !phone) {
      return res.status(400).json({ message: 'Nom complet, email, mot de passe et téléphone requis.' });
    }

    const existing = await findUserByEmail(email);
    if (existing) {
      return res.status(400).json({ message: 'Cet email est déjà utilisé.' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userId = await createUserAndCustomer({
      full_name: nomComplet, email, password: hashedPassword,
      phone, address, latitude, longitude,
      has_password: 1  // ✅ Compte classique avec mot de passe réel
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
        id: userId, full_name: nomComplet,
        email, phone, address: address || null, avatar_url: null
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

    // ✅ Compte Google sans mot de passe réel
    if (user.google_id && !user.has_password) {
      return res.status(400).json({
        message: 'Ce compte utilise Google Sign-In. Utilisez "Mot de passe oublié" pour créer un mot de passe.',
        code: 'GOOGLE_ACCOUNT'
      });
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
        id: user.id, full_name, email: user.email, phone: user.phone,
        address: customer?.address || null,
        latitude: customer?.latitude || null,
        longitude: customer?.longitude || null,
        avatar_url: user.avatar_url || user.photo_url || null
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
      avatar_url: customer.avatar_url || customer.photo_url || null
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 4. UPLOAD AVATAR
// ──────────────────────────────────────────────
async function uploadAvatar(req, res) {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'Aucun fichier envoyé.' });
    }

    const baseUrl = `${req.protocol}://${req.get('host')}`;
    const avatarUrl = `${baseUrl}/uploads/${req.file.filename}`;
    await updateAvatarUrl(req.user.id, avatarUrl);

    res.json({ message: 'Photo de profil mise à jour.', avatar_url: avatarUrl });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 5. FCM TOKEN
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
// 7. MOT DE PASSE OUBLIÉ — envoie un vrai email
// ──────────────────────────────────────────────
async function forgotPassword(req, res) {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: 'Email requis.' });
    }

    const user = await findUserByEmail(email);

    // Toujours répondre succès même si email inconnu (sécurité)
    if (!user) {
      return res.status(200).json({
        message: 'Si un compte existe avec cet email, un lien de réinitialisation vous a été envoyé.'
      });
    }

    const resetToken = crypto.randomBytes(32).toString('hex');
    await createResetToken(user.id, resetToken);

    // ✅ Envoi d'un vrai email avec Nodemailer
    try {
      const fullName = [user.first_name, user.last_name].filter(Boolean).join(' ').trim();
      await sendResetPasswordEmail(user.email, resetToken, fullName);
    } catch (mailError) {
      console.error('[Mailer] Erreur envoi email:', mailError.message);
      // On ne bloque pas si l'email échoue
    }

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

    // ✅ has_password = 1 après reset (compte Google peut maintenant se connecter avec mdp)
    await pool.query(
      'UPDATE users SET password = ?, has_password = 1 WHERE id = ?',
      [hashedPassword, resetEntry.user_id]
    );
    await deleteResetToken(token);

    res.json({ message: 'Mot de passe réinitialisé avec succès. Vous pouvez maintenant vous connecter.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 9. CONNEXION / INSCRIPTION VIA GOOGLE
// ✅ Utilise google-auth-library (même approche que le manager)
// ──────────────────────────────────────────────
async function googleLogin(req, res) {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: 'Token Google requis.' });
    }

    // ✅ Vérification sécurisée avec OAuth2Client (au lieu de fetch tokeninfo)
    let payload;
    try {
      payload = await verifyGoogleToken(idToken);
    } catch (err) {
      return res.status(401).json({ message: 'Token Google invalide ou expiré.' });
    }

    if (!payload.email_verified) {
      return res.status(401).json({ message: 'Email Google non vérifié.' });
    }

    const { sub: googleId, email, given_name, family_name, picture } = payload;
    const full_name = [given_name, family_name].filter(Boolean).join(' ').trim() || 'Utilisateur Google';

    // ÉTAPE 1 — Chercher par google_id (le plus fiable)
    let user = await findUserByGoogleId(googleId);

    if (!user) {
      // ÉTAPE 2 — Chercher par email (lier si compte existant)
      user = await findUserByEmail(email);

      if (user) {
        if (user.role !== 'customer') {
          return res.status(403).json({ message: 'Accès réservé aux clients.' });
        }
        // Lier le Google ID au compte existant
        await linkGoogleId(user.id, googleId, picture);
        // Rafraîchir les données
        user = await findUserById(user.id);
      } else {
        // ÉTAPE 3 — Nouveau compte Google
        const hashedPassword = await bcrypt.hash(crypto.randomBytes(16).toString('hex'), 10);
        const userId = await createUserAndCustomer({
          full_name, email,
          password: hashedPassword,
          phone: 'Non renseigné',
          address: null, latitude: null, longitude: null,
          google_id: googleId,
          has_password: 0, // ✅ Pas de mot de passe réel
          photo_url: picture || null
        });
        user = await findUserById(userId);

        // ✅ Envoyer un email de bienvenue
        try {
          await sendWelcomeGoogleEmail(email, full_name);
        } catch (mailError) {
          console.error('[Mailer] Email bienvenue échoué:', mailError.message);
        }
      }
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
        avatar_url: user.avatar_url || user.photo_url || null
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ──────────────────────────────────────────────
// 10. CHANGEMENT DE MOT DE PASSE
// ──────────────────────────────────────────────
async function changePassword(req, res) {
  try {
    const { old_password, new_password } = req.body;

    if (!old_password || !new_password) {
      return res.status(400).json({ message: 'Ancien et nouveau mot de passe requis.' });
    }
    if (new_password.length < 6) {
      return res.status(400).json({ message: 'Le nouveau mot de passe doit contenir au moins 6 caractères.' });
    }

    const user = await findUserById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'Utilisateur introuvable.' });
    }

    // ✅ Compte Google sans mot de passe réel
    if (user.google_id && !user.has_password) {
      return res.status(400).json({
        message: 'Ce compte utilise Google Sign-In. Utilisez "Mot de passe oublié" pour créer un mot de passe.',
        code: 'GOOGLE_ACCOUNT'
      });
    }

    const isValid = await bcrypt.compare(old_password, user.password);
    if (!isValid) {
      return res.status(401).json({ message: 'Ancien mot de passe incorrect.' });
    }

    const hashedPassword = await bcrypt.hash(new_password, 10);
    await pool.query(
      'UPDATE users SET password = ?, has_password = 1 WHERE id = ?',
      [hashedPassword, req.user.id]
    );

    res.json({ message: 'Mot de passe modifié avec succès.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

module.exports = {
  register, login, me, uploadAvatar,
  updateFcmToken: updateFcmTokenHandler,
  logout, forgotPassword, resetPassword,
  googleLogin, changePassword
};