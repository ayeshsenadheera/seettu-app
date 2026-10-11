// Helpers: Firebase sign-up / sign-in over Firebase's REST API, and a small API caller.
//
// AUTH_MODE=firebase (default) -> real Firebase accounts, needs FIREBASE_API_KEY.
// AUTH_MODE=stub               -> only for a server whose token check is stubbed (used to check these tests offline).
const { request } = require('@playwright/test');

const MODE = process.env.AUTH_MODE || 'firebase';
const KEY = process.env.FIREBASE_API_KEY || '';
const PASSWORD = 'Test@12345';
const FB = 'https://identitytoolkit.googleapis.com/v1/accounts';

const RUN = Date.now().toString(36);
let seq = 0;
const stubUsers = new Map();
const created = []; // Firebase users created by this run (removed again in cleanup)

function uniquePhone() {
  seq += 1;
  const a = String(Date.now() % 1000000).padStart(6, '0');
  return '07' + a + String(seq).padStart(2, '0'); // 10 digits, e.g. 0771234501
}
const uniqueEmail = (label) => `pwtest.${RUN}.${label}@example.com`;

let ctx;
async function context() {
  if (!ctx) ctx = await request.newContext({ baseURL: process.env.API_URL || 'http://localhost:5000' });
  return ctx;
}
async function dispose() { if (ctx) { await ctx.dispose(); ctx = null; } }

// ---- Firebase (REST) ----
async function fbSignUp(email, password = PASSWORD) {
  if (MODE === 'stub') {
    const uid = email.split('@')[0];
    stubUsers.set(email, { password, uid });
    created.push({ idToken: `${uid}|${email}` });
    return { idToken: `${uid}|${email}`, uid };
  }
  if (!KEY) throw new Error('FIREBASE_API_KEY is missing. Copy .env.example to .env and set it.');
  const r = await (await context()).post(`${FB}:signUp?key=${KEY}`, { data: { email, password, returnSecureToken: true } });
  const j = await r.json();
  if (!r.ok()) throw new Error(`Firebase sign-up failed: ${j.error && j.error.message}`);
  created.push({ idToken: j.idToken });
  return { idToken: j.idToken, uid: j.localId };
}

async function fbSignIn(email, password) {
  if (MODE === 'stub') {
    const u = stubUsers.get(email);
    if (!u || u.password !== password) return { ok: false, error: 'INVALID_LOGIN_CREDENTIALS' };
    return { ok: true, idToken: `${u.uid}|${email}`, uid: u.uid };
  }
  const r = await (await context()).post(`${FB}:signInWithPassword?key=${KEY}`, { data: { email, password, returnSecureToken: true } });
  const j = await r.json();
  if (!r.ok()) return { ok: false, error: j.error && j.error.message };
  return { ok: true, idToken: j.idToken, uid: j.localId };
}

async function cleanupFirebase() {
  if (MODE === 'stub') return;
  for (const u of created) {
    try { await (await context()).post(`${FB}:delete?key=${KEY}`, { data: { idToken: u.idToken } }); } catch (e) { /* ignore */ }
  }
}

// ---- Seettu API ----
async function call(token, method, url, data) {
  const c = await context();
  const opts = { method, headers: token ? { Authorization: `Bearer ${token}` } : {} };
  if (data !== undefined) opts.data = data;
  const r = await c.fetch(url, opts);
  let body = null;
  try { body = await r.json(); } catch (e) { body = null; }
  return { status: r.status(), body };
}

// Creates a Firebase account and the matching profile on the server (what the app does at "Create account").
async function makeUser(label, name, { phone, email } = {}) {
  const u = { label, name, phone: phone || uniquePhone(), email: email || uniqueEmail(label), password: PASSWORD };
  const fb = await fbSignUp(u.email, u.password);
  u.token = fb.idToken; u.uid = fb.uid;
  const r = await call(u.token, 'POST', '/api/auth/sync', { name: u.name, phone: u.phone });
  if (r.status !== 201) throw new Error(`Profile creation failed for ${label}: ${r.status} ${JSON.stringify(r.body)}`);
  return u;
}

module.exports = { MODE, PASSWORD, RUN, uniquePhone, uniqueEmail, context, dispose, fbSignUp, fbSignIn, cleanupFirebase, call, makeUser };
