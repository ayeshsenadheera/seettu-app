// Initializes the Firebase Admin SDK using server/serviceAccountKey.json
// (download it from Firebase Console > Project settings > Service accounts > Generate new private key)
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const keyPath = path.join(__dirname, '..', '..', 'serviceAccountKey.json');

if (!admin.apps.length) {
  const options = { projectId: process.env.FIREBASE_PROJECT_ID || undefined };
  options.credential = fs.existsSync(keyPath)
    ? admin.credential.cert(require(keyPath))
    : admin.credential.applicationDefault();
  admin.initializeApp(options);
}

module.exports = admin;
