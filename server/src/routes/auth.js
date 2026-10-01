const router = require('express').Router();
const admin = require('../utils/firebase');
const User = require('../models/User');
const auth = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/http');
const { normalizePhone } = require('../utils/phone');

const pub = (u) => ({ id: String(u._id), name: u.name, email: u.email, phone: u.phone, role: u.role, settings: u.settings });

async function verify(req) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) throw new HttpError(401, 'Please log in.');
  try { return await admin.auth().verifyIdToken(token); }
  catch (e) { throw new HttpError(401, 'Session expired. Please log in again.'); }
}

// Called right after Firebase sign-up / sign-in. Creates the profile the first time,
// or just returns it on later calls. name+phone are required only when creating.
router.post('/sync', wrap(async (req, res) => {
  const decoded = await verify(req);
  let user = await User.findOne({ firebaseUid: decoded.uid });
  if (user) return res.json({ user: pub(user), created: false });

  const { name, phone } = req.body;
  const p = normalizePhone(phone);
  if (!name || name.trim().length < 2) throw new HttpError(400, 'Enter your full name.');
  if (!p) throw new HttpError(400, 'Enter a valid phone number, like 0771234567.');
  if (!decoded.email) throw new HttpError(400, 'Your Firebase account has no email address.');

  user = await User.create({ firebaseUid: decoded.uid, name: name.trim(), email: decoded.email, phone: p });
  res.status(201).json({ user: pub(user), created: true });
}));

router.get('/me', auth, wrap(async (req, res) => res.json({ user: pub(req.user) })));

router.put('/me', auth, wrap(async (req, res) => {
  const { name, phone } = req.body;
  const p = normalizePhone(phone);
  if (!name || name.trim().length < 2) throw new HttpError(400, 'Enter your full name.');
  if (!p) throw new HttpError(400, 'Enter a valid phone number, like 0771234567.');
  req.user.name = name.trim();
  req.user.phone = p;
  await req.user.save();
  res.json({ user: pub(req.user) });
}));

module.exports = router;
