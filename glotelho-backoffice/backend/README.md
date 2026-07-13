# Backend Glotelho — Unifie v2.0

## Structure
```
src/
├── modules/
│   ├── auth/          — Authentification tous acteurs
│   ├── livreur/       — App mobile livreur (Flutter)
│   ├── livraison/     — Gestion livraisons
│   ├── commercant/    — App mobile commercant (Flutter)
│   └── administration/— Back-office web (React)
├── middlewares/       — Auth, roles, upload
├── config/            — Firebase Admin
└── utils/             — Prisma, mailer
```

## Endpoints principaux

### Auth
- POST /api/auth/login           — Manager (web)
- POST /api/auth/login-mobile    — Livreur/Commercant (mobile)
- POST /api/auth/register        — Nouveau manager

### Livreur (Flutter app)
- POST /api/v1/drivers/register  — Inscription livreur
- POST /api/v1/drivers/login     — Connexion livreur
- GET  /api/v1/drivers/me        — Profil livreur
- PUT  /api/v1/drivers/me        — Modifier profil
- GET  /api/v1/drivers/courses   — Mes courses
- POST /api/v1/drivers/courses/:id/accepter
- POST /api/v1/drivers/courses/:id/demarrer
- POST /api/v1/drivers/courses/:id/position
- POST /api/v1/drivers/courses/:id/cloturer
- POST /api/v1/drivers/courses/:id/incident

### Commercant (Flutter app)
- GET  /api/v1/commercant/livraisons        — Mes livraisons
- POST /api/v1/commercant/livraisons        — Creer livraison
- GET  /api/v1/commercant/livreurs-disponibles
- POST /api/v1/commercant/livraisons/:id/litige

### Livraisons (back-office web)
- GET  /api/livraisons           — Liste
- POST /api/livraisons           — Creer (admin)
- GET  /api/livraisons/:id       — Detail
- POST /api/livraisons/:id/assigner
- POST /api/livraisons/:id/annuler
- GET  /api/livraisons/public/:id — Tracking client (sans auth)

### Administration (back-office web)
- GET/PUT /api/livreurs          — Gestion livreurs
- GET/PUT /api/litiges           — Litiges
- GET/PUT /api/recouvrements     — Recouvrements
- GET/PUT /api/profils           — Validation profils livreurs
- GET     /api/bordereaux        — Bordereaux PDF

## Demarrage
```bash
cp .env.example .env
# Editer .env avec vos valeurs
npm install
npx prisma generate
npm run dev
```
