// routes/notificationRoutes.js
const express = require('express');
const router = express.Router();
const Notification = require('../models/notification');
const auth = require('../middleware/authMiddleware');

// POST nouvelle notification système
router.post('/', auth, async (req, res) => {
  const { title, message, type } = req.body;

  const notif = await Notification.create({
    title,
    message,
    type,
    userId: req.user.userId,
    seen: false,
    createdAt: new Date(),
  });

  res.status(201).json(notif);
});

// GET mes notifications
router.get('/', auth, async (req, res) => {
  const notifs = await Notification.find({ userId: req.user.userId });
  res.json(notifs);
});

module.exports = router;
