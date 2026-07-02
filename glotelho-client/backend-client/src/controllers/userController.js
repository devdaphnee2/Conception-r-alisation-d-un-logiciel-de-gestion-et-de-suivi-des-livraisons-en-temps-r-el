// src/controllers/userController.js
// Gestion du profil utilisateur

const {
  getCustomerByUserId,
  updateProfile
} = require('../models/userModel');

// ──────────────────────────────────────────────
// MISE À JOUR DU PROFIL (PATCH /api/v1/users/me)
// ──────────────────────────────────────────────
async function updateMe(req, res) {
  try {
    const { full_name, email, phone } = req.body;

    if (!full_name && !email && !phone) {
      return res.status(400).json({ message: 'Au moins un champ à mettre à jour est requis.' });
    }

    // Récupérer les données actuelles
    const customer = await getCustomerByUserId(req.user.id);
    if (!customer) {
      return res.status(404).json({ message: 'Utilisateur introuvable.' });
    }

    // Utiliser les nouvelles valeurs ou garder les anciennes
    const updatedData = {
      full_name: full_name || customer.first_name,
      email:     email     || customer.email,
      phone:     phone     || customer.phone,
    };

    await updateProfile(req.user.id, updatedData);

    // Récupérer le profil mis à jour
    const updated = await getCustomerByUserId(req.user.id);
    const name = [updated.first_name, updated.last_name].filter(Boolean).join(' ').trim();

    res.json({
      message: 'Profil mis à jour avec succès.',
      user: {
        id:         updated.id,
        full_name:  name || updatedData.full_name,
        email:      updated.email,
        phone:      updated.phone,
        address:    updated.address,
        avatar_url: updated.avatar_url || null
      }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

module.exports = { updateMe };