// src/middlewares/uploadMiddleware.js
// Gestion de l'upload de fichiers avec multer

const multer = require('multer');
const path = require('path');

// Configuration du stockage local
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'uploads/'); // Dossier de stockage
  },
  filename: (req, file, cb) => {
    // Nom unique : userId_timestamp.extension
    const ext = path.extname(file.originalname);
    cb(null, `avatar_${req.user.id}_${Date.now()}${ext}`);
  }
});

// Filtre : uniquement les images
const fileFilter = (req, file, cb) => {
  const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Seules les images JPEG, PNG et WebP sont acceptées.'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 5 * 1024 * 1024 } // 5 Mo max
});

module.exports = upload;