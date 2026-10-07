// Contribution cycles are monthly ("YYYY-MM"). Due day = start-date day (max 28).
const DAY = 86400000;
const GRACE_DAYS = 7;

const startOfDay = (d) => { const x = new Date(d); x.setHours(0, 0, 0, 0); return x; };
const monthKey = (d) => { const x = new Date(d); return `${x.getFullYear()}-${String(x.getMonth() + 1).padStart(2, '0')}`; };
const nextKey = (key) => { const [y, m] = key.split('-').map(Number); return monthKey(new Date(y, m, 1)); };

function dueDate(group, key) {
  const [y, m] = key.split('-').map(Number);
  return new Date(y, m - 1, Math.min(new Date(group.startDate).getDate(), 28));
}

function monthsUpTo(group, today = new Date()) {
  const out = [];
  let key = monthKey(group.startDate);
  const start = new Date(group.startDate);
  const last = monthKey(new Date(start.getFullYear(), start.getMonth() + Math.max(1, group.memberLimit || group.members.length) - 1, 1));
  const end = [monthKey(today), last].sort()[0];
  if (key > end) return out;
  for (;;) { out.push(key); if (key >= end) break; key = nextKey(key); }
  return out;
}

// Paid | Pending | Late (within 7 days grace) | Missed | N/A (member had not joined yet)
function statusFor(group, payments, member, key, today = new Date()) {
  const from = monthKey(new Date(Math.max(new Date(member.joinedAt || group.startDate), new Date(group.startDate))));
  if (key < from) return 'N/A';
  const paid = payments.find((p) => String(p.memberId) === String(member._id) && p.month === key);
  if (paid && paid.amount >= group.contribution) return 'Paid';
  const t = startOfDay(today).getTime();
  const due = dueDate(group, key).getTime();
  if (t <= due) return 'Pending';
  if (t <= due + (group.policy?.graceDays ?? GRACE_DAYS) * DAY) return 'Late';
  return 'Missed';
}

function outstandingFor(group, payments, today = new Date()) {
  const out = [];
  const t = startOfDay(today);
  for (const key of monthsUpTo(group, today)) {
    for (const m of group.members) {
      if (m.status === 'Inactive') continue;
      const st = statusFor(group, payments, m, key, today);
      if (st === 'Late' || st === 'Missed') {
        const due = dueDate(group, key);
        out.push({
          groupId: String(group._id), groupName: group.name, memberId: String(m._id), memberName: m.name,
          month: key, dueDate: due, amount: Math.max(0, group.contribution - (payments.find((p) => String(p.memberId) === String(m._id) && p.month === key)?.amount || 0)), status: st,
          daysOverdue: Math.floor((t - due) / DAY),
        });
      }
    }
  }
  return out;
}

// Next collection (due) date on or after today
function nextDue(group, today = new Date()) {
  const key = monthKey(today);
  const d = dueDate(group, key);
  return d >= startOfDay(today) ? d : dueDate(group, nextKey(key));
}

function payoutDate(group, position) {
  const s = new Date(group.startDate);
  const d = new Date(s);
  if (group.frequency === 'Weekly') d.setDate(s.getDate() + 7 * (position - 1));
  else {
    d.setDate(1);
    d.setMonth(s.getMonth() + position - 1);
    const lastDay = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
    d.setDate(Math.min(s.getDate(), lastDay));
  }
  return d;
}

// The member entry that belongs to the logged-in user (matched by phone), else null
const myMember = (group, user) => group.members.find((m) => m.phone && m.phone === user.phone) || null;

module.exports = { DAY, GRACE_DAYS, startOfDay, monthKey, nextKey, dueDate, monthsUpTo, statusFor, outstandingFor, nextDue, payoutDate, myMember };
