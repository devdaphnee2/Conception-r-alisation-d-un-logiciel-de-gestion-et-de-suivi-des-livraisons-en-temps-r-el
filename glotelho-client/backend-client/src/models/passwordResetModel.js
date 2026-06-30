// src/models/passwordResetModel.js
// Gestion des tokens de réinitialisation de mot de passe

const pool = require('../config/db');

// Créer un token de réinitialisation
const createResetToken = async (userId, token) => {
  await pool.query(
    `INSERT INTO password_resets (user_id, token, created_at)
     VALUES (?, ?, NOW())`,
    [userId, token]
  );
};

// Trouver un token valide (non expiré — 15 minutes)
const findResetToken = async (token) => {
  const [rows] = await pool.query(
    `SELECT * FROM password_resets 
     WHERE token = ? AND created_at > NOW() - INTERVAL 15 MINUTE`,
    [token]
  );
  return rows[0];
};

// Supprimer un token (après utilisation)
const deleteResetToken = async (token) => {
  await pool.query('DELETE FROM password_resets WHERE token = ?', [token]);
};

module.exports = { createResetToken, findResetToken, deleteResetToken };