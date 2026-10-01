// Fills the database with demo data, and creates a matching Firebase login.
// Needs server/serviceAccountKey.json in place first (see README). Run: npm run seed
// Login afterwards, in the Flutter app:  nimal@example.com / password123
require('dotenv').config();
const mongoose = require('mongoose');
const admin = require('./utils/firebase');
const User = require('./models/User');
const Group = require('./models/Group');
const Payment = require('./models/Payment');
const { monthKey, nextKey, dueDate } = require('./utils/cycles');

const EMAIL = 'nimal@example.com';
const PASSWORD = 'password123';
const NAMES = ['Amal Fernando', 'Alen Makrem', 'Glenn Phillips', 'Jos Butler', 'Samantha Perera',
  'Kasun Silva', 'Dilani Wickrama', 'Ruwan Jayasinghe', 'Nadeesha Fernando', 'Chamara Gunawardena'];

async function getOrCreateFirebaseUser() {
  try { return await admin.auth().getUserByEmail(EMAIL); }
  catch (e) { return admin.auth().createUser({ email: EMAIL, password: PASSWORD, displayName: 'Nimal Perera' }); }
}

async function main() {
  await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/seettu');
  await Promise.all([User.deleteMany({}), Group.deleteMany({}), Payment.deleteMany({})]);

  const fbUser = await getOrCreateFirebaseUser();
  const user = await User.create({ firebaseUid: fbUser.uid, name: 'Nimal Perera', email: EMAIL, phone: '0771234567' });

  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth() - 2, 25);
  const defs = [
    { name: 'Friend Seettu', contribution: 10000, frequency: 'Monthly', limit: 10 },
    { name: 'Family Seettu', contribution: 25000, frequency: 'Monthly', limit: 8 },
    { name: 'Friends Circle', contribution: 12000, frequency: 'Monthly', limit: 8 },
    { name: 'Office Group', contribution: 40000, frequency: 'Monthly', limit: 6 },
  ];

  for (const [gi, d] of defs.entries()) {
    const members = [{ name: user.name, phone: user.phone, email: user.email, position: 1, joinedAt: start }];
    NAMES.slice(0, d.limit - 1).forEach((n, i) => members.push({
      name: n, phone: `07${gi}${String(1000000 + i * 137).slice(-7)}`.slice(0, 10), email: '', position: i + 2, joinedAt: start,
    }));
    const g = await Group.create({
      owner: user._id, name: d.name, contribution: d.contribution, frequency: d.frequency, memberLimit: d.limit,
      startDate: start, description: `${d.name} savings circle`, members,
    });

    const k1 = monthKey(start), k2 = nextKey(k1), k3 = nextKey(k2);
    const rows = [];
    g.members.forEach((m, i) => {
      const pay = (key, on) => rows.push({
        owner: user._id, group: g._id, memberId: m._id, memberName: m.name, amount: g.contribution,
        month: key, date: new Date(dueDate(g, key).getTime() - on * 86400000), method: i % 2 ? 'Bank Transfer' : 'Cash',
      });
      pay(k1, 1);
      if (i % 4 !== 3) pay(k2, 2); // every 4th member misses month 2
      if (i % 2 === 0 && gi === 0) pay(k3, 1);
    });
    await Payment.insertMany(rows);
  }
  console.log(`Seeded. Login in the app: ${EMAIL} / ${PASSWORD}`);
  await mongoose.disconnect();
}
main().catch((e) => { console.error(e); process.exit(1); });
