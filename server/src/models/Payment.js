
const { Schema, model } = require('mongoose');

const paymentSchema = new Schema({
  owner: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  group: {
    type: Schema.Types.ObjectId,
    ref: 'Group',
    required: true,
    index: true,
  },
  memberId: {
    type: Schema.Types.ObjectId,
    required: true,
  },
  memberName: {
    type: String,
    required: true,
  },
  amount: {
    type: Number,
    required: true,
    min: 0.01,
  },
  month: {
    type: String,
    required: true,
    match: /^\d{4}-(0[1-9]|1[0-2])$/,
  },
  date: {
    type: Date,
    required: true,
  },
  method: {
    type: String,
    enum: ['Cash', 'Bank Transfer', 'Other'],
    default: 'Cash',
  },
  reference: {
    type: String,
    default: '',
    trim: true,
  },
}, { timestamps: true });

// Non-unique index: multiple installments per member/cycle.
paymentSchema.index({ group: 1, memberId: 1, month: 1 });

module.exports = model('Payment', paymentSchema);
