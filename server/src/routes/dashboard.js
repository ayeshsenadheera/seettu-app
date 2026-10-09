const router = require('express').Router();
const Group = require('../models/Group');
const Payment = require('../models/Payment');
const auth = require('../middleware/auth');
const { wrap } = require('../utils/http');
const { monthKey, nextKey, dueDate, statusFor, outstandingFor, myMember } = require('../utils/cycles');
const { canManage, accessibleGroups } = require('../utils/access');

router.get('/', auth, wrap(async (req, res) => {
  const groups = await accessibleGroups(req.user);
  const allPayments = await Payment.find({ group: { $in: groups.map((g) => g._id) } }).sort({ date: -1, createdAt: -1 });
  // Organizer sees everything in groups they run; a member sees only their own payments
  const visible = (g, list) => {
    if (canManage(g, req.user)) return list;
    const me = myMember(g, req.user);
    return me ? list.filter((p) => String(p.memberId) === String(me._id)) : [];
  };
  const groupOf = (id) => groups.find((g) => String(g._id) === String(id));
  const payments = allPayments.filter((p) => visible(groupOf(p.group), [p]).length);
  const by = (g) => allPayments.filter((p) => String(p.group) === String(g._id)); // full list, used for statuses

  const outstanding = groups.flatMap((g) => {
    const list = outstandingFor(g, by(g));
    if (canManage(g, req.user)) return list;
    const me = myMember(g, req.user);
    return me ? list.filter((i) => i.memberId === String(me._id)) : [];
  });

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
    managedGroups: groups.filter((g) => canManage(g, req.user)).length,
    joinedGroups: groups.filter((g) => !canManage(g, req.user)).length,
    totalMembers: groups.reduce((s, g) => s + g.members.length, 0),
    missedCount: outstanding.length,
    missedGroupName: outstanding[0] ? outstanding[0].groupName : null,
    nextUp,
    recent: payments.slice(0, 5).map((p) => ({ id: String(p._id), memberName: p.memberName, groupName: names[String(p.group)], amount: p.amount, date: p.date, method: p.method })),
  });
}));

module.exports = router;
