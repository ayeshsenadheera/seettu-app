const express = require('express');
const Group = require('../models/Group');
const User = require('../models/User');
const Payout = require('../models/Payout');
const Notification = require('../models/Notification');
const { HttpError, wrap } = require('../utils/http');
const { normalizePhone } = require('../utils/phone');
const service = require('../services/sixScreens');

const profile = (user) => ({ id: String(user._id), name: user.name, email: user.email,
  phone: user.phone, role: user.role, status: 'Active', settings: user.settings });
const numberIn = (value, min, max, label, integer = false) => {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < min || value > max || (integer && !Number.isInteger(value))) throw new HttpError(400, `Invalid ${label}.`);
  return value;
};

module.exports = function createSixScreensRouter(authenticate) {
  const router = express.Router();
  router.use(authenticate);

  router.get('/groups', wrap(async (req, res) => {
    const groups = await Group.find({ $or: [{ owner: req.user._id }, { members: { $elemMatch: { firebaseUid: req.user.firebaseUid, status: 'Active' } } }] }).sort({ createdAt: 1 });
    res.json({ groups: groups.map((group) => ({ ...service.publicGroup(group), canManage: String(group.owner) === String(req.user._id) })) });
  }));

  router.get('/groups/:id/outstanding', wrap(async (req, res) => res.json(await service.outstanding(await service.accessibleGroup(req.user, req.params.id)))));

  router.put('/groups/:id/members/:memberId/account', wrap(async (req, res) => {
    const group = await service.accessibleGroup(req.user, req.params.id, true);
    const member = service.memberFor(group, req.params.memberId);
    service.objectId(req.body.userId, 'account ID');
    const account = await User.findById(req.body.userId);
    if (!account) throw new HttpError(404, 'Account not found.');
    if (group.members.some((item) => item.firebaseUid === account.firebaseUid && String(item._id) !== String(member._id))) throw new HttpError(409, 'This account is already linked to another member.');
    member.firebaseUid = account.firebaseUid;
    await group.save();
    res.json({ memberId: String(member._id), userId: String(account._id) });
  }));

  router.get('/groups/:id/payments/:memberId', wrap(async (req, res) => {
    const group = await service.accessibleGroup(req.user, req.params.id);
    const member = service.memberFor(group, req.params.memberId);
    const cycle = service.cycleFor(group, member, req.query.month);
    res.json(await service.paymentDetail(group, member, cycle));
  }));

  router.post('/groups/:id/reminders', wrap(async (req, res) => {
    const group = await service.accessibleGroup(req.user, req.params.id, true);
    const report = await service.outstanding(group);
    let items = report.items;
    if (req.body.memberId !== undefined) {
      const member = service.memberFor(group, req.body.memberId);
      items = items.filter((item) => item.memberId === String(member._id));
      if (req.body.month !== undefined) {
        const cycle = service.cycleFor(group, member, req.body.month);
        items = items.filter((item) => item.month === cycle);
      }
    } else if (req.body.month !== undefined) throw new HttpError(400, 'Select a member when selecting a cycle.');
    if (!items.length) throw new HttpError(400, 'There are no outstanding contributions to remind.');
    const records = await Notification.insertMany(items.map((item) => ({ owner: req.user._id, group: group._id,
      memberId: item.memberId, memberName: item.memberName, cycle: item.month,
      message: `Your ${group.name} contribution balance of Rs. ${item.amount} for ${item.month} is ${item.status.toLowerCase()}.`,
      deliveryStatus: 'Recorded' })));
    res.status(201).json({ recorded: records.length, delivery: 'not_configured', message: 'Reminder records saved. SMS, WhatsApp and push delivery are not connected.' });
  }));

  router.get('/groups/:id/payouts', wrap(async (req, res) => res.json(await service.payoutSchedule(await service.accessibleGroup(req.user, req.params.id)))));
  router.get('/groups/:id/payouts/:memberId', wrap(async (req, res) => {
    const group = await service.accessibleGroup(req.user, req.params.id);
    const member = service.memberFor(group, req.params.memberId);
    const schedule = await service.payoutSchedule(group);
    res.json({ group: schedule.group, total: schedule.total, payout: schedule.payouts.find((item) => item.memberId === String(member._id)) });
  }));

  router.post('/groups/:id/payouts/:memberId', wrap(async (req, res) => {
    const group = await service.accessibleGroup(req.user, req.params.id, true);
    const member = service.memberFor(group, req.params.memberId);
    const { status, reference, method = 'Bank Transfer' } = req.body;
    if (!['Processing', 'Paid'].includes(status)) throw new HttpError(400, 'Choose Processing or Paid.');
    if (typeof reference !== 'string' || !reference.trim() || reference.length > 120) throw new HttpError(400, 'Enter a payout reference (up to 120 characters).');
    if (!['Cash', 'Bank Transfer', 'Other'].includes(method)) throw new HttpError(400, 'Invalid payout method.');
    const existing = await Payout.findOne({ group: group._id, memberId: member._id });
    if (existing?.status === 'Paid') {
      if (existing.reference === reference.trim() && status === 'Paid') return res.json({ payout: existing, alreadyRecorded: true });
      throw new HttpError(409, 'This payout has already been recorded as Paid.');
    }
    const schedule = await service.payoutSchedule(group);
    if (schedule.current?.memberId !== String(member._id)) throw new HttpError(409, 'Record payouts in the agreed order.');
    const record = await Payout.findOneAndUpdate({ group: group._id, memberId: member._id, status: { $ne: 'Paid' } }, {
      $set: { memberName: member.name, position: member.position, amount: schedule.potAmount,
        status, reference: reference.trim(), method, recordedBy: req.user._id, paidAt: status === 'Paid' ? new Date() : null },
    }, { upsert: true, new: true, runValidators: true });
    res.status(existing ? 200 : 201).json({ payout: record, moneyTransferred: false });
  }));

  router.get('/groups/:id/rules', wrap(async (req, res) => res.json(service.rulesFor(await service.accessibleGroup(req.user, req.params.id)))));
  router.put('/groups/:id/rules', wrap(async (req, res) => {
    const group = await service.accessibleGroup(req.user, req.params.id, true);
    const patch = {};
    for (const field of Object.keys(req.body)) {
      if (!['graceDays', 'lateFeePerDay', 'maxDiscountPercent'].includes(field)) throw new HttpError(400, `Unknown rule: ${field}.`);
      patch[field] = numberIn(req.body[field], 0, field === 'graceDays' ? 30 : field === 'maxDiscountPercent' ? 100 : 1000000, field, field === 'graceDays');
    }
    Object.assign(group.policy, patch);
    await group.save();
    res.json(service.rulesFor(group));
  }));

  router.get('/profile', wrap(async (req, res) => res.json({ user: profile(req.user) })));
  router.put('/profile', wrap(async (req, res) => {
    const { name, phone } = req.body;
    if (req.body.email !== undefined) throw new HttpError(400, 'Email changes must be made through Firebase Authentication.');
    if (typeof name !== 'string' || name.trim().length < 2 || name.length > 100) throw new HttpError(400, 'Enter a full name (2–100 characters).');
    const normalized = normalizePhone(phone);
    if (!normalized) throw new HttpError(400, 'Enter a valid Sri Lankan phone number.');
    req.user.name = name.trim(); req.user.phone = normalized;
    await req.user.save();
    res.json({ user: profile(req.user) });
  }));
  router.put('/profile/settings', wrap(async (req, res) => {
    const settings = req.user.settings;
    for (const [key, value] of Object.entries(req.body)) {
      if (key === 'notificationsEnabled' || key === 'sharePayoutUpdates') {
        if (typeof value !== 'boolean') throw new HttpError(400, `${key} must be a boolean.`);
        if (key === 'notificationsEnabled') settings.reminder.enabled = value;
        else settings.sharePayoutUpdates = value;
      } else if (key === 'textSize') {
        if (!['Small', 'Medium', 'Large', 'Extra Large'].includes(value)) throw new HttpError(400, 'Invalid text size.');
        settings.textSize = value;
      } else if (key === 'language') {
        if (!['English', 'Sinhala', 'Tamil'].includes(value)) throw new HttpError(400, 'Invalid language.');
        settings.language = value;
      } else throw new HttpError(400, `Unknown setting: ${key}.`);
    }
    await req.user.save();
    res.json({ settings });
  }));
  return router;
};
