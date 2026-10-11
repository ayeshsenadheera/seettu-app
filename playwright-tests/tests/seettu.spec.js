// Seettu functional test cases TC-01 ... TC-29 (report section 8), run with Playwright against the Seettu API.
// Each test title starts with its test-case ID so the report can quote the result directly.
const { test, expect } = require('@playwright/test');
const h = require('./helpers');

test.describe.configure({ mode: 'serial' });

// First day of the month two months ago, so earlier cycles are already overdue.
const d0 = new Date(); d0.setDate(1); d0.setMonth(d0.getMonth() - 2);
const MONTH = `${d0.getFullYear()}-${String(d0.getMonth() + 1).padStart(2, '0')}`;
const START = `${MONTH}-01`;

const now = new Date();
const NOW_MONTH = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

const groupBody = (name, extra = {}) => ({ name, contribution: 5000, frequency: 'Monthly', memberLimit: 10, startDate: START, description: '', ...extra });
const NOT_ORGANIZER = 'Only the group organizer can do this.';

const U = {};          // test users
const S = {};          // shared state between tests
const api = (u, method, url, data) => h.call(u.token, method, url, data);
const members = async (u, gid) => (await api(u, 'GET', `/api/groups/${gid}/members`)).body.members;
const memberId = async (u, gid, name) => (await members(u, gid)).find((m) => m.name === name).id;

test.beforeAll(async () => {
  const health = await h.call(null, 'GET', '/api/health');
  if (health.status !== 200 || !health.body.ok) throw new Error('The server is not reachable. Start it first and check API_URL.');
  if (health.body.database !== 'connected') throw new Error('The server cannot reach its database.');

  U.org = await h.makeUser('org', 'Organizer One');
  U.nimal = await h.makeUser('nimal', 'Nimal Perera');
  U.late = await h.makeUser('late', 'Late Payer');
  U.rem = await h.makeUser('rem', 'Remove Me');
  U.outsider = await h.makeUser('outsider', 'Outsider Person');

  // G0 = the main group used by most tests
  const g = await api(U.org, 'POST', '/api/groups', groupBody(`PW Family Seettu ${h.RUN}`));
  expect(g.status).toBe(201);
  S.g0 = g.body.group.id; S.g0name = g.body.group.name;
  for (const u of [U.nimal, U.late, U.rem]) {
    const r = await api(U.org, 'POST', `/api/groups/${S.g0}/members`, { name: u.name, phone: u.phone, email: u.email });
    expect(r.status).toBe(201);
  }
  const s = await api(U.org, 'POST', `/api/groups/${S.g0}/members`, { name: 'Sunil Fernando', phone: h.uniquePhone() });
  expect(s.status).toBe(201);
  S.nimalMid = await memberId(U.org, S.g0, 'Nimal Perera');
  S.lateMid = await memberId(U.org, S.g0, 'Late Payer');
  S.sunilMid = await memberId(U.org, S.g0, 'Sunil Fernando');
});

test.afterAll(async () => { await h.cleanupFirebase(); await h.dispose(); });

/* ---------------- Groups (FR1) ---------------- */
test('TC-01 [FR1] Create a group with valid details; creator is the Organizer', async () => {
  const before = (await api(U.org, 'GET', '/api/groups')).body.groups.length;
  const r = await api(U.org, 'POST', '/api/groups', groupBody(`PW Group One ${h.RUN}`));
  expect(r.status).toBe(201);
  expect(r.body.group.role).toBe('Organizer');
  expect(r.body.group.canManage).toBe(true);
  S.g1 = r.body.group.id;
  const list = (await api(U.org, 'GET', '/api/groups')).body.groups;
  expect(list.length).toBe(before + 1);
  expect(list.map((g) => g.id)).toContain(S.g1);
});

test('TC-02 [FR1] Create a group with amount 0 is refused and nothing is saved', async () => {
  const before = (await api(U.org, 'GET', '/api/groups')).body.groups.length;
  const r = await api(U.org, 'POST', '/api/groups', groupBody('PW Zero Group', { contribution: 0 }));
  expect(r.status).toBe(400);
  expect(r.body.message).toMatch(/more than 0/);
  expect((await api(U.org, 'GET', '/api/groups')).body.groups.length).toBe(before);
});

test('TC-03 [FR1] Organizer edits group name and amount; changes show in Group details', async () => {
  const r = await api(U.org, 'PUT', `/api/groups/${S.g1}`, groupBody(`PW Renamed ${h.RUN}`, { contribution: 6000 }));
  expect(r.status).toBe(200);
  const g = (await api(U.org, 'GET', `/api/groups/${S.g1}`)).body.group;
  expect(g.name).toBe(`PW Renamed ${h.RUN}`);
  expect(g.contribution).toBe(6000);
});

test('TC-04 [FR1] A member who opens Edit group and saves is refused (only the organizer can do this)', async () => {
  const r = await api(U.nimal, 'PUT', `/api/groups/${S.g0}`, groupBody('Hacked name'));
  expect(r.status).toBe(403);
  expect(r.body.message).toBe(NOT_ORGANIZER);
  const g = (await api(U.org, 'GET', `/api/groups/${S.g0}`)).body.group;
  expect(g.name).toBe(S.g0name);
});

test('TC-05 [FR1] Organizer deletes a group; the group and its payments are removed', async () => {
  const orgMid = (await members(U.org, S.g1))[0].id;
  const p = await api(U.org, 'POST', '/api/payments', { groupId: S.g1, memberId: orgMid, month: MONTH });
  expect(p.status).toBe(201);
  const del = await api(U.org, 'DELETE', `/api/groups/${S.g1}`);
  expect(del.status).toBe(200);
  expect((await api(U.org, 'GET', `/api/groups/${S.g1}`)).status).toBe(404);
  expect((await api(U.org, 'GET', `/api/payments/history?groupId=${S.g1}`)).status).toBe(404);
  const ids = (await api(U.org, 'GET', '/api/groups')).body.groups.map((g) => g.id);
  expect(ids).not.toContain(S.g1);
});

/* ---------------- Members (FR2) ---------------- */
test('TC-06 [FR2] Organizer adds a member with name and phone; the member appears in the list', async () => {
  const phone = h.uniquePhone();
  const r = await api(U.org, 'POST', `/api/groups/${S.g0}/members`, { name: 'Kasun Silva', phone });
  expect(r.status).toBe(201);
  S.kasunPhone = phone;
  const list = await members(U.org, S.g0);
  expect(list.map((m) => m.name)).toContain('Kasun Silva');
  S.kasunMid = list.find((m) => m.name === 'Kasun Silva').id;
});

test('TC-07 [FR2] Adding a member with a phone number already in the group is refused', async () => {
  const r = await api(U.org, 'POST', `/api/groups/${S.g0}/members`, { name: 'Kasun Again', phone: S.kasunPhone });
  expect(r.status).toBe(409);
  expect(r.body.message).toMatch(/already in the group/);
  expect((await members(U.org, S.g0)).filter((m) => m.name === 'Kasun Again').length).toBe(0);
});

test('TC-08 [FR2] Organizer sets a member to Inactive; the member is left out of overdue lists', async () => {
  const before = (await api(U.org, 'GET', `/api/payments/outstanding?groupId=${S.g0}`)).body.items;
  expect(before.map((i) => i.memberName)).toContain('Kasun Silva');
  const r = await api(U.org, 'PUT', `/api/groups/${S.g0}/members/${S.kasunMid}`, { name: 'Kasun Silva', phone: S.kasunPhone, email: '', status: 'Inactive' });
  expect(r.status).toBe(200);
  expect(r.body.member.status).toBe('Inactive');
  const after = (await api(U.org, 'GET', `/api/payments/outstanding?groupId=${S.g0}`)).body.items;
  expect(after.map((i) => i.memberName)).not.toContain('Kasun Silva');
});

test('TC-09 [FR2] Organizer removes a member; that person no longer sees the group', async () => {
  const mid = await memberId(U.org, S.g0, 'Remove Me');
  const seesBefore = (await api(U.rem, 'GET', '/api/groups')).body.groups.map((g) => g.id);
  expect(seesBefore).toContain(S.g0);
  const r = await api(U.org, 'DELETE', `/api/groups/${S.g0}/members/${mid}`);
  expect(r.status).toBe(200);
  expect((await members(U.org, S.g0)).map((m) => m.name)).not.toContain('Remove Me');
  expect((await api(U.rem, 'GET', '/api/groups')).body.groups.map((g) => g.id)).not.toContain(S.g0);
  expect((await api(U.rem, 'GET', `/api/groups/${S.g0}`)).status).toBe(404);
});

test("TC-10 [FR2] Organizer cannot remove their own entry", async () => {
  const org = (await members(U.org, S.g0)).find((m) => m.role === 'Organizer');
  const r = await api(U.org, 'DELETE', `/api/groups/${S.g0}/members/${org.id}`);
  expect(r.status).toBe(400);
  expect(r.body.message).toMatch(/can't remove yourself/);
  expect((await members(U.org, S.g0)).map((m) => m.id)).toContain(org.id);
});

test('TC-11 [FR2] A member who tries to add or remove a member is refused', async () => {
  const add = await api(U.nimal, 'POST', `/api/groups/${S.g0}/members`, { name: 'Evil Person', phone: h.uniquePhone() });
  expect(add.status).toBe(403);
  expect(add.body.message).toBe(NOT_ORGANIZER);
  const del = await api(U.nimal, 'DELETE', `/api/groups/${S.g0}/members/${S.sunilMid}`);
  expect(del.status).toBe(403);
  expect((await members(U.org, S.g0)).map((m) => m.name)).toContain('Sunil Fernando');
});

/* ---------------- Roles and privacy (NFR4) ---------------- */
test('TC-12 [NFR4] A person who already has an account is added and sees the group as Member', async () => {
  U.amal = await h.makeUser('amal', 'Amal Jayasinghe');
  const r = await api(U.org, 'POST', `/api/groups/${S.g0}/members`, { name: U.amal.name, phone: U.amal.phone });
  expect(r.status).toBe(201);
  expect(r.body.linked).toBe(true);
  const g = (await api(U.amal, 'GET', '/api/groups')).body.groups.find((x) => x.id === S.g0);
  expect(g).toBeTruthy();
  expect(g.role).toBe('Member');
  expect(g.canManage).toBe(false);
});

test('TC-13 [NFR4] A person added before signing up sees the group as Member after signing up with the same email', async () => {
  const email = h.uniqueEmail('joiner');
  const added = await api(U.org, 'POST', `/api/groups/${S.g0}/members`, { name: 'Late Joiner', phone: h.uniquePhone(), email });
  expect(added.status).toBe(201);
  expect(added.body.linked).toBe(false);
  U.joiner = await h.makeUser('joiner', 'Late Joiner', { email }); // different phone, same email
  const g = (await api(U.joiner, 'GET', '/api/groups')).body.groups.find((x) => x.id === S.g0);
  expect(g).toBeTruthy();
  expect(g.role).toBe('Member');
});

test('TC-14 [NFR4] An account with no link to the group cannot open it (not found, nothing shown)', async () => {
  expect((await api(U.outsider, 'GET', '/api/groups')).body.groups.length).toBe(0);
  const r = await api(U.outsider, 'GET', `/api/groups/${S.g0}`);
  expect(r.status).toBe(404);
  expect((await api(U.outsider, 'GET', `/api/groups/${S.g0}/members`)).status).toBe(404);
  expect((await api(U.outsider, 'GET', `/api/payments/history?groupId=${S.g0}`)).status).toBe(404);
});

/* ---------------- Payments (FR3, FR4, FR5, FR8, FR9) ---------------- */
test('TC-15 [FR3] Organizer records a payment for a member and month; status becomes Paid', async () => {
  const r = await api(U.org, 'POST', '/api/payments', { groupId: S.g0, memberId: S.nimalMid, month: MONTH, method: 'Cash' });
  expect(r.status).toBe(201);
  expect(r.body.payment.status).toBe('Paid');
  const board = (await api(U.org, 'GET', `/api/payments/shared?groupId=${S.g0}&month=${MONTH}`)).body.rows;
  expect(board.find((x) => x.name === 'Nimal Perera').status).toBe('Paid');
});

test('TC-16 [FR3] A second payment for the same member and month is refused (already recorded)', async () => {
  const r = await api(U.org, 'POST', '/api/payments', { groupId: S.g0, memberId: S.nimalMid, month: MONTH });
  expect(r.status).toBe(409);
  expect(r.body.message).toMatch(/already has a payment recorded/);
  const hist = (await api(U.nimal, 'GET', `/api/payments/history?groupId=${S.g0}`)).body;
  expect(hist.count).toBe(1);
});

test('TC-17 [FR3] A member who tries to record a payment is refused', async () => {
  const r = await api(U.nimal, 'POST', '/api/payments', { groupId: S.g0, memberId: S.lateMid, month: MONTH });
  expect(r.status).toBe(403);
  expect(r.body.message).toBe(NOT_ORGANIZER);
});

test('TC-18 [FR4, FR8] A member sees only their own payments in the history', async () => {
  const other = await api(U.org, 'POST', '/api/payments', { groupId: S.g0, memberId: S.sunilMid, month: MONTH });
  expect(other.status).toBe(201);
  const mine = (await api(U.nimal, 'GET', `/api/payments/history?groupId=${S.g0}`)).body;
  expect(mine.count).toBe(1);
  expect(mine.payments.every((p) => p.memberId === S.nimalMid)).toBe(true);
  const all = (await api(U.org, 'GET', `/api/payments/history?groupId=${S.g0}`)).body;
  expect(all.count).toBe(2);
});

test('TC-19 [FR5] Any member can open the shared payment records and sees every status', async () => {
  const r = await api(U.nimal, 'GET', `/api/payments/shared?groupId=${S.g0}&month=${MONTH}`);
  expect(r.status).toBe(200);
  const total = (await members(U.org, S.g0)).length;
  expect(r.body.rows.length).toBe(total);
  const allowed = ['Paid', 'Pending', 'Late', 'Missed', 'N/A'];
  expect(r.body.rows.every((x) => allowed.includes(x.status))).toBe(true);
  expect(r.body.rows.find((x) => x.name === 'Nimal Perera').status).toBe('Paid');
  expect(r.body.rows.find((x) => x.name === 'Sunil Fernando').status).toBe('Paid');
  // people who joined this month and have not paid are overdue for the current month (due on the 1st + 7 days grace)
  const current = (await api(U.nimal, 'GET', `/api/payments/shared?groupId=${S.g0}&month=${NOW_MONTH}`)).body.rows;
  expect(['Late', 'Missed']).toContain(current.find((x) => x.name === 'Late Payer').status);
});

test('TC-20 [FR9] Organizer sees all overdue members; a member sees only their own', async () => {
  const org = (await api(U.org, 'GET', `/api/payments/outstanding?groupId=${S.g0}`)).body.items;
  expect(org.length).toBeGreaterThan(0);
  expect(org.map((i) => i.memberName)).toContain('Late Payer');
  const mine = (await api(U.late, 'GET', `/api/payments/outstanding?groupId=${S.g0}`)).body.items;
  expect(mine.length).toBeGreaterThan(0);
  expect(mine.every((i) => i.memberName === 'Late Payer')).toBe(true);
  const other = (await api(U.nimal, 'GET', `/api/payments/outstanding?groupId=${S.g0}`)).body.items;
  expect(other.every((i) => i.memberName === 'Nimal Perera')).toBe(true);
});

/* ---------------- Reminders (FR7), payouts (FR6) ---------------- */
test('TC-21 [FR7] Organizer sends a reminder to an overdue member; it is saved in the member inbox', async () => {
  const r = await api(U.org, 'POST', '/api/payments/notify', { groupId: S.g0, memberId: S.lateMid });
  expect(r.status).toBe(200);
  expect(r.body.sent).toBeGreaterThanOrEqual(1);
  const inbox = (await api(U.late, 'GET', '/api/payments/notifications')).body.notifications;
  expect(inbox.length).toBeGreaterThanOrEqual(1);
  expect(inbox[0].message).toMatch(/Reminder/);
  expect((await api(U.nimal, 'GET', '/api/payments/notifications')).body.notifications.every((n) => n.cycle !== MONTH)).toBe(true);
});

test('TC-22 [FR7] A member who tries to send a reminder is refused', async () => {
  const r = await api(U.nimal, 'POST', '/api/payments/notify', { groupId: S.g0, memberId: S.lateMid });
  expect(r.status).toBe(403);
  expect(r.body.message).toBe(NOT_ORGANIZER);
});

test('TC-23 [FR6] A member can see the payout order and next payout but cannot change it', async () => {
  const r = await api(U.nimal, 'GET', `/api/groups/${S.g0}/payouts`);
  expect(r.status).toBe(200);
  expect(r.body.payouts.length).toBeGreaterThanOrEqual(5);
  const positions = r.body.payouts.map((p) => p.position);
  expect(positions).toEqual([...positions].sort((a, b) => a - b));
  expect(r.body.payouts.some((p) => p.status === 'Current' || p.status === 'Upcoming')).toBe(true);
  const change = await api(U.nimal, 'PUT', `/api/groups/${S.g0}/members/${S.sunilMid}`, { name: 'Sunil Fernando', phone: h.uniquePhone(), position: 1 });
  expect(change.status).toBe(403);
});

/* ---------------- Trusted people (NFR4) ---------------- */
test('TC-24 [NFR4] Organizer invites a trusted person; they enter the code and see only what was shared', async () => {
  U.mum = await h.makeUser('mum', 'Mother Perera');
  const inv = await api(U.org, 'POST', '/api/trusted', { name: 'Mother Perera', phone: U.mum.phone, relationship: 'Family', share: ['paymentStatus', 'payoutDate', 'amount'] });
  expect(inv.status).toBe(201);
  expect(inv.body.person.inviteCode).toMatch(/^\d{6}$/);
  S.trustedId = inv.body.person.id;
  const acc = await api(U.mum, 'POST', '/api/trusted/accept', { code: inv.body.person.inviteCode });
  expect(acc.status).toBe(200);
  const shared = (await api(U.mum, 'GET', '/api/trusted/shared')).body.shared;
  expect(shared.length).toBe(1);
  expect(shared[0].data.groupName).toBe(S.g0name);
  expect(shared[0].data.paymentStatus).toBeTruthy();
  expect(shared[0].data.payoutDate).toBeTruthy();
  // a trusted person is not a group member
  expect((await api(U.mum, 'GET', '/api/groups')).body.groups.length).toBe(0);
  expect((await api(U.mum, 'GET', `/api/groups/${S.g0}`)).status).toBe(404);
});

test('TC-25 [NFR4] Organizer removes a trusted person; they can no longer open the shared view', async () => {
  const del = await api(U.org, 'DELETE', `/api/trusted/${S.trustedId}`);
  expect(del.status).toBe(200);
  expect((await api(U.mum, 'GET', '/api/trusted/shared')).body.shared.length).toBe(0);
  expect((await api(U.org, 'GET', '/api/trusted')).body.people.length).toBe(0);
});

test('TC-26 [FR1, NFR4] Home totals for a member count only their own payments', async () => {
  const member = await api(U.nimal, 'GET', '/api/dashboard');
  expect(member.status).toBe(200);
  expect(member.body.totalSavings).toBe(5000);
  const organizer = await api(U.org, 'GET', '/api/dashboard');
  expect(organizer.body.totalSavings).toBeGreaterThan(member.body.totalSavings);
});

/* ---------------- Account (ACC) ---------------- */
test('TC-27 [ACC] Create an account with name, phone, email and password', async () => {
  const email = h.uniqueEmail('fresh');
  const fb = await h.fbSignUp(email);
  const noName = await h.call(fb.idToken, 'POST', '/api/auth/sync', { name: '', phone: h.uniquePhone() });
  expect(noName.status).toBe(400);
  expect(noName.body.message).toMatch(/full name/);
  const phone = h.uniquePhone();
  const r = await h.call(fb.idToken, 'POST', '/api/auth/sync', { name: 'Fresh User', phone });
  expect(r.status).toBe(201);
  expect(r.body.created).toBe(true);
  const me = await h.call(fb.idToken, 'GET', '/api/auth/me');
  expect(me.status).toBe(200);
  expect(me.body.user.email).toBe(email);
  S.fresh = { email, phone };
});

test('TC-28 [ACC] Log in with the correct email and password; Home opens', async () => {
  const login = await h.fbSignIn(S.fresh.email, h.PASSWORD);
  expect(login.ok).toBe(true);
  const sync = await h.call(login.idToken, 'POST', '/api/auth/sync', {});
  expect(sync.status).toBe(200);
  expect(sync.body.created).toBe(false);
  const home = await h.call(login.idToken, 'GET', '/api/dashboard');
  expect(home.status).toBe(200);
});

test('TC-29 [ACC] Log in with a wrong password shows an error and no access is given', async () => {
  const login = await h.fbSignIn(S.fresh.email, 'Wrong-Password-1');
  expect(login.ok).toBe(false);
  expect(String(login.error)).toMatch(/INVALID|PASSWORD/);
  const noAccess = await h.call('not-a-real-token', 'GET', '/api/dashboard');
  expect(noAccess.status).toBe(401);
  expect(noAccess.body.message).toMatch(/Session expired|log in/i);
  const noToken = await h.call(null, 'GET', '/api/dashboard');
  expect(noToken.status).toBe(401);
});
