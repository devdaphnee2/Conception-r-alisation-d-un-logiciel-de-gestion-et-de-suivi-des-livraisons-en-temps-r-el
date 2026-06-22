const prisma = require('./prismaClient');

async function check() {
    const user = await prisma.users.findUnique({
        where: { email: 'manager@glotelho.com' },
        include: { managers: true },
    });

    console.log(user);
}

check().finally(() => prisma.$disconnect());