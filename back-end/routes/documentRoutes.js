// routes/documentRoutes.js
const express = require('express');
const router = express.Router();
const Document = require('../models/document');
const auth = require('../middleware/authMiddleware');

// POST créer document
router.post('/', auth, async (req, res) => {
  const { title, content } = req.body;

  const doc = await Document.create({
    title,
    content,
    userId: req.user.userId,
  });

  res.status(201).json(doc);
});

// GET mes documents
router.get('/', auth, async (req, res) => {
  const docs = await Document.find({ userId: req.user.userId });
  res.json(docs);
});

module.exports = router;
