// models/AccessLog.js
const mongoose = require('mongoose');

const AccessLogSchema = new mongoose.Schema({
  userId: mongoose.Types.ObjectId,
  action: String,
  timestamp: { type: Date, default: Date.now }
});
module.exports = mongoose.model('AccessLog', AccessLogSchema);