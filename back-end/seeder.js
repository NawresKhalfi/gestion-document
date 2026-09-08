require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// === Import des modèles ===
const User = require('./models/user');
const Document = require('./models/document');
const Log = require('./models/AccessLog');
const Notification = require('./models/notification');

// === Connexion à MongoDB Atlas ===
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
})
.then(() => console.log('✅ Connecté à MongoDB Atlas'))
.catch(err => console.error('❌ Erreur MongoDB:', err));

// === Fonction principale ===
async function seedData() {
  try {
    await User.deleteMany();
    await Document.deleteMany();
    await Log.deleteMany();
    await Notification.deleteMany();

    // === Création des utilisateurs ===
    const adminPassword = await bcrypt.hash('admin123', 10);
    const userPassword = await bcrypt.hash('user123', 10);

    const admin = await User.create({
      name: 'Admin',
      email: 'admin@gmail.com',
      password: 'admin123',
      role: 'admin'
    });

    const user = await User.create({
      name: 'nawres',
      email: 'nawreskhalfi77@gmail.com',
      password: 'naw123',
      role: 'user'
    });

    console.log('✅ Utilisateurs insérés');

    // === Documents ===
    const doc1 = await Document.create({
      title: 'Document 1',
      content: 'Contenu du document 1.',
      createdBy: user._id
    });

    const doc2 = await Document.create({
      title: 'Document 2',
      content: 'Contenu du document 2.',
      createdBy: admin._id
    });

    console.log('✅ Documents insérés');

    // === Logs ===
    await Log.create([
      { userId: user._id, action: 'consultation', description: 'Consultation de doc 1' },
      { userId: admin._id, action: 'ajout', description: 'Ajout d’un nouveau document' }
    ]);

    console.log('✅ Logs insérés');

    // === Notifications ===
    await Notification.create([
      { title: 'Bienvenue', message: 'Bienvenue sur la plateforme', type: 'info' },
      { title: 'Document ajouté', message: 'Un nouveau document a été ajouté', type: 'document' }
    ]);

    console.log('✅ Notifications insérées');

    process.exit();

  } catch (error) {
    console.error('❌ Erreur pendant l’insertion :', error);
    process.exit(1);
  }
}

seedData();
