const prisma = require('./prismaClient');

async function updateManager() {
    const user = await prisma.users.update({
        where: { email: 'manager@glotelho.com' },
        data: {
            last_name: 'Moussinga',
            first_name: 'Amandine',
            phone: '698713895',
        },
    });

    console.log('✅ Compte mis à jour avec succès :');
    console.log(user);
}

updateManager()
    .catch((e) => {
        console.error('❌ Erreur :', e);
    })
    .finally(() => prisma.$disconnect());