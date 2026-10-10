
const router = require('express').Router();

const Group = require('../models/Group');
const Payment = require('../models/Payment');
const Notification = require('../models/Notification');

const auth = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/http');

const {
  monthKey,
  dueDate,
  statusFor,
  outstandingFor,
  nextDue,
  myMember,
} = require('../utils/cycles');

const {
  roleOf,
  canManage,
  accessibleGroups,
  loadGroup,
} = require('../utils/access');

router.use(auth);

// Organizer can manage payments.
// Members can only view permitted group information.
const ownGroup = (user, groupId, manage = false) =>
  loadGroup(user, groupId, { manage });

// Format payment response.
const ser = (p) => ({
  id: String(p._id),
  memberId: String(p.memberId),
  memberName: p.memberName,
  amount: p.amount,
  month: p.month,
  date: p.date,
  method: p.method,
  reference: p.reference,
  status: 'Paid',
});

// Round monetary values to two decimal places.
const roundMoney = (value) =>
  Math.round((Number(value) + Number.EPSILON) * 100) / 100;

// Calculate all installments paid by a member for one month.
const paidFor = (payments, memberId, month) =>
  roundMoney(
    payments
      .filter(
        (p) =>
          String(p.memberId) === String(memberId) &&
          p.month === month
      )
      .reduce((total, p) => total + Number(p.amount), 0)
  );

// Calculate payment progress.
const paymentProgress = (contribution, paid) => {
  const total = roundMoney(contribution);
  const totalPaid = roundMoney(paid);
  const remaining = roundMoney(Math.max(0, total - totalPaid));

  return {
    contribution: total,
    totalPaid,
    remaining,
    paymentStatus:
      remaining === 0
        ? 'Paid'
        : totalPaid > 0
          ? 'Partial'
          : 'Pending',
  };
};

// ======================================================
// 1. RECORD PAYMENT
// POST /api/payments
// Organizer only
// Supports partial payments
// ======================================================

router.post('/', wrap(async (req, res) => {
  const {
    groupId,
    memberId,
    amount,
    month,
    date,
    method = 'Cash',
    reference = '',
  } = req.body || {};

  const g = await ownGroup(req.user, groupId, true);
  const m = g.members.id(memberId);

  if (!m) {
    throw new HttpError(404, 'Choose a valid member.');
  }

  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month || '')) {
    throw new HttpError(400, 'Enter a valid month (YYYY-MM).');
  }

  const amt =
    amount === undefined || amount === ''
      ? Number(g.contribution)
      : Number(amount);

  if (
    !Number.isFinite(amt) ||
    amt <= 0 ||
    !Number.isInteger(Math.round(amt * 100)) ||
    Math.abs(amt * 100 - Math.round(amt * 100)) > 0.000001
  ) {
    throw new HttpError(400, 'Enter a valid positive amount.');
  }

  if (!['Cash', 'Bank Transfer', 'Other'].includes(method)) {
    throw new HttpError(400, 'Invalid payment method.');
  }

  const paymentDate =
    date === undefined ? new Date() : new Date(date);

  if (!Number.isFinite(paymentDate.getTime())) {
    throw new HttpError(400, 'Enter a valid payment date.');
  }

  const query = {
    group: g._id,
    memberId: m._id,
    month,
  };

  const previousPayments = await Payment.find(query);

  const totalPaid = roundMoney(
    previousPayments.reduce(
      (sum, payment) => sum + Number(payment.amount),
      0
    )
  );

  const contribution = roundMoney(g.contribution);
  const remaining = roundMoney(contribution - totalPaid);

  if (remaining <= 0) {
    throw new HttpError(
      409,
      'This contribution is already fully paid.'
    );
  }

  if (amt > remaining) {
    throw new HttpError(
      400,
      `Amount exceeds remaining balance of Rs. ${remaining}.`
    );
  }

  const payment = await Payment.create({
    owner: g.owner,
    group: g._id,
    memberId: m._id,
    memberName: m.name,
    amount: amt,
    month,
    date: paymentDate,
    method,
    reference: String(reference).trim(),
  });

  const newTotal = roundMoney(totalPaid + amt);

  res.status(201).json({
    payment: ser(payment),
    contribution,
    totalPaid: newTotal,
    remaining: roundMoney(
      Math.max(0, contribution - newTotal)
    ),
    paymentStatus:
      newTotal >= contribution ? 'Paid' : 'Partial',
  });
}));

// ======================================================
// 2. PAYMENT HISTORY
// GET /api/payments/history?groupId=...
// ======================================================

router.get('/history', wrap(async (req, res) => {
  const g = await ownGroup(req.user, req.query.groupId);

  let list = await Payment.find({
    group: g._id,
  }).sort({
    date: -1,
    createdAt: -1,
  });

  // Members see only their own payments.
  if (!canManage(g, req.user)) {
    const me = myMember(g, req.user);

    list = me
      ? list.filter(
          (p) =>
            String(p.memberId) === String(me._id)
        )
      : [];
  }

  res.json({
    totalPaid: roundMoney(
      list.reduce(
        (sum, p) => sum + Number(p.amount),
        0
      )
    ),
    count: list.length,
    payments: list.map(ser),
  });
}));

// ======================================================
// 3. SHARED PAYMENT RECORDS
// GET /api/payments/shared?groupId=...&month=YYYY-MM
// ======================================================

