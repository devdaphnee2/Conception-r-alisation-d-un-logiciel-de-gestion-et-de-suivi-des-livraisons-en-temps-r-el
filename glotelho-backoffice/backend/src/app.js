const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const livraisonRoutes = require('./routes/livraisonRoutes');
const livreurRoutes = require('./routes/livreurRoutes');
const litigeRoutes = require('./routes/litigeRoutes');
const customerRoutes = require('./routes/customerRoutes');
const bordereauRoutes = require('./routes/bordereauRoutes');

const app = express();

app.use(cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    credentials: true,
}));
app.use(express.json());

app.use('/api/auth', authRoutes);
app.use('/api/livraisons', livraisonRoutes);
app.use('/api/livreurs', livreurRoutes);
app.use('/api/litiges', litigeRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/bordereaux', bordereauRoutes);

app.get('/', (req, res) => {
    res.json({ message: 'API Glotelho Back-office — operationnelle' });
});

module.exports = app;