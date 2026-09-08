// routes/logRoutes.js
const express = require('express');
const router = express.Router();
const Log = require('../models/AccessLog');
const auth = require('../middleware/authMiddleware');

// POST log d'action
router.post('/', auth, async (req, res) => {
  const { action } = req.body;

  const log = await Log.create({
    userId: req.user.userId,
    action,
    timestamp: new Date(),
  });

  res.status(201).json(log);
});

// GET mes logs
router.get('/', auth, async (req, res) => {
  const logs = await Log.find({ userId: req.user.userId }).sort({ timestamp: -1 });
  res.json(logs);
});

module.exports = router;
