// Accepts 0771234567, 077 123 4567 or +94771234567 -> "0771234567" (or null)
function normalizePhone(input = '') {
  const digits = String(input).replace(/[\s-]/g, '');
  const local = /^\+94\d{9}$/.test(digits) ? '0' + digits.slice(3) : digits;
  return /^0\d{9}$/.test(local) ? local : null;
}
module.exports = { normalizePhone };
