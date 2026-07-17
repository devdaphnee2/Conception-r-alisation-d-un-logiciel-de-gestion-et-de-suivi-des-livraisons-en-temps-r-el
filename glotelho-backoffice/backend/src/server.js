require('dotenv').config();
const os  = require('os');
const app = require('./app');

const PORT = process.env.PORT || 3002;

// Récupère automatiquement l'IP locale de la machine
function getLocalIP() {
    const interfaces = os.networkInterfaces();
    for (const name of Object.keys(interfaces)) {
        for (const iface of interfaces[name]) {
            if (iface.family === 'IPv4' && !iface.internal) {
                return iface.address;
            }
        }
    }
    return 'localhost';
}

app.listen(PORT, '0.0.0.0', () => {
    const ip = getLocalIP();
    console.log('Serveur Glotelho lance sur http://localhost:' + PORT);
    console.log('Accessible sur le reseau : http://' + ip + ':' + PORT);
});