import { initializeApp } from 'firebase/app';
import { getDatabase, ref, onValue, off } from 'firebase/database';

const firebaseConfig = {
    apiKey: "AIzaSyCULSB6KxGRaq7St10xzo-1aRz-ceGXKIE",
     authDomain: "glotelho-livraison.firebaseapp.com",
     databaseURL: "https://glotelho-livraison-default-rtdb.europe-west1.firebasedatabase.app",
     projectId: "glotelho-livraison",
     storageBucket: "glotelho-livraison.firebasestorage.app",
     messagingSenderId: "470677606340",
     appId: "1:470677606340:web:328c4303976fc9590a9e91",
     measurementId: "G-3ME0DP8GF6",
    authDomain: "glotelho-livraison.firebaseapp.com",
    databaseURL: "https://glotelho-livraison-default-rtdb.firebaseio.com",
    projectId: "glotelho-livraison",
    storageBucket: "glotelho-livraison.appspot.com",
    messagingSenderId: "VOTRE_ID",
    appId: "VOTRE_APP_ID"
};

const app = initializeApp(firebaseConfig);
const database = getDatabase(app);

export { database, ref, onValue, off };