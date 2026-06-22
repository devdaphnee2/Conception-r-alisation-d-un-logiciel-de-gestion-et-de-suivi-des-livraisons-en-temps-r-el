const bcrypt = require('bcrypt');
const prisma = require('./prismaClient');

async function resetPassword() {
    const hashedPassword = await bcrypt.hash('password123', 10);

    const user = await prisma.users.update({
        where: { email: 'manager@glotelho.com' },
        data: { password: hashedPassword },
    });

    console.log('✅ Mot de passe réinitialisé pour :', user.email);
    console.log('Nouveau hash :', user.password);
}

resetPassword()
    .catch((e) => console.error('❌ Erreur :', e))
    .finally(() => prisma.$disconnect());