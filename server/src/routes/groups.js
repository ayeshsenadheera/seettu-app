const router = require('express').Router();
const Group = require('../models/Group');
const Payment = require('../models/Payment');
const Notification = require('../models/Notification');
const User = require('../models/User');
const Trusted = require('../models/Trusted');
const auth = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/http');
const { normalizePhone } = require('../utils/phone');
const { monthKey, nextDue, payoutDate, startOfDay } = require('../utils/cycles');
const { isOwner, roleOf, canManage, accessibleGroups, linkToExistingUser, loadGroup } = require('../utils/access');

router.use(auth);

// Phone / e-mail are shown only to the organizer and to the member themselves.
// role: Organizer | Member.  hasAccount: false = not signed up yet (so they cannot see the group).
const serMember = (m, { showContact = true, ownerUid = null } = {}) => ({
  id: String(m._id), name: m.name, phone: showContact ? m.phone : '', email: showContact ? m.email : '',
  status: m.status, position: m.position, joined: m.joinedAt ? m.joinedAt.toISOString().split('T')[0] : 'N/A',
  role: ownerUid && m.firebaseUid === ownerUid ? 'Organizer' : 'Member',
  hasAccount: !!m.firebaseUid,
});
const serGroup = (g, payments = [], user = null, organizerName = null) => {
  const key = monthKey(new Date());
  const role = user ? roleOf(g, user) : null;
  return {
    id: String(g._id), name: g.name, contribution: g.contribution, frequency: g.frequency, memberLimit: g.memberLimit,
    startDate: g.startDate, description: g.description, memberCount: g.members.length,
    paidThisMonth: payments.filter((p) => p.month === key).length, nextCollection: nextDue(g),
    role, canManage: role === 'Organizer', organizerName,
  };
};
// Any group I can open (organizer or member). manage=true -> organizer only.
const getGroup = (req, manage = false) => loadGroup(req.user, req.params.id, { manage });
const ownerOf = async (g) => User.findById(g.owner);
const nameOf = async (g) => ((await ownerOf(g)) || {}).name || null;
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
  const groups = await accessibleGroups(req.user);
  const payments = await Payment.find({ group: { $in: groups.map((g) => g._id) } });
  const owners = await User.find({ _id: { $in: groups.map((g) => g.owner) } });
  const nameById = Object.fromEntries(owners.map((u) => [String(u._id), u.name]));
  res.json({ groups: groups.map((g) => serGroup(g, payments.filter((p) => String(p.group) === String(g._id)), req.user, nameById[String(g.owner)] || null)) });
}));

// "What am I in this app?"  organizer of / member of / trusted person for
router.get('/roles/summary', wrap(async (req, res) => {
  const groups = await accessibleGroups(req.user);
  const trusted = await Trusted.find({ guest: req.user._id, status: 'Active' });
  const owners = await User.find({ _id: { $in: trusted.map((t) => t.owner) } });
  const nameById = Object.fromEntries(owners.map((u) => [String(u._id), u.name]));
  const pick = (r) => groups.filter((g) => roleOf(g, req.user) === r).map((g) => ({ id: String(g._id), name: g.name }));
  res.json({
    organizerOf: pick('Organizer'), memberOf: pick('Member'),
    trustedFor: trusted.filter((t) => !t.expiresAt || t.expiresAt > new Date()).map((t) => ({ id: String(t._id), ownerName: nameById[String(t.owner)] || null })),
  });
}));

router.post('/', wrap(async (req, res) => {
  const data = readGroup(req.body);
  const g = await Group.create({
    ...data, owner: req.user._id,
    members: [{ firebaseUid: req.user.firebaseUid, name: req.user.name, phone: req.user.phone, email: req.user.email, position: 1, joinedAt: data.startDate }],
  });
  res.status(201).json({ group: serGroup(g, [], req.user, req.user.name) });
}));

router.get('/:id', wrap(async (req, res) => {
  const g = await getGroup(req);
  res.json({ group: serGroup(g, await Payment.find({ group: g._id }), req.user, await nameOf(g)) });
}));

router.put('/:id', wrap(async (req, res) => {
  const g = await getGroup(req, true);
  Object.assign(g, readGroup(req.body, g));
  await g.save();
  res.json({ group: serGroup(g, await Payment.find({ group: g._id }), req.user, req.user.name) });
}));

router.delete('/:id', wrap(async (req, res) => {
  const g = await getGroup(req, true);
  await Payment.deleteMany({ group: g._id });
  await Notification.deleteMany({ group: g._id });
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
  const owner = await ownerOf(g);
  const manage = canManage(g, req.user);
  res.json({
    group: serGroup(g, [], req.user, owner && owner.name),
    members: list.map((m) => ({
      ...serMember(m, { showContact: manage || m.firebaseUid === req.user.firebaseUid, ownerUid: owner && owner.firebaseUid }),
      nextPayout: !!next && String(next._id) === String(m._id),
    })),
  });
}));

router.get('/:id/members/:mid', wrap(async (req, res) => {
  const g = await getGroup(req);
  const m = g.members.id(req.params.mid);
  if (!m) throw new HttpError(404, 'Member not found.');
  const owner = await ownerOf(g);
  const showContact = canManage(g, req.user) || m.firebaseUid === req.user.firebaseUid;
  res.json({ member: { ...serMember(m, { showContact, ownerUid: owner && owner.firebaseUid }), payoutDate: payoutDate(g, m.position) } });
}));

function readMember(b, g, selfId) {
  const name = String(b.name || '').trim();
  const phone = normalizePhone(b.phone);
  const email = String(b.email || '').trim();
  if (name.length < 2) throw new HttpError(400, "Enter the member's full name.");
  if (!phone) throw new HttpError(400, 'Enter a valid phone number, like 0771234567.');
  if (email && !/^\S+@\S+\.\S+$/.test(email)) throw new HttpError(400, 'Enter a valid email address.');
  if (g.members.some((m) => m.phone === phone && String(m._id) !== String(selfId))) throw new HttpError(409, 'A member with this phone number is already in the group.');
  if (email && g.members.some((m) => m.email && m.email.toLowerCase() === email.toLowerCase() && String(m._id) !== String(selfId))) throw new HttpError(409, 'A member with this email is already in the group.');
  const position = b.position ? parseInt(b.position, 10) : undefined;
  const joinedAt = b.joinedAt ? new Date(b.joinedAt) : undefined;
  return { name, phone, email, ...(position && { position }), ...(joinedAt && !isNaN(joinedAt) && { joinedAt }) };
}

router.post('/:id/members', wrap(async (req, res) => {
  const g = await getGroup(req, true);
  if (g.members.length >= g.memberLimit) throw new HttpError(400, `This group is full (${g.memberLimit} members).`);
  g.members.push({ position: g.members.length + 1, ...readMember(req.body, g) });
  const added = g.members[g.members.length - 1];
  // If this person already has an account (same phone or e-mail) they see the group right away;
  // otherwise it is linked automatically the first time they sign up / log in.
  await linkToExistingUser(added);
  await g.save();
  res.status(201).json({ member: serMember(added), linked: !!added.firebaseUid });
}));

router.put('/:id/members/:mid', wrap(async (req, res) => {
  const g = await getGroup(req, true);
  const m = g.members.id(req.params.mid);
  if (!m) throw new HttpError(404, 'Member not found.');
  const before = { phone: m.phone, email: m.email };
  Object.assign(m, readMember(req.body, g, m._id));
  if (['Active', 'Inactive'].includes(req.body.status)) m.status = req.body.status;
  // Contact details changed -> re-check which account (if any) this person is
  if ((before.phone !== m.phone || before.email !== m.email) && m.firebaseUid !== req.user.firebaseUid) await linkToExistingUser(m);
  await g.save();
  res.json({ member: serMember(m) });
}));

router.delete('/:id/members/:mid', wrap(async (req, res) => {
  const g = await getGroup(req, true);
  const m = g.members.id(req.params.mid);
  if (!m) throw new HttpError(404, 'Member not found.');
  if (m.firebaseUid === req.user.firebaseUid || m.phone === req.user.phone) throw new HttpError(400, "You can't remove yourself from your own group.");
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
  res.json({ group: serGroup(g, [], req.user), potAmount: pot, payouts });
}));

module.exports = router;
