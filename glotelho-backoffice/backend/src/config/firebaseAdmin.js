const { initializeApp, cert } = require('firebase-admin/app');
const { getDatabase } = require('firebase-admin/database');
const fs = require('fs');
const path = require('path');

let db = null;

function getFirebaseDB() {
    if (db) return db;
    try {
        const filePath = path.join(__dirname, 'firebase-admin.json');
        const serviceAccount = JSON.parse(fs.readFileSync(filePath, 'utf8'));

        initializeApp({
            credential: cert(serviceAccount),
            databaseURL: 'https://glotelho-livraison-default-rtdb.europe-west1.firebasedatabase.app'
        });

        db = getDatabase();
        console.log('[Firebase Admin] Connexion Realtime Database OK');
        return db;
    } catch (err) {
        console.warn('[Firebase Admin] Non configure :', err.message);
        return null;
    }
}

module.exports = { getFirebaseDB };