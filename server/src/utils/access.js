// Who can see / change what.
//   Organizer = the user who created the group (group.owner)  -> full control
//   Member    = a person in group.members linked to an account (firebaseUid) -> view + own data
//   Trusted   = invited through the Trusted feature             -> view-only (see routes/trusted.js)
const mongoose = require('mongoose');
const Group = require('../models/Group');
const User = require('../models/User');
const { HttpError } = require('./http');

const escapeRe = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const isOwner = (g, user) => String(g.owner) === String(user._id);
const asMember = (g, user) => g.members.find((m) => m.firebaseUid && m.firebaseUid === user.firebaseUid && m.status !== 'Inactive') || null;
const roleOf = (g, user) => (isOwner(g, user) ? 'Organizer' : asMember(g, user) ? 'Member' : null);
const canManage = (g, user) => isOwner(g, user);

// Loose Mongo filter (owner, or listed as a member with this account). Inactive members are
// removed afterwards by accessibleGroups / loadGroup, so the rule lives in one place (roleOf).
const groupFilter = (user) => ({ $or: [{ owner: user._id }, { 'members.firebaseUid': user.firebaseUid }] });

// Every group this user may open, oldest first
async function accessibleGroups(user) {
  const list = await Group.find(groupFilter(user)).sort({ createdAt: 1 });
  return list.filter((g) => roleOf(g, user));
}

// Connect member entries (added by an organizer with a phone / email) to this account,
// so the group appears for them as soon as they sign up or log in.
async function linkMemberships(user) {
  const conds = [{ 'members.phone': user.phone }];
  if (user.email) conds.push({ 'members.email': new RegExp(`^${escapeRe(user.email)}$`, 'i') });
  const groups = await Group.find({ $or: conds });
  for (const g of groups) {
    let changed = false;
    for (const m of g.members) {
      const mine = m.phone === user.phone || (user.email && m.email && m.email.toLowerCase() === user.email.toLowerCase());
      if (mine && !m.firebaseUid) { m.firebaseUid = user.firebaseUid; changed = true; }
    }
    if (changed) await g.save();
  }
}

// Link one member entry to an account that already exists (phone or e-mail match)
async function linkToExistingUser(member) {
  const or = [{ phone: member.phone }];
  if (member.email) or.push({ email: member.email.toLowerCase() });
  const u = await User.findOne({ $or: or });
  member.firebaseUid = u ? u.firebaseUid : '';
  return !!u;
}

// Open a group the user may access. manage=true -> organizer only (403 for members).
async function loadGroup(user, id, { manage = false } = {}) {
  if (!id) throw new HttpError(400, 'Choose a group.');
  if (!mongoose.isValidObjectId(id)) throw new HttpError(404, 'Group not found.');
  const g = await Group.findOne({ _id: id, ...groupFilter(user) });
  if (!g || !roleOf(g, user)) throw new HttpError(404, 'Group not found.');
  if (manage && !canManage(g, user)) throw new HttpError(403, 'Only the group organizer can do this.');
  return g;
}

module.exports = { isOwner, asMember, roleOf, canManage, groupFilter, accessibleGroups, linkMemberships, linkToExistingUser, loadGroup };
