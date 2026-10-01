const router = require('express').Router();
const Group = require('../models/Group');
const Payment = require('../models/Payment');
const auth = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/http');
const { normalizePhone } = require('../utils/phone');
const { monthKey, nextDue, payoutDate, startOfDay } = require('../utils/cycles');

router.use(auth);

const serMember = (m) => ({ id: String(m._id), name: m.name, phone: m.phone, email: m.email, status: m.status, position: m.position });
const serGroup = (g, payments = []) => {
  const key = monthKey(new Date());
  return {
    id: String(g._id), name: g.name, contribution: g.contribution, frequency: g.frequency, memberLimit: g.memberLimit,
    startDate: g.startDate, description: g.description, memberCount: g.members.length,
    paidThisMonth: payments.filter((p) => p.month === key).length, nextCollection: nextDue(g),
  };
};
async function getGroup(req) {
  const g = await Group.findOne({ _id: req.params.id, owner: req.user._id });
  if (!g) throw new HttpError(404, 'Group not found.');
  return g;
}
function readGroup(b, current) {
  const name = String(b.name || '').trim();
  const contribution = Number(b.contribution);
  const memberLimit = parseInt(b.memberLimit, 10);
  const start = new Date(b.startDate);
  if (name.length < 2) throw new HttpError(400, 'Enter a group name.');
  if (!(contribution > 0)) throw new HttpError(400, 'Contribution amount must be more than 0.');
  if (!['Weekly', 'Monthly'].includes(b.frequency)) throw new HttpError(400, 'Choose Weekly or Monthly.');
  if (!(memberLimit >= 2 && memberLimit <= 100)) throw new HttpError(400, 'Number of members must be between 2 and 100.');
  if (isNaN(start)) throw new HttpError(400, 'Enter a valid start date (YYYY-MM-DD).');
  if (current && memberLimit < current.members.length) throw new HttpError(400, `This group already has ${current.members.length} members.`);
  return { name, contribution, frequency: b.frequency, memberLimit, startDate: start, description: String(b.description || '').trim() };
}

router.get('/', wrap(async (req, res) => {
  const groups = await Group.find({ owner: req.user._id }).sort({ createdAt: 1 });
  const payments = await Payment.find({ group: { $in: groups.map((g) => g._id) } });
  res.json({ groups: groups.map((g) => serGroup(g, payments.filter((p) => String(p.group) === String(g._id)))) });
}));

router.post('/', wrap(async (req, res) => {
  const data = readGroup(req.body);
  const g = await Group.create({
    ...data, owner: req.user._id,
    members: [{ name: req.user.name, phone: req.user.phone, email: req.user.email, position: 1, joinedAt: data.startDate }],
  });
  res.status(201).json({ group: serGroup(g) });
}));

router.get('/:id', wrap(async (req, res) => {
  const g = await getGroup(req);
  res.json({ group: serGroup(g, await Payment.find({ group: g._id })) });
}));

router.put('/:id', wrap(async (req, res) => {
  const g = await getGroup(req);
  Object.assign(g, readGroup(req.body, g));
  await g.save();
  res.json({ group: serGroup(g, await Payment.find({ group: g._id })) });
}));

router.delete('/:id', wrap(async (req, res) => {
  const g = await getGroup(req);
  await Payment.deleteMany({ group: g._id });
  await g.deleteOne();
  res.json({ ok: true });
}));

/* ---------- members ---------- */
const sortedMembers = (g) => [...g.members].sort((a, b) => a.position - b.position);

router.get('/:id/members', wrap(async (req, res) => {
  const g = await getGroup(req);
  const list = sortedMembers(g);
  const today = startOfDay(new Date());
  const next = list.find((m) => payoutDate(g, m.position) >= today);
  res.json({ group: serGroup(g), members: list.map((m) => ({ ...serMember(m), nextPayout: !!next && String(next._id) === String(m._id) })) });
}));

router.get('/:id/members/:mid', wrap(async (req, res) => {
  const g = await getGroup(req);
  const m = g.members.id(req.params.mid);
  if (!m) throw new HttpError(404, 'Member not found.');
  res.json({ member: { ...serMember(m), payoutDate: payoutDate(g, m.position) } });
}));

function readMember(b, g, selfId) {
  const name = String(b.name || '').trim();
  const phone = normalizePhone(b.phone);
  const email = String(b.email || '').trim();
  if (name.length < 2) throw new HttpError(400, "Enter the member's full name.");
  if (!phone) throw new HttpError(400, 'Enter a valid phone number, like 0771234567.');
  if (email && !/^\S+@\S+\.\S+$/.test(email)) throw new HttpError(400, 'Enter a valid email address.');
  if (g.members.some((m) => m.phone === phone && String(m._id) !== String(selfId))) throw new HttpError(409, 'A member with this phone number is already in the group.');
  return { name, phone, email };
}

router.post('/:id/members', wrap(async (req, res) => {
  const g = await getGroup(req);
  if (g.members.length >= g.memberLimit) throw new HttpError(400, `This group is full (${g.memberLimit} members).`);
  g.members.push({ ...readMember(req.body, g), position: g.members.length + 1 });
  await g.save();
  res.status(201).json({ member: serMember(g.members[g.members.length - 1]) });
}));

router.put('/:id/members/:mid', wrap(async (req, res) => {
  const g = await getGroup(req);
  const m = g.members.id(req.params.mid);
  if (!m) throw new HttpError(404, 'Member not found.');
  Object.assign(m, readMember(req.body, g, m._id));
  if (['Active', 'Inactive'].includes(req.body.status)) m.status = req.body.status;
  await g.save();
  res.json({ member: serMember(m) });
}));

router.delete('/:id/members/:mid', wrap(async (req, res) => {
  const g = await getGroup(req);
  const m = g.members.id(req.params.mid);
  if (!m) throw new HttpError(404, 'Member not found.');
  if (m.phone === req.user.phone) throw new HttpError(400, "You can't remove yourself from your own group.");
  m.deleteOne();
  sortedMembers(g).forEach((x, i) => { x.position = i + 1; });
  await g.save();
  res.json({ ok: true });
}));

/* ---------- payouts ---------- */
router.get('/:id/payouts', wrap(async (req, res) => {
  const g = await getGroup(req);
  const today = startOfDay(new Date());
  const list = sortedMembers(g);
  const pot = g.contribution * list.length;
  let currentSet = false;
  const payouts = list.map((m) => {
    const date = payoutDate(g, m.position);
    let status = 'Upcoming';
    if (date < today) status = 'Paid';
    else if (!currentSet) { status = 'Current'; currentSet = true; }
    return { memberId: String(m._id), name: m.name, position: m.position, date, amount: pot, status };
  });
  res.json({ group: serGroup(g), potAmount: pot, payouts });
}));

module.exports = router;
