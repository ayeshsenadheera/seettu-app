// Adds a sample pool for an already-synced Firebase account without deleting data.
require('dotenv').config();
process.env.TZ = 'Asia/Colombo';
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const User = require('./models/User');
const Group = require('./models/Group');
const Payment = require('./models/Payment');
const Payout = require('./models/Payout');
const { monthKey, monthsUpTo, dueDate, payoutDate } = require('./utils/cycles');

async function main() {
  const firebaseUid = process.argv[2] || process.env.SEED_FIREBASE_UID;
  if (!firebaseUid) throw new Error('Usage: npm run seed:ui -- YOUR_FIREBASE_UID [--local]');
  const localConnection = path.join(__dirname, '../.local-mongo/connection.txt');
  const uri = process.argv.includes('--local') && fs.existsSync(localConnection)
    ? fs.readFileSync(localConnection, 'utf8').trim()
    : process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/seettu';
  await mongoose.connect(uri);
  const user = await User.findOne({ firebaseUid });
  if (!user) throw new Error('Sign up in the connected app first so your profile is synced.');
  if (await Group.exists({ owner: user._id, name: 'Community Seettu' })) {
    console.log('Community Seettu already exists; no existing records changed.');
    return;
  }
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth() - 3, 15);
  const names = [user.name, 'Alice Cameron', 'Kiara Jaxson', 'Kevin Dixon', 'Rose Peterkin', 'Victor Hussain'];
  const group = await Group.create({ owner: user._id, name: 'Community Seettu', contribution: 25000, memberLimit: 6,
    startDate: start, policy: { graceDays: 7, lateFeePerDay: 50, maxDiscountPercent: 35 },
    members: names.map((name, index) => ({ name, phone: index ? `077111220${index}` : user.phone,
      firebaseUid: index ? '' : user.firebaseUid, position: index + 1, joinedAt: start })) });
  const keys = monthsUpTo(group, now);
  const latestDue = keys.filter((month) => dueDate(group, month) < now).at(-1);
  const payments = [];
  for (const [index, member] of group.members.entries()) for (const key of keys) {
    if (dueDate(group, key) > now || (key === latestDue && index < 3)) continue;
    payments.push({ owner: user._id, group: group._id, memberId: member._id, memberName: member.name,
      amount: group.contribution, month: key, date: dueDate(group, key), reference: `DEMO-${index}-${key}` });
  }
  if (payments.length) await Payment.insertMany(payments);
  await Payout.insertMany(group.members.slice(0, 3).map((member) => ({ group: group._id, memberId: member._id,
    memberName: member.name, position: member.position, amount: group.contribution * group.members.length,
    status: 'Paid', reference: `DEMO-PAYOUT-${member.position}`, recordedBy: user._id, paidAt: payoutDate(group, member.position) })));
  console.log('Created Community Seettu with sample contributions and payout records. Refresh your app.');
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; }).finally(() => mongoose.disconnect());
