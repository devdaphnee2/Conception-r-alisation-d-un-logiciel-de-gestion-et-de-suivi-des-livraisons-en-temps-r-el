const express = require('express');
const cors = require('cors');
const app = express();


const authRoutes = require('./routes/authRoutes');
const livraisonRoutes = require('./routes/livraisonRoutes');
const livreurRoutes = require('./routes/livreurRoutes');
const litigeRoutes = require('./routes/litigeRoutes');
const customerRoutes = require('./routes/customerRoutes');
const vehiculeRoutes = require('./routes/vehiculeRoutes');
const bordereauRoutes = require('./routes/bordereauRoutes');
const orderRoutes = require('./routes/orderRoutes');
const profilRoutes = require('./routes/profilRoutes');
const livreurMobileRoutes = require('./routes/livreurMobileRoutes');
const recouvrementRoutes = require('./routes/recouvrementRoutes');

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
app.use('/api/vehicules', vehiculeRoutes);
app.use('/api/bordereaux', bordereauRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/profils', profilRoutes);
app.get('/', (req, res) => {
    res.json({ message: 'API Glotelho Back-office operationnelle' });
});
app.use('/api/mobile/livreur', livreurMobileRoutes);
app.use('/api/recouvrements', recouvrementRoutes);

module.exports = app;