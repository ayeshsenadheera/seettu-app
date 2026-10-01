const { Schema, model } = require('mongoose');

module.exports = model('Trusted', new Schema({
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  guest: { type: Schema.Types.ObjectId, ref: 'User', default: null },
  name: { type: String, required: true },
  phone: { type: String, required: true },
  relationship: { type: String, enum: ['Family', 'Friend', 'Other'], default: 'Family' },
  share: [{ type: String, enum: ['payoutDate', 'paymentStatus', 'amount'] }],
  inviteCode: { type: String, required: true, index: true },
  status: { type: String, enum: ['Pending', 'Active'], default: 'Pending' },
  expiresAt: { type: Date, default: null },
}, { timestamps: true }));
