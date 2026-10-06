const { Schema, model } = require('mongoose');

const schema = new Schema({
  group: { type: Schema.Types.ObjectId, ref: 'Group', required: true },
  memberId: { type: Schema.Types.ObjectId, required: true },
  memberName: { type: String, required: true },
  position: { type: Number, required: true, min: 1 },
  amount: { type: Number, required: true, min: 0 },
  status: { type: String, enum: ['Processing', 'Paid'], required: true },
  method: { type: String, enum: ['Cash', 'Bank Transfer', 'Other'], default: 'Bank Transfer' },
  reference: { type: String, required: true, maxlength: 120 },
  recordedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  paidAt: { type: Date, default: null },
}, { timestamps: true });
schema.index({ group: 1, memberId: 1 }, { unique: true });
schema.index({ group: 1, position: 1 }, { unique: true });
module.exports = model('Payout', schema);
