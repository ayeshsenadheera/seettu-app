require('dotenv').config();
const path = require('path');
const fs = require('fs');
process.env.MONGOMS_DOWNLOAD_DIR = path.resolve(__dirname, '../.mongo-binaries');
const { MongoMemoryServer } = require('mongodb-memory-server');

async function main() {
  const dbPath = path.resolve(__dirname, '../.local-mongo');
  fs.mkdirSync(dbPath, { recursive: true });
  const database = await MongoMemoryServer.create({ instance: { dbPath, storageEngine: 'wiredTiger', dbName: 'seettu' } });
  process.env.MONGO_URI = database.getUri('seettu');
  fs.writeFileSync(path.join(dbPath, 'connection.txt'), process.env.MONGO_URI);
  console.log('Local MongoDB started. Data directory:', dbPath);
  await require('./index').start({ onShutdown: () => database.stop({ doCleanup: false }) });
}
main().catch((error) => { console.error(error.message); process.exitCode = 1; });
