const router = require('express').Router();
const Group = require('../models/Group');
const Payment = require('../models/Payment');
const Notification = require('../models/Notification');
const auth = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/http');
const { monthKey, dueDate, statusFor, outstandingFor, nextDue, myMember } = require('../utils/cycles');

router.use(auth);

async function ownGroup(user, groupId) {
  if (!groupId) throw new HttpError(400, 'Choose a group.');
  const g = await Group.findOne({ _id: groupId, owner: user._id });
  if (!g) throw new HttpError(404, 'Group not found.');
  return g;
}
const ser = (p) => ({ id: String(p._id), memberId: String(p.memberId), memberName: p.memberName, amount: p.amount, month: p.month, date: p.date, method: p.method, reference: p.reference, status: 'Paid' });

router.post('/', wrap(async (req, res) => {
  const { groupId, memberId, amount, month, date, method, reference } = req.body;
  const g = await ownGroup(req.user, groupId);
  const m = g.members.id(memberId);
  if (!m) throw new HttpError(404, 'Choose a member.');
  const amt = Number(amount === undefined || amount === '' ? g.contribution : amount);
  if (!(amt > 0)) throw new HttpError(400, 'Amount must be more than 0.');
  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month || '')) throw new HttpError(400, 'Enter the payment month as YYYY-MM.');
  const d = new Date(date || Date.now());
  if (isNaN(d)) throw new HttpError(400, 'Enter a valid payment date (YYYY-MM-DD).');
  try {
    const p = await Payment.create({
      owner: req.user._id, group: g._id, memberId: m._id, memberName: m.name, amount: amt, month, date: d,
      method: ['Cash', 'Bank Transfer', 'Other'].includes(method) ? method : 'Cash', reference: String(reference || '').trim(),
    });
    res.status(201).json({ payment: ser(p) });
  } catch (e) {
    if (e.code === 11000) throw new HttpError(409, `${m.name} already has a payment recorded for ${month}.`);
    throw e;
  }
}));

router.get('/history', wrap(async (req, res) => {
  const g = await ownGroup(req.user, req.query.groupId);
  const list = await Payment.find({ group: g._id }).sort({ date: -1, createdAt: -1 });
  res.json({ totalPaid: list.reduce((s, p) => s + p.amount, 0), count: list.length, payments: list.map(ser) });
}));

router.get('/shared', wrap(async (req, res) => {
  const g = await ownGroup(req.user, req.query.groupId);
  const month = /^\d{4}-\d{2}$/.test(req.query.month || '') ? req.query.month : monthKey(new Date());
  const payments = await Payment.find({ group: g._id });
  const rows = g.members.map((m) => ({
    memberId: String(m._id), name: m.name, amount: g.contribution,
    status: statusFor(g, payments, m, month), paidAmount: (payments.find((p) => String(p.memberId) === String(m._id) && p.month === month) || {}).amount || 0,
  }));
  const count = (s) => rows.filter((r) => r.status === s).length;
  res.json({ month, rows, summary: { paid: count('Paid'), pending: count('Pending'), late: count('Late'), missed: count('Missed') } });
}));

router.get('/outstanding', wrap(async (req, res) => {
  const groups = req.query.groupId ? [await ownGroup(req.user, req.query.groupId)] : await Group.find({ owner: req.user._id });
  const payments = await Payment.find({ group: { $in: groups.map((g) => g._id) } });
  const items = groups.flatMap((g) => outstandingFor(g, payments.filter((p) => String(p.group) === String(g._id))))
    .sort((a, b) => b.daysOverdue - a.daysOverdue);
  res.json({ items, late: items.filter((i) => i.status === 'Late').length, missed: items.filter((i) => i.status === 'Missed').length });
}));

router.post('/notify', wrap(async (req, res) => {
  const { groupId, memberId, month } = req.body;
  const g = await ownGroup(req.user, groupId);
  const payments = await Payment.find({ group: g._id });
  let items = outstandingFor(g, payments);
  if (memberId) items = items.filter((i) => i.memberId === String(memberId));
  if (month) items = items.filter((i) => i.month === month);
  if (!items.length) throw new HttpError(400, 'There is nobody to notify.');
  await Notification.insertMany(items.map((i) => ({
    owner: req.user._id, group: g._id, memberId: i.memberId, memberName: i.memberName,
    message: `Reminder: your ${g.name} contribution of Rs. ${i.amount} for ${i.month} is ${i.status.toLowerCase()}.`,
  })));
  res.json({ sent: items.length });
}));

// Payment dashboard summary for the logged-in user in one group
router.get('/summary', wrap(async (req, res) => {
  const g = await ownGroup(req.user, req.query.groupId);
  const payments = await Payment.find({ group: g._id });
  const me = myMember(g, req.user);
  const key = monthKey(new Date());
  res.json({
    monthlyAmount: g.contribution, nextDue: nextDue(g), month: key, dueDate: dueDate(g, key),
    myStatus: me ? statusFor(g, payments, me, key) : 'N/A', myMemberId: me ? String(me._id) : null,
  });
}));

module.exports = router;
