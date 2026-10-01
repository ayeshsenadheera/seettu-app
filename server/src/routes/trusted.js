const router = require('express').Router();
const crypto = require('crypto');
const Trusted = require('../models/Trusted');
const User = require('../models/User');
const Group = require('../models/Group');
const Payment = require('../models/Payment');
const auth = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/http');
const { normalizePhone } = require('../utils/phone');
const { monthKey, statusFor, payoutDate, myMember } = require('../utils/cycles');

router.use(auth);
const active = (t) => !t.expiresAt || t.expiresAt > new Date();
const ser = (t) => ({ id: String(t._id), name: t.name, phone: t.phone, relationship: t.relationship, share: t.share, status: t.status, inviteCode: t.inviteCode, expiresAt: t.expiresAt });

// People I have given access to (expired ones are removed)
router.get('/', wrap(async (req, res) => {
  await Trusted.deleteMany({ owner: req.user._id, expiresAt: { $ne: null, $lte: new Date() } });
  const list = await Trusted.find({ owner: req.user._id }).sort({ createdAt: -1 });
  res.json({ people: list.map(ser) });
}));

router.post('/', wrap(async (req, res) => {
  const { name, phone, relationship, share, days } = req.body;
  const p = normalizePhone(phone);
  const allowed = ['payoutDate', 'paymentStatus', 'amount'];
  const picked = (Array.isArray(share) ? share : []).filter((s) => allowed.includes(s));
  if (!name || String(name).trim().length < 2) throw new HttpError(400, "Enter the person's full name.");
  if (!p) throw new HttpError(400, 'Enter a valid number, like 0771234567 or +94771234567.');
  if (!picked.length) throw new HttpError(400, 'Choose at least one thing they can see.');
  if (await Trusted.findOne({ owner: req.user._id, phone: p })) throw new HttpError(409, 'This person already has access.');
  const d = Number(days) || 0;
  const t = await Trusted.create({
    owner: req.user._id, name: String(name).trim(), phone: p, share: picked,
    relationship: ['Family', 'Friend', 'Other'].includes(relationship) ? relationship : 'Family',
    inviteCode: String(crypto.randomInt(100000, 1000000)),
    expiresAt: d > 0 ? new Date(Date.now() + d * 86400000) : null,
  });
  res.status(201).json({ person: ser(t) });
}));

router.delete('/:id', wrap(async (req, res) => {
  const t = await Trusted.findOne({ _id: req.params.id, owner: req.user._id });
  if (!t) throw new HttpError(404, 'Person not found.');
  await t.deleteOne();
  res.json({ ok: true });
}));

// The invited person enters the code from their own account
router.post('/accept', wrap(async (req, res) => {
  const t = await Trusted.findOne({ inviteCode: String(req.body.code || '').trim(), status: 'Pending' });
  if (!t || !active(t)) throw new HttpError(404, 'That code is not valid or has expired.');
  if (String(t.owner) === String(req.user._id)) throw new HttpError(400, "You can't accept your own invite.");
  t.guest = req.user._id;
  t.status = 'Active';
  await t.save();
  res.json({ ok: true });
}));

// View-only data that other people have shared with me
router.get('/shared', wrap(async (req, res) => {
  const list = (await Trusted.find({ guest: req.user._id, status: 'Active' })).filter(active);
  const out = [];
  for (const t of list) {
    const owner = await User.findById(t.owner);
    if (!owner) continue;
    const groups = await Group.find({ owner: owner._id }).sort({ createdAt: 1 });
    let g = null, me = null;
    for (const x of groups) { const m = myMember(x, owner); if (m) { g = x; me = m; break; } }
    const data = { groupName: g ? g.name : null };
    if (g && me) {
      const payments = await Payment.find({ group: g._id });
      if (t.share.includes('payoutDate')) data.payoutDate = payoutDate(g, me.position);
      if (t.share.includes('paymentStatus')) data.paymentStatus = statusFor(g, payments, me, monthKey(new Date()));
      if (t.share.includes('amount')) data.amount = g.contribution;
    }
    out.push({ id: String(t._id), ownerName: owner.name, share: t.share, expiresAt: t.expiresAt, data });
  }
  res.json({ shared: out });
}));

module.exports = router;
