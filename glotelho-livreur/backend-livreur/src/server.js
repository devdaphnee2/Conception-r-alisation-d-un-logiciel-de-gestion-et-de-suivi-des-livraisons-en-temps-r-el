require('dotenv').config();
const express      = require('express');
const cors         = require('cors');
const path         = require('path');
const pool         = require('./config/db');
const driverRoutes = require('./routes/driverRoutes');

const app  = express();
const PORT = process.env.PORT || 3002;

// ── Middlewares globaux ────────────────────────────────────────
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ── Fichiers uploadés accessibles publiquement ─────────────────
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// ── Routes — préfixe /api/v1 (identique au frontend Flutter) ──
app.use('/api/v1/drivers', driverRoutes);

// ── Route de santé ─────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({ message: '🚀 Backend Livreur Glotelho — opérationnel', port: PORT });
});

// ── Route inconnue ─────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ message: `Route introuvable : ${req.method} ${req.path}` });
});

// ── Erreur globale ─────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('[Erreur]', err.message);
  res.status(500).json({ message: err.message || 'Erreur serveur.' });
});

// ── Démarrage ──────────────────────────────────────────────────
async function start() {
  try {
    await pool.query('SELECT 1');
    console.log('✅ Connexion MySQL OK');
    app.listen(PORT, () => console.log(`🚀 Backend livreur démarré → port ${PORT}`));
  } catch (err) {
    console.error('❌ MySQL inaccessible :', err.message);
    process.exit(1);
  }
}

start();