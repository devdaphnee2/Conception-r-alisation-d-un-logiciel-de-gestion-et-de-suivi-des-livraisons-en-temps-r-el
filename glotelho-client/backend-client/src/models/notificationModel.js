// src/models/notificationModel.js
const pool = require('../config/db');

// ── Récupérer les notifications d'un utilisateur ─────────────────
const getNotificationsByUserId = async (userId) => {
  const [rows] = await pool.query(
    `SELECT id, message, type, is_read, sent_at
     FROM notifications
     WHERE recipient_id = ?
     ORDER BY sent_at DESC`,
    [userId]
  );
  return rows;
};

// ── Marquer une notification comme lue ──────────────────────────
const markAsRead = async (notificationId, userId) => {
  await pool.query(
    `UPDATE notifications SET is_read = 1
     WHERE id = ? AND recipient_id = ?`,
    [notificationId, userId]
  );
};

// ── Marquer toutes les notifications comme lues ──────────────────
const markAllAsRead = async (userId) => {
  await pool.query(
    `UPDATE notifications SET is_read = 1
     WHERE recipient_id = ? AND is_read = 0`,
    [userId]
  );
};

// ── Compter les notifications non lues ───────────────────────────
const countUnread = async (userId) => {
  const [rows] = await pool.query(
    `SELECT COUNT(*) as count FROM notifications
     WHERE recipient_id = ? AND is_read = 0`,
    [userId]
  );
  return rows[0].count;
};

module.exports = { getNotificationsByUserId, markAsRead, markAllAsRead, countUnread };