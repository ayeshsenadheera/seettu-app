const { Schema, model } = require('mongoose');

const memberSchema = new Schema({
  name: { type: String, required: true, trim: true },
  phone: { type: String, required: true },
  email: { type: String, default: '', trim: true },
  status: { type: String, enum: ['Active', 'Inactive'], default: 'Active' },
  position: { type: Number, required: true },
  joinedAt: { type: Date, default: Date.now },
});

const groupSchema = new Schema({
  owner: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  name: { type: String, required: true, trim: true },
  contribution: { type: Number, required: true },
  frequency: { type: String, enum: ['Weekly', 'Monthly'], default: 'Monthly' },
  memberLimit: { type: Number, required: true },
  startDate: { type: Date, required: true },
  description: { type: String, default: '' },
  members: [memberSchema],
}, { timestamps: true });

module.exports = model('Group', groupSchema);
