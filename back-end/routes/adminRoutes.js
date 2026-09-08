// routes/adminRoutes.js
const express = require('express');
const User = require('../models/user');
const Document = require('../models/document');
const Log = require('../models/AccessLog');
const auth = require('../middleware/authMiddleware');
const admin = require('../middleware/adminMiddleware');
const router = express.Router();
// GET all users
router.get('/users', auth, admin, async (req, res) => {
  const users = await User.find();
  res.json(users);
});

// GET all logs
router.get('/logs', auth, admin, async (req, res) => {
  const logs = await Log.find().populate('userId', 'email');
  res.json(logs);
});

// GET all documents
router.get('/documents', auth, admin, async (req, res) => {
  const docs = await Document.find().populate('userId', 'email');
  res.json(docs);
});

module.exports = router;