// Playwright configuration for the Seettu API tests.
// The tests call the running Express server (the same one the Flutter app uses).
const { defineConfig } = require('@playwright/test');
const path = require('path');
require('fs').existsSync(path.join(__dirname, '.env')) &&
  require('fs').readFileSync(path.join(__dirname, '.env'), 'utf8').split(/\r?\n/).forEach((line) => {
    const m = line.match(/^\s*([A-Z_]+)\s*=\s*(.*?)\s*$/);
    if (m && !line.trim().startsWith('#') && process.env[m[1]] === undefined) process.env[m[1]] = m[2];
  });

module.exports = defineConfig({
  testDir: './tests',
  timeout: 60_000,
  workers: 1,                 // tests share data and run in order TC-01 ... TC-29
  fullyParallel: false,
  reporter: [
    ['list'],
    ['html', { open: 'never', outputFolder: 'playwright-report' }],
    ['json', { outputFile: 'results/results.json' }],
  ],
  use: {
    baseURL: process.env.API_URL || 'http://localhost:5000',
  },
});
