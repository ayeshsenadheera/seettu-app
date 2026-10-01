const router = require('express').Router();
const auth = require('../middleware/auth');
const { HttpError, wrap } = require('../utils/http');

router.use(auth);
router.get('/', wrap(async (req, res) => res.json({ settings: req.user.settings })));

router.put('/', wrap(async (req, res) => {
  const { language, textSize, reminder } = req.body;
  const s = req.user.settings;
  if (language !== undefined) {
    if (!['English', 'Sinhala', 'Tamil'].includes(language)) throw new HttpError(400, 'Unknown language.');
    s.language = language;
  }
  if (textSize !== undefined) {
    if (!['Small', 'Medium', 'Large', 'Extra Large'].includes(textSize)) throw new HttpError(400, 'Unknown text size.');
    s.textSize = textSize;
  }
  if (reminder) {
    if (reminder.enabled !== undefined) s.reminder.enabled = !!reminder.enabled;
    if (reminder.daysBefore !== undefined) {
      if (![1, 2, 3, 7].includes(Number(reminder.daysBefore))) throw new HttpError(400, 'Choose 1, 2, 3 or 7 days.');
      s.reminder.daysBefore = Number(reminder.daysBefore);
    }
    if (reminder.method !== undefined) {
      if (!['Push', 'SMS', 'WhatsApp'].includes(reminder.method)) throw new HttpError(400, 'Unknown notification method.');
      s.reminder.method = reminder.method;
    }
  }
  await req.user.save();
  res.json({ settings: req.user.settings });
}));

module.exports = router;
