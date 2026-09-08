// routes/iotRoutes.js
const express = require('express');
const Log = require('../models/AccessLog');
const router = express.Router();

router.post('/signal', async (req, res) => {
  const { userId, action } = req.body;
  await Log.create({ userId, action });
  res.send('Signal reçu');
});

module.exports = router;

