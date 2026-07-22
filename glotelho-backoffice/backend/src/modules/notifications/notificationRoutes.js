const express = require('express');
const router = express.Router();
const prisma = require('../../utils/prismaClient');

router.get('/', async(req, res) => {
    const notifs = await prisma.notifications.findMany({
        where: { recipient_id: req.user.id },
        orderBy: { sent_at: 'desc' },
        take: 50
    });
    res.json(notifs);
});

router.delete('/:id', async(req, res) => {
    await prisma.notifications.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: 'Supprimée.' });
});

router.patch('/:id/lire', async(req, res) => {
    await prisma.notifications.update({
        where: { id: parseInt(req.params.id) },
        data: { is_read: true }
    });
    res.json({ message: 'Marquée lue.' });
});
module.exports = router;