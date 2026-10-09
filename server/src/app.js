const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const auth = require('./middleware/auth');

function createApp({ authenticate = auth } = {}) {
  const app = express();
  app.disable('x-powered-by');
  app.use(cors());
  app.use(express.json({ limit: '100kb' }));
  app.get('/api/health', (req, res) => res.json({ ok: true, database: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected' }));
  app.use('/api/ui', require('./routes/sixScreens')(authenticate));
  app.use('/api/auth', require('./routes/auth'));
  app.use('/api/settings', require('./routes/settings'));
  app.use('/api/dashboard', require('./routes/dashboard'));
  app.use('/api/groups', require('./routes/groups'));
  app.use('/api/payments', require('./routes/payments'));
  app.use('/api/trusted', require('./routes/trusted'));
  app.use((req, res) => res.status(404).json({ message: 'Not found' }));
  app.use((err, req, res, next) => {
    if (err.type === 'entity.parse.failed') return res.status(400).json({ message: 'Invalid JSON request body.' });
    if (err.name === 'CastError') return res.status(400).json({ message: 'Invalid field value or ID.' });
    if (err.name === 'ValidationError') return res.status(400).json({ message: 'Invalid data.', errors: Object.values(err.errors).map((e) => e.message) });
    if (err.code === 11000) return res.status(409).json({ message: 'This record already exists.' });
    if (err.status) return res.status(err.status).json({ message: err.message });
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  });
  return app;
}

module.exports = { createApp };
