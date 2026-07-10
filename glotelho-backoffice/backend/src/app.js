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
const trackingPublicRoutes = require('./routes/trackingPublicRoutes');

const driversRoutes = require('./routes/driversRoutes');
const path = require('path');



app.use(cors({
    origin: [
        'http://localhost:5173',
        'http://192.168.1.145:5173',
        process.env.FRONTEND_URL,
    ].filter(Boolean),
    credentials: true,
}));

app.use(express.json());

app.get('/', (req, res) => {
    res.json({ message: 'API Glotelho Back-office operationnelle' });
});

app.use('/api/auth', authRoutes);
// Route publique AVANT la route protegee
app.use('/api/livraisons/public', trackingPublicRoutes);
app.use('/api/livraisons', livraisonRoutes);
app.use('/api/livreurs', livreurRoutes);
app.use('/api/litiges', litigeRoutes);
app.use('/api/customers', customerRoutes);
app.use('/api/vehicules', vehiculeRoutes);
app.use('/api/bordereaux', bordereauRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/profils', profilRoutes);
app.use('/api/mobile/livreur', livreurMobileRoutes);
app.use('/api/recouvrements', recouvrementRoutes);

app.use('/uploads', express.static(path.join(__dirname, '../uploads')));


app.use('/api/v1/drivers', driversRoutes);
app.use('/api/drivers', driversRoutes);

module.exports = app;