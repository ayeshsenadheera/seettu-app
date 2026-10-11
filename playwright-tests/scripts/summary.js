// Prints one line per test case from results/results.json, ready to copy into the report (section 8).
const fs = require('fs');
const path = require('path');
const file = path.join(__dirname, '..', 'results', 'results.json');
if (!fs.existsSync(file)) { console.error('No results yet. Run "npm test" first.'); process.exit(1); }
const json = JSON.parse(fs.readFileSync(file, 'utf8'));
const rows = [];
(function walk(suites) {
  for (const s of suites || []) {
    for (const spec of s.specs || []) {
      const r = (spec.tests[0].results || []).slice(-1)[0] || {};
      const status = r.status === 'passed' ? 'Pass' : r.status === 'skipped' ? 'Not run' : 'FAIL';
      rows.push({ id: (spec.title.match(/^TC-\d+/) || [''])[0], status, title: spec.title.replace(/^TC-\d+\s*/, ''), ms: r.duration });
    }
    walk(s.suites);
  }
})(json.suites);
rows.sort((a, b) => a.id.localeCompare(b.id));
const pad = (t, n) => String(t).padEnd(n);
console.log(`${pad('ID', 7)}${pad('Result', 9)}Test`);
rows.forEach((r) => console.log(`${pad(r.id, 7)}${pad(r.status, 9)}${r.title}`));
const pass = rows.filter((r) => r.status === 'Pass').length;
console.log(`\n${pass} of ${rows.length} test cases passed. Run date: ${new Date(json.stats.startTime).toLocaleString()}`);
process.exitCode = pass === rows.length ? 0 : 1;
