const mongoose = require('mongoose');
const Group = require('../models/Group');
const Payment = require('../models/Payment');
const Payout = require('../models/Payout');
const Notification = require('../models/Notification');
const { HttpError } = require('../utils/http');
const { monthKey, dueDate, statusFor, outstandingFor, payoutDate, monthsUpTo } = require('../utils/cycles');
const localDate = (value) => {
  const date = new Date(value);
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
};

function objectId(value, label = 'ID') {
  if (typeof value !== 'string' || !mongoose.isObjectIdOrHexString(value)) throw new HttpError(400, `Invalid ${label}.`);
  return value;
}

async function accessibleGroup(user, id, organizerOnly = false) {
  objectId(id, 'group ID');
  const access = organizerOnly ? { owner: user._id } : { $or: [{ owner: user._id }, { members: { $elemMatch: { firebaseUid: user.firebaseUid, status: 'Active' } } }] };
  const group = await Group.findOne({ _id: id, ...access });
  if (!group) throw new HttpError(404, 'Group not found.');
  if (group.frequency !== 'Monthly') throw new HttpError(400, 'These screens currently support monthly contribution pools.');
  return group;
}

function memberFor(group, id) {
  objectId(id, 'member ID');
  const member = group.members.id(id);
  if (!member || member.status !== 'Active') throw new HttpError(404, 'Active member not found.');
  return member;
}

function cycleFor(group, member, value) {
  if (typeof value !== 'string' || !/^\d{4}-(0[1-9]|1[0-2])$/.test(value)) throw new HttpError(400, 'Use a cycle in YYYY-MM format.');
  const joined = monthKey(new Date(Math.max(new Date(member.joinedAt), new Date(group.startDate))));
  const all = monthsUpTo(group, new Date(9999, 11, 1));
  if (value < joined || !all.includes(value)) throw new HttpError(400, 'Cycle is outside this member’s participation.');
  return value;
}

function publicGroup(group) {
  return { id: String(group._id), name: group.name, contribution: group.contribution,
    memberCount: group.members.filter((m) => m.status === 'Active').length,
    memberLimit: group.memberLimit, startDate: localDate(group.startDate), frequency: group.frequency };
}

async function outstanding(group) {
  const payments = await Payment.find({ group: group._id });
  const items = outstandingFor(group, payments).sort((a, b) => b.daysOverdue - a.daysOverdue)
    .map((item) => ({ ...item, dueDate: localDate(item.dueDate) }));
  return { group: publicGroup(group), items,
    totalOverdue: items.reduce((sum, item) => sum + item.amount, 0),
    overdueMembers: new Set(items.map((item) => item.memberId)).size,
    late: items.filter((item) => item.status === 'Late').length,
    missed: items.filter((item) => item.status === 'Missed').length,
    averageDaysOverdue: items.length ? Math.round(items.reduce((sum, item) => sum + item.daysOverdue, 0) / items.length) : 0,
  };
}

async function paymentDetail(group, member, cycle) {
  const payment = await Payment.findOne({ group: group._id, memberId: member._id, month: cycle });
  const due = dueDate(group, cycle);
  const { startOfDay, DAY } = require('../utils/cycles');
  const daysOverdue = Math.max(0, Math.floor((startOfDay(new Date()) - due) / DAY));
  const balance = Math.max(0, group.contribution - (payment?.amount || 0));
  const history = await Notification.find({ group: group._id, memberId: member._id, cycle }).sort({ createdAt: -1 }).limit(30);
  return { group: publicGroup(group), member: { id: String(member._id), name: member.name, phone: member.phone },
    cycle, dueDate: localDate(due), status: statusFor(group, payment ? [payment] : [], member, cycle),
    assignedAmount: group.contribution, paidAmount: payment?.amount || 0, pendingAmount: balance,
    daysOverdue: balance ? daysOverdue : 0,
    latePenalty: balance ? Math.max(0, daysOverdue - (group.policy?.graceDays ?? 7)) * (group.policy?.lateFeePerDay || 0) : 0,
    reference: payment?.reference || `${String(group._id).slice(-6)}-${String(member._id).slice(-6)}-${cycle}`,
    payment: payment ? { id: String(payment._id), date: payment.date, method: payment.method, amount: payment.amount } : null,
    communicationHistory: history.map((item) => ({ id: String(item._id), message: item.message, date: item.createdAt, status: item.deliveryStatus })),
  };
}

async function payoutSchedule(group) {
  const records = await Payout.find({ group: group._id });
  const members = [...group.members].filter((m) => m.status === 'Active').sort((a, b) => a.position - b.position);
  const potAmount = group.contribution * members.length;
  let currentSelected = false;
  const payouts = members.map((member) => {
    const record = records.find((p) => String(p.memberId) === String(member._id));
    let status = record?.status || 'Upcoming';
    if (status !== 'Paid' && !currentSelected) { currentSelected = true; status = record?.status || 'Current'; }
    return { memberId: String(member._id), name: member.name, position: member.position,
      date: localDate(payoutDate(group, member.position)), amount: record?.amount ?? potAmount, status,
      reference: record?.reference || null, method: record?.method || 'Bank Transfer', paidAt: record?.paidAt || null };
  });
  const completed = payouts.filter((p) => p.status === 'Paid').length;
  return { group: publicGroup(group), potAmount, completed, total: payouts.length,
    progress: payouts.length ? completed / payouts.length : 0,
    current: payouts.find((p) => p.status === 'Current' || p.status === 'Processing') || null, payouts };
}

function rulesFor(group) {
  const policy = group.policy || {};
  const graceDays = policy.graceDays ?? 7;
  const lateFeePerDay = policy.lateFeePerDay ?? 0;
  return { group: publicGroup(group), version: policy.version || '1.0', graceDays, lateFeePerDay,
    maxDiscountPercent: policy.maxDiscountPercent ?? 35,
    potAmount: group.contribution * group.members.filter((m) => m.status === 'Active').length,
    dueDay: Math.min(new Date(group.startDate).getDate(), 28),
    sections: {
      General: [{ title: 'Contribution schedule', text: `Members contribute Rs. ${group.contribution} every month. The due day is ${Math.min(new Date(group.startDate).getDate(), 28)}.` },
        { title: 'Payout schedule', text: 'The agreed member positions define payout order. Payouts are marked Paid only when the organizer records a completed disbursement.' }],
      Rules: [{ title: 'Shared records', text: 'Authorized group members may view contribution status and payout order. Only the group owner may change financial records or group policies.' }],
      Penalties: [{ title: 'Grace period', text: `Overdue contributions are Late for ${graceDays} days, then Missed.` },
        { title: 'Late payment fee', text: lateFeePerDay ? `Rs. ${lateFeePerDay} per day after the grace period, while a balance remains unpaid.` : 'This group has no configured late payment fee.' }],
    } };
}

module.exports = { objectId, accessibleGroup, memberFor, cycleFor, publicGroup, outstanding, paymentDetail, payoutSchedule, rulesFor };
