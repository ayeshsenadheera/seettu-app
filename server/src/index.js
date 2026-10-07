require('dotenv').config();
process.env.TZ = process.env.TZ || 'Asia/Colombo';
const mongoose = require('mongoose');
const { createApp } = require('./app');

async function start({ onShutdown = async () => {} } = {}) {
  await mongoose.connect(process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/seettu', { serverSelectionTimeoutMS: 10000 });
  const port = process.env.PORT || 5000;
  const server = createApp().listen(port, '0.0.0.0', () => console.log(`API running on http://localhost:${port}/api`));
  let stopping = false;
  async function shutdown() {
    if (stopping) return;
    stopping = true;
    server.close(async () => { await mongoose.disconnect(); await onShutdown(); process.exit(0); });
  }
  process.once('SIGINT', shutdown);
  process.once('SIGTERM', shutdown);
  return server;
}

if (require.main === module) start().catch((error) => { console.error('Startup failed:', error.message); process.exitCode = 1; });
module.exports = { start };