router.get('/shared', wrap(async (req, res) => {
  const g = await ownGroup(req.user, req.query.groupId);

  const month = req.query.month || monthKey(new Date());

  if (!/^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
    throw new HttpError(400, 'Invalid payment month.');
  }

  const payments = await Payment.find({
    group: g._id,
    month,
  });

  const rows = g.members.map((m) => {
    const paidAmount = paidFor(
      payments,
      m._id,
      month
    );

    const progress = paymentProgress(
      g.contribution,
      paidAmount
    );

    const status =
      progress.paymentStatus === 'Paid'
        ? 'Paid'
        : progress.paymentStatus === 'Partial'
          ? 'Partial'
          : statusFor(g, payments, m, month);

    return {
      memberId: String(m._id),
      name: m.name,
      amount: g.contribution,
      paidAmount,
      remaining: progress.remaining,
      status,
    };
  });

  const count = (status) =>
    rows.filter(
      (row) => row.status === status
    ).length;

  res.json({
    month,
    rows,
    summary: {
      paid: count('Paid'),
      partial: count('Partial'),
      pending: count('Pending'),
      late: count('Late'),
      missed: count('Missed'),
    },
  });
}));

// ======================================================
// 4. OUTSTANDING PAYMENTS
// Existing teammate functionality - preserved
// ======================================================

router.get('/outstanding', wrap(async (req, res) => {
  const groups = req.query.groupId
    ? [await ownGroup(req.user, req.query.groupId)]
    : await accessibleGroups(req.user);

  const payments = await Payment.find({
    group: {
      $in: groups.map((g) => g._id),
    },
  });

  const items = groups
    .flatMap((g) => {
      const list = outstandingFor(
        g,
        payments.filter(
          (p) =>
            String(p.group) === String(g._id)
        )
      );

      if (canManage(g, req.user)) {
        return list;
      }

      const me = myMember(g, req.user);

      return me
        ? list.filter(
            (i) =>
              i.memberId === String(me._id)
          )
        : [];
    })
    .sort(
      (a, b) =>
        b.daysOverdue - a.daysOverdue
    );

  res.json({
    items,
    late: items.filter(
      (i) => i.status === 'Late'
    ).length,
    missed: items.filter(
      (i) => i.status === 'Missed'
    ).length,
  });
}));

// ======================================================
// 5. PAYMENT NOTIFICATIONS
// POST /api/payments/notify
// Organizer only
// ======================================================

router.post('/notify', wrap(async (req, res) => {
  const {
    groupId,
    memberId,
    month,
  } = req.body;

  const g = await ownGroup(
    req.user,
    groupId,
    true
  );

  const payments = await Payment.find({
    group: g._id,
  });

  let items = outstandingFor(
    g,
    payments
  );

  if (memberId) {
    items = items.filter(
      (i) =>
        i.memberId === String(memberId)
    );
  }

  if (month) {
    items = items.filter(
      (i) => i.month === month
    );
  }

  if (!items.length) {
    throw new HttpError(
      400,
      'There is nobody to notify.'
    );
  }

  await Notification.insertMany(
    items.map((i) => ({
      owner: g.owner,
      group: g._id,
      memberId: i.memberId,
      memberName: i.memberName,
      cycle: i.month,
      message:
        `Reminder: your ${g.name} contribution ` +
        `of Rs. ${i.amount} for ${i.month} ` +
        `is ${i.status.toLowerCase()}.`,
    }))
  );

  res.json({
    sent: items.length,
  });
}));

// ======================================================
// 6. PAYMENT DASHBOARD SUMMARY
// GET /api/payments/summary?groupId=...
// ======================================================

router.get('/summary', wrap(async (req, res) => {
  const g = await ownGroup(
    req.user,
    req.query.groupId
  );

  const key = monthKey(new Date());
  const me = myMember(g, req.user);

  const payments = me
    ? await Payment.find({
        group: g._id,
        memberId: me._id,
        month: key,
      })
    : [];

  const paidAmount = me
    ? paidFor(
        payments,
        me._id,
        key
      )
    : 0;

  const progress = paymentProgress(
    g.contribution,
    paidAmount
  );

  const myStatus = !me
    ? 'N/A'
    : progress.paymentStatus === 'Paid'
      ? 'Paid'
      : progress.paymentStatus === 'Partial'
        ? 'Partial'
        : statusFor(
            g,
            payments,
            me,
            key
          );

  res.json({
    monthlyAmount: g.contribution,
    nextDue: nextDue(g),
    month: key,
    dueDate: dueDate(g, key),
    myStatus,
    myMemberId: me
      ? String(me._id)
      : null,
    paidAmount,
    remainingAmount:
      progress.remaining,
    role: roleOf(
      g,
      req.user
    ),
    canManage: canManage(
      g,
      req.user
    ),
  });
}));

// ======================================================
// 7. MY PAYMENT NOTIFICATIONS
// GET /api/payments/notifications
// ======================================================

router.get('/notifications', wrap(async (req, res) => {
  const groups = await accessibleGroups(
    req.user
  );

  const mine = groups
    .map((g) => ({
      g,
      me: myMember(
        g,
        req.user
      ),
    }))
    .filter((x) => x.me);

  if (!mine.length) {
    return res.json({
      notifications: [],
    });
  }

  const list = await Notification.find({
    $or: mine.map((x) => ({
      group: x.g._id,
      memberId: x.me._id,
    })),
  })
    .sort({
      createdAt: -1,
    })
    .limit(50);

  const names = Object.fromEntries(
    groups.map((g) => [
      String(g._id),
      g.name,
    ])
  );

  res.json({
    notifications: list.map((n) => ({
      id: String(n._id),
      groupName:
        names[String(n.group)],
      message: n.message,
      cycle: n.cycle,
      createdAt: n.createdAt,
    })),
  });
}));

module.exports = router;
