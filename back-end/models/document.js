// models/Document.js
const mongoose = require('mongoose');

const DocumentSchema = new mongoose.Schema({
  userId: mongoose.Types.ObjectId,
  filename: String,
  originalname: String,
  uploadedAt: { type: Date, default: Date.now }
});
module.exports = mongoose.model('Document', DocumentSchema);

