const { Schema, model } = require('mongoose');

const paymentSchema = new Schema({
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  group: { type: Schema.Types.ObjectId, ref: 'Group', required: true, index: true },
  memberId: { type: Schema.Types.ObjectId, required: true },
  memberName: { type: String, required: true },
  amount: { type: Number, required: true },
  month: { type: String, required: true }, // "YYYY-MM" cycle
  date: { type: Date, required: true },
  method: { type: String, enum: ['Cash', 'Bank Transfer', 'Other'], default: 'Cash' },
  reference: { type: String, default: '' },
}, { timestamps: true });

// One payment per member per cycle
paymentSchema.index({ group: 1, memberId: 1, month: 1 }, { unique: true });

module.exports = model('Payment', paymentSchema);
