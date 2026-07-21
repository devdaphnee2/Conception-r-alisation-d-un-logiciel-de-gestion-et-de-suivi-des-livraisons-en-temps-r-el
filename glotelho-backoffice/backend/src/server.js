require('dotenv').config();
const os  = require('os');
const app = require('./app');

const PORT = process.env.PORT || 3002;

app.listen(PORT, '0.0.0.0', () => {
    console.log('Serveur Glotelho lance sur http://localhost:' + PORT);
    console.log('Accessible sur le reseau : http://192.168.1.145:' + PORT);
});
