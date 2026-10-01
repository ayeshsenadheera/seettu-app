const router = require('express').Router();
const Group = require('../models/Group');
const Payment = require('../models/Payment');
const auth = require('../middleware/auth');
const { wrap } = require('../utils/http');
const { monthKey, nextKey, dueDate, statusFor, outstandingFor, myMember } = require('../utils/cycles');

router.get('/', auth, wrap(async (req, res) => {
  const groups = await Group.find({ owner: req.user._id }).sort({ createdAt: 1 });
  const payments = await Payment.find({ group: { $in: groups.map((g) => g._id) } }).sort({ date: -1, createdAt: -1 });
  const by = (g) => payments.filter((p) => String(p.group) === String(g._id));

  const outstanding = groups.flatMap((g) => outstandingFor(g, by(g)));

  // Next payment the logged-in user has to make
  const today = new Date();
  let nextUp = null;
  for (const g of groups) {
    const me = myMember(g, req.user);
    if (!me) continue;
    let key = monthKey(today);
    if (statusFor(g, by(g), me, key) === 'Paid') key = nextKey(key);
    const due = dueDate(g, key);
    if (!nextUp || due < nextUp.dueDate) nextUp = { groupId: String(g._id), groupName: g.name, memberId: String(me._id), amount: g.contribution, month: key, dueDate: due };
  }
  const names = Object.fromEntries(groups.map((g) => [String(g._id), g.name]));
  res.json({
    name: req.user.name,
    totalSavings: payments.reduce((s, p) => s + p.amount, 0),
    activeGroups: groups.length,
    totalMembers: groups.reduce((s, g) => s + g.members.length, 0),
    missedCount: outstanding.length,
    missedGroupName: outstanding[0] ? outstanding[0].groupName : null,
    nextUp,
    recent: payments.slice(0, 5).map((p) => ({ id: String(p._id), memberName: p.memberName, groupName: names[String(p.group)], amount: p.amount, date: p.date, method: p.method })),
  });
}));

module.exports = router;
