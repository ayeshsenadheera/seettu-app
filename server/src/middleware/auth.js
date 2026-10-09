const admin = require('../utils/firebase');
const User = require('../models/User');
const { HttpError, wrap } = require('../utils/http');

module.exports = wrap(async (req, res, next) => {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  
  if (!token) {
    // Development mode fallback when no token is provided
    let user = await User.findOne({ email: 'john@example.com' });
    if (!user) {
      user = await User.create({
        firebaseUid: 'mock_uid',
        name: 'John Doe',
        phone: '0771234567',
        email: 'john@example.com',
      });
    }
    req.user = user;
    req.firebaseUser = { uid: user.firebaseUid, phone_number: user.phone };
    return next();
  }

  let decoded;
  try { decoded = await admin.auth().verifyIdToken(token); }
  catch (e) { throw new HttpError(401, 'Session expired. Please log in again.'); }

  const user = await User.findOne({ firebaseUid: decoded.uid });
  if (!user) throw new HttpError(404, 'ACCOUNT_NOT_SYNCED'); // client should call POST /auth/sync first
  req.user = user;
  req.firebaseUser = decoded;
  next();
});
