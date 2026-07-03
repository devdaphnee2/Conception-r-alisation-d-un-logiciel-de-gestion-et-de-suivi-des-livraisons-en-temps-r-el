// src/controllers/notificationController.js
const {
  getNotificationsByUserId,
  markAsRead,
  markAllAsRead,
  countUnread
} = require('../models/notificationModel');

// ── 1. Liste des notifications (GET /notifications) ──────────────
async function getNotifications(req, res) {
  try {
    const notifications = await getNotificationsByUserId(req.user.id);
    const unread = await countUnread(req.user.id);

    res.json({
      notifications,
      unread_count: unread
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ── 2. Marquer une notification comme lue (PATCH /notifications/:id/read) ──
async function markNotificationAsRead(req, res) {
  try {
    const { id } = req.params;
    await markAsRead(id, req.user.id);
    res.json({ message: 'Notification marquée comme lue.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

// ── 3. Marquer toutes comme lues (PATCH /notifications/read-all) ──
async function markAllNotificationsAsRead(req, res) {
  try {
    await markAllAsRead(req.user.id);
    res.json({ message: 'Toutes les notifications marquées comme lues.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Erreur serveur.', error: error.message });
  }
}

module.exports = { getNotifications, markNotificationAsRead, markAllNotificationsAsRead };