// src/server.js
// ═══════════════════════════════════════════════════════════════════
// SERVEUR EXPRESS — POINT D'ENTRÉE DE L'API
// ═══════════════════════════════════════════════════════════════════

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();

// Initialisation de l'application Express
const app = express();

// ===================================================================
// 1. MIDDLEWARES GLOBAUX
// ===================================================================
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// ===================================================================
// 2. ROUTES DE TEST
// ===================================================================

// Route racine
app.get('/', (req, res) => {
  res.json({ message: '✅ API Client Glotelho opérationnelle' });
});

// Route de test DB
const pool = require('./config/db');
app.get('/test-db', async (req, res) => {
  try {
    const [rows] = await pool.query('SELECT 1 as test');
    res.json({ success: true, message: 'Base de données connectée', data: rows });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ===================================================================
// 3. ROUTES DE L'API
// ===================================================================
app.use('/api/v1/auth', require('./routes/authRoutes'));

// Routes client (commandes, confirmation, annulation, notation)
app.use('/api/v1/client', require('./routes/clientRoutes'));

// ===================================================================
// 4. LANCEMENT DU SERVEUR
// ===================================================================
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`✅ [Client] Serveur lancé sur http://localhost:${PORT}`);
});