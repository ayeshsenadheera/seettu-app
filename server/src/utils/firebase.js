// Initializes the Firebase Admin SDK.
// Order: FIREBASE_SERVICE_ACCOUNT env var (used on Render) -> server/serviceAccountKey.json (local) -> default credentials.
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const keyPath = path.join(__dirname, '..', '..', 'serviceAccountKey.json');

function loadCredential() {
  if (process.env.FIREBASE_SERVICE_ACCOUNT) {
    return admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT));
  }
  if (fs.existsSync(keyPath)) {
    return admin.credential.cert(require(keyPath));
  }
  return admin.credential.applicationDefault();
}

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID || undefined,
    credential: loadCredential(),
  });
}

module.exports = admin;