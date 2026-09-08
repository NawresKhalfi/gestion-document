// createAdmin.js

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config(); // charge MONGO_URI

// modèle User
const User = require('./models/user');

// Connexion à MongoDB
mongoose.connect(process.env.MONGO_URI, async () => {
  console.log('✅ Connexion MongoDB établie');

  const email = 'admin@tse.com';

  // Vérifie si l’admin existe déjà
  const existingAdmin = await User.findOne({ email });
  if (existingAdmin) {
    console.log('⚠️ Admin existe déjà');
    mongoose.disconnect();
    return;
  }

  const hashedPassword = await bcrypt.hash('admin123', 10);

  const admin = await User.create({
    name: 'Admin TSE',
    email: email,
    password: hashedPassword,
    role: 'admin'
  });

  console.log('✅ Compte admin créé :', admin);
  mongoose.disconnect();
});
