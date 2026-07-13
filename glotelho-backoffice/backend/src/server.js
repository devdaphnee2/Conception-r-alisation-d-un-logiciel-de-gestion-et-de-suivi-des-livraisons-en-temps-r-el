require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => {
    console.log('Serveur Glotelho lance sur http://localhost:' + PORT);
    console.log('Accessible sur le reseau : http://192.168.1.145:' + PORT);
});
