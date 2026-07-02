// src/routes/userRoutes.js
const express = require('express');
const router = express.Router();
const { updateMe } = require('../controllers/userController');
const { authMiddleware, requireCustomer } = require('../middlewares/authMiddleware');
const upload = require('../middlewares/uploadMiddleware');
const { uploadAvatar } = require('../controllers/authController');

// Mise à jour du profil
router.patch('/me', authMiddleware, requireCustomer, updateMe);

// Upload avatar (accessible aussi via /api/v1/users/me/avatar)
router.patch('/me/avatar', authMiddleware, requireCustomer, upload.single('avatar'), uploadAvatar);

module.exports = router;