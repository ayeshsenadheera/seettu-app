const { Schema, model } = require('mongoose');

module.exports = model('Notification', new Schema({
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  group: { type: Schema.Types.ObjectId, ref: 'Group', required: true },
  memberId: { type: Schema.Types.ObjectId, required: true },
  memberName: String,
  message: String,
  cycle: String,
  deliveryStatus: { type: String, enum: ['Recorded', 'Sent', 'Failed'], default: 'Recorded' },
}, { timestamps: true }));
