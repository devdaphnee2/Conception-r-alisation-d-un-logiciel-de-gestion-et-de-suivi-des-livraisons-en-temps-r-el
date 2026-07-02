// src/server.js
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
dotenv.config();

const app = express();

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Servir les fichiers uploadés publiquement
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

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

// Routes
app.use('/api/v1/auth', require('./routes/authRoutes'));
app.use('/api/v1/client', require('./routes/clientRoutes'));
app.use('/api/v1/users', require('./routes/userRoutes')); 

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`✅ [Client] Serveur lancé sur http://localhost:${PORT}`);
});