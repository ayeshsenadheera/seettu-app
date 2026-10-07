const { Schema, model } = require('mongoose');

const userSchema = new Schema({
  firebaseUid: { type: String, required: true, unique: true, index: true },
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, lowercase: true, trim: true },
  phone: { type: String, required: true },
  role: { type: String, enum: ['Organizer', 'Participant'], default: 'Organizer' },
  settings: {
    sharePayoutUpdates: { type: Boolean, default: false },
    language: { type: String, enum: ['English', 'Sinhala', 'Tamil'], default: 'English' },
    textSize: { type: String, enum: ['Small', 'Medium', 'Large', 'Extra Large'], default: 'Medium' },
    reminder: {
      enabled: { type: Boolean, default: true },
      daysBefore: { type: Number, default: 3 },
      method: { type: String, enum: ['Push', 'SMS', 'WhatsApp'], default: 'Push' },
    },
  },
}, { timestamps: true });

module.exports = model('User', userSchema);
