// src/routes/notificationRoutes.js
const express = require('express');
const router = express.Router();
const {
  getNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead
} = require('../controllers/notificationController');
const { authMiddleware, requireCustomer } = require('../middlewares/authMiddleware');

router.get('/', authMiddleware, requireCustomer, getNotifications);
router.patch('/:id/read', authMiddleware, requireCustomer, markNotificationAsRead);
router.patch('/read-all', authMiddleware, requireCustomer, markAllNotificationsAsRead);

module.exports = router;