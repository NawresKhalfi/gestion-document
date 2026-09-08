// server.js
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();

const authRoutes = require('./routes/authRoutes');
const documentRoutes = require('./routes/documentRoutes');
const iotRoutes = require('./routes/iotRoutes');
const adminRoutes = require('./routes/adminRoutes');

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

app.use('/api/auth', authRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/iot', iotRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/logs', require('./routes/logRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));

mongoose.connect(process.env.MONGO_URI, () => console.log('MongoDB connected'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log('Server running on port , ${PORT}'));