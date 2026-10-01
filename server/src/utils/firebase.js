// Initializes the Firebase Admin SDK using server/serviceAccountKey.json
// (download it from Firebase Console > Project settings > Service accounts > Generate new private key)
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const keyPath = path.join(__dirname, '..', '..', 'serviceAccountKey.json');

if (!admin.apps.length) {
  if (!fs.existsSync(keyPath)) {
    console.error('\nMissing server/serviceAccountKey.json.');
    console.error('Firebase Console > Project settings > Service accounts > Generate new private key,');
    console.error('then save the downloaded file as server/serviceAccountKey.json\n');
    process.exit(1);
  }
  admin.initializeApp({ credential: admin.credential.cert(require(keyPath)) });
}

module.exports = admin;
