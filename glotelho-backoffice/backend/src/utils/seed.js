const bcrypt = require('bcrypt');
const prisma = require('./prismaClient');

async function seed() {
    const hashedPassword = await bcrypt.hash('password123', 10);

    const user = await prisma.users.create({
        data: {
            last_name: 'Moussinga',
            first_name: 'Kily',
            email: 'manager@glotelho.com',
            password: hashedPassword,
            phone: '698713895',
            role: 'manager',
        },
    });

    const manager = await prisma.managers.create({
        data: {
            user_id: user.id,
        },
    });

    console.log('✅ Manager créé avec succès :');
    console.log({ user, manager });
}

seed()
    .catch((e) => {
        console.error('❌ Erreur lors du seed :', e);
    })
    .finally(async() => {
        await prisma.$disconnect();
    });