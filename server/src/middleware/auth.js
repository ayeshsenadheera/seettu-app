const admin = require('../utils/firebase');
const User = require('../models/User');
const { HttpError, wrap } = require('../utils/http');

function createAuth({ verifyToken = (token) => admin.auth().verifyIdToken(token, !process.env.FIREBASE_AUTH_EMULATOR_HOST) } = {}) {
return wrap(async (req, res, next) => {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) throw new HttpError(401, 'Please log in.');

  let decoded;
  try { decoded = await verifyToken(token); }
  catch (e) { throw new HttpError(401, 'Session expired. Please log in again.'); }

  const user = await User.findOne({ firebaseUid: decoded.uid });
  if (!user) throw new HttpError(404, 'ACCOUNT_NOT_SYNCED'); // client should call POST /auth/sync first
  req.user = user;
  req.firebaseUser = decoded;
  next();
});
}

module.exports = createAuth();
module.exports.createAuth = createAuth;
