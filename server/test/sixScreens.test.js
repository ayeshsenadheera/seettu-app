process.env.TZ = 'Asia/Colombo';
process.env.MONGOMS_DOWNLOAD_DIR = require('path').resolve(__dirname, '../.mongo-binaries');
process.env.TEMP = require('path').resolve(__dirname, '../.test-tmp');
process.env.TMP = process.env.TEMP;
require('fs').mkdirSync(process.env.TEMP, { recursive: true });
const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const mongoose = require('mongoose');
const request = require('supertest');
const { MongoMemoryServer } = require('mongodb-memory-server');
const { createApp } = require('../src/app');
const { createAuth } = require('../src/middleware/auth');
const User = require('../src/models/User');
const Group = require('../src/models/Group');
const Payment = require('../src/models/Payment');
const Payout = require('../src/models/Payout');
const Notification = require('../src/models/Notification');
const { monthKey, monthsUpTo, payoutDate, statusFor } = require('../src/utils/cycles');

let database, app, owner, participant, outsider, group;
before(async () => {
  database = await MongoMemoryServer.create();
  await mongoose.connect(database.getUri());
  await Promise.all([User.init(), Group.init(), Payment.init(), Payout.init()]);
  // Only the test app injects a token verifier; production always uses Firebase.
  app = createApp({ authenticate: createAuth({ verifyToken: async (token) => {
    if (!['owner-token', 'participant-token', 'outsider-token'].includes(token)) throw new Error('Invalid token');
    return { uid: token.replace('-token', '') };
  } }) });
});
after(async () => { await mongoose.disconnect(); await database?.stop(); });
beforeEach(async () => {
  await Promise.all([User.deleteMany({}), Group.deleteMany({}), Payment.deleteMany({}), Payout.deleteMany({}), Notification.deleteMany({})]);
  [owner, participant, outsider] = await User.create([
    { firebaseUid: 'owner', name: 'Marcus Vance', email: 'marcus@example.com', phone: '0771234567' },
    { firebaseUid: 'participant', name: 'Alice Cameron', email: 'alice@example.com', phone: '0777654321', role: 'Participant' },
    // Sharing a phone number alone must not grant access to a group.
    { firebaseUid: 'outsider', name: 'Other User', email: 'other@example.com', phone: '0777654321' },
  ]);
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth() - 2, 1);
  group = await Group.create({ owner: owner._id, name: 'Community Pool', contribution: 25000,
    memberLimit: 3, startDate: start, policy: { graceDays: 7, lateFeePerDay: 50 }, members: [
      { name: owner.name, phone: owner.phone, firebaseUid: owner.firebaseUid, position: 1, joinedAt: start },
      { name: participant.name, phone: participant.phone, firebaseUid: participant.firebaseUid, position: 2, joinedAt: start },
      { name: 'Kiara Jaxson', phone: '0771112233', position: 3, joinedAt: start },
    ] });
});
const get = (path, token = 'owner-token') => request(app).get('/api/ui' + path).set('Authorization', 'Bearer ' + token);
const post = (path, data, token = 'owner-token') => request(app).post('/api/ui' + path).set('Authorization', 'Bearer ' + token).send(data);
const put = (path, data, token = 'owner-token') => request(app).put('/api/ui' + path).set('Authorization', 'Bearer ' + token).send(data);

test('authentication and account-bound group access are enforced', async () => {
  await request(app).get('/api/ui/groups').expect(401);
  await get('/groups', 'invalid-token').expect(401);
  const groups = await get('/groups', 'participant-token').expect(200);
  assert.equal(groups.body.groups.length, 1);
  await get(`/groups/${group.id}/outstanding`, 'outsider-token').expect(404);
  await get('/groups/not-an-id/outstanding').expect(400);
  await put(`/groups/${group.id}/rules`, { graceDays: 10 }, 'participant-token').expect(404);
  await post(`/groups/${group.id}/reminders`, {}, 'participant-token').expect(404);
});

test('outstanding detail deducts partial payments and returns stored communication history', async () => {
  const member = group.members[0];
  const month = monthKey(group.startDate);
  await Payment.create({ owner: owner._id, group: group._id, memberId: member._id,
    memberName: member.name, amount: 15000, month, date: group.startDate, reference: 'PARTIAL-001' });
  const detail = await get(`/groups/${group.id}/payments/${member.id}?month=${month}`).expect(200);
  assert.equal(detail.body.pendingAmount, 10000);
  assert.equal(detail.body.status, 'Missed');
  assert.equal(detail.body.reference, 'PARTIAL-001');
  assert.equal(detail.body.dueDate, `${month}-01`);
  const outstanding = await get(`/groups/${group.id}/outstanding`).expect(200);
  assert.equal(outstanding.body.overdueMembers, 3);
  assert.ok(outstanding.body.items.some((item) => item.memberId === member.id && item.amount === 10000));
  const reminder = await post(`/groups/${group.id}/reminders`, { memberId: member.id, month }).expect(201);
  assert.equal(reminder.body.recorded, 1);
  assert.equal(reminder.body.delivery, 'not_configured');
  const updated = await get(`/groups/${group.id}/payments/${member.id}?month=${month}`).expect(200);
  assert.equal(updated.body.communicationHistory.length, 1);
  assert.equal(updated.body.communicationHistory[0].status, 'Recorded');
  await get(`/groups/${group.id}/payments/${member.id}?month=2026-13`).expect(400);
});

test('past payout dates do not imply payment; payout recording is ordered and idempotent', async () => {
  const schedule = await get(`/groups/${group.id}/payouts`).expect(200);
  assert.equal(schedule.body.completed, 0);
  assert.equal(schedule.body.current.memberId, group.members[0].id);
  assert.equal(schedule.body.potAmount, 75000);
  await post(`/groups/${group.id}/payouts/${group.members[1].id}`, { status: 'Paid', reference: 'OUT-OF-ORDER' }).expect(409);
  const endpoint = `/groups/${group.id}/payouts/${group.members[0].id}`;
  await post(endpoint, { status: 'Paid', reference: 'BANK-001' }, 'participant-token').expect(404);
  await post(endpoint, { status: 'Paid', reference: 'BANK-001' }).expect(201);
  const repeat = await post(endpoint, { status: 'Paid', reference: 'BANK-001' }).expect(200);
  assert.equal(repeat.body.alreadyRecorded, true);
  await post(endpoint, { status: 'Processing', reference: 'BANK-002' }).expect(409);
  const changed = await get(`/groups/${group.id}/payouts`).expect(200);
  assert.equal(changed.body.completed, 1);
  assert.equal(changed.body.current.memberId, group.members[1].id);
  assert.equal(await Payout.countDocuments(), 1);
  const detail = await get(endpoint).expect(200);
  assert.equal(detail.body.payout.reference, 'BANK-001');
});

test('profile, privacy and notification settings persist with validation', async () => {
  await put('/profile', { name: 'Yeshani Wijesundara', phone: '0771234567' }).expect(200);
  await put('/profile/settings', { notificationsEnabled: false, sharePayoutUpdates: true, textSize: 'Large' }).expect(200);
  const saved = await get('/profile').expect(200);
  assert.equal(saved.body.user.name, 'Yeshani Wijesundara');
  assert.equal(saved.body.user.settings.reminder.enabled, false);
  assert.equal(saved.body.user.settings.sharePayoutUpdates, true);
  await put('/profile', { name: 'Valid Name', phone: '0771234567', email: 'spoof@example.com' }).expect(400);
  await put('/profile/settings', { notificationsEnabled: 'false' }).expect(400);
  await put('/profile/settings', { textSize: 'Small', unknown: true }).expect(400);
  const unchanged = await get('/profile').expect(200);
  assert.equal(unchanged.body.user.settings.textSize, 'Large');
});

test('rules persist and invalid policies cannot be stored', async () => {
  await put(`/groups/${group.id}/rules`, { graceDays: 10, lateFeePerDay: 100, maxDiscountPercent: 25 }).expect(200);
  const rules = await get(`/groups/${group.id}/rules`, 'participant-token').expect(200);
  assert.equal(rules.body.graceDays, 10);
  assert.equal(rules.body.lateFeePerDay, 100);
  assert.equal(rules.body.sections.Penalties.length, 2);
  await put(`/groups/${group.id}/rules`, { graceDays: 1.5 }).expect(400);
  await put(`/groups/${group.id}/rules`, { lateFeePerDay: -1 }).expect(400);
  await put(`/groups/${group.id}/rules`, { owner: outsider.id }).expect(400);
});

test('future and finished pools do not generate endless contribution cycles; month-end dates clamp', () => {
  const example = { startDate: new Date(2026, 0, 31), memberLimit: 3, members: [], frequency: 'Monthly', contribution: 25000 };
  assert.deepEqual(monthsUpTo(example, new Date(2025, 11, 1)), []);
  assert.deepEqual(monthsUpTo(example, new Date(2030, 0, 1)), ['2026-01', '2026-02', '2026-03']);
  assert.equal(payoutDate(example, 2).getMonth(), 1);
  assert.equal(payoutDate(example, 2).getDate(), 28);
  const member = { _id: 'member', joinedAt: example.startDate };
  assert.equal(statusFor(example, [{ memberId: 'member', month: '2026-02', amount: 10000 }], member, '2026-02', new Date(2026, 2, 10)), 'Missed');
});
