const express = require('express');
const cors = require('cors');
const path = require('path');
const app = express();

app.use(cors({ origin: '*', credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

app.get('/', (req, res) => {
    res.json({ message: 'API Glotelho v2.0 operationnelle', modules: ['auth', 'livreur', 'livraison', 'commercant', 'administration'] });
});

// AUTH
app.use('/api/auth', require('./modules/auth/authRoutes'));

// LIVREUR (app mobile Flutter)
var livreurRoutes = require('./modules/livreur/livreurRoutes');
app.use('/api/v1/drivers', livreurRoutes);
app.use('/api/mobile/livreur', livreurRoutes);

// LIVRAISON
app.use('/api/livraisons/public', require('./modules/livraison/trackingPublicRoutes'));
app.use('/api/livraisons', require('./modules/livraison/livraisonRoutes'));

// COMMERCANT (app mobile Flutter)
app.use('/api/v1/commercant', require('./modules/commercant/commercantRoutes'));

// ADMINISTRATION (back-office web)
var authMiddleware = require('./middlewares/authMiddleware');
var managerOnly = require('./middlewares/managerOnly');

app.use('/api/livreurs', authMiddleware, managerOnly, require('./modules/administration/livreurRoutesAdminRoutes'));
app.use('/api/litiges', authMiddleware, managerOnly, require('./modules/administration/litigeRoutesAdminRoutes'));
app.use('/api/recouvrements', authMiddleware, managerOnly, require('./modules/administration/recouvrementRoutesAdminRoutes'));
app.use('/api/profils', authMiddleware, managerOnly, require('./modules/administration/profilAdminRoutes'));
app.use('/api/bordereaux', authMiddleware, managerOnly, require('./modules/administration/bordereauAdminRoutes'));

// 404
app.use((req, res) => {
    res.status(404).json({ message: 'Route introuvable : ' + req.method + ' ' + req.path });
});

app.use((err, req, res, next) => {
    console.error('[Erreur]', err.message);
    res.status(500).json({ message: err.message || 'Erreur serveur.' });
});

module.exports = app;