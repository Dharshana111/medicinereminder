#!/usr/bin/env node
// MedCare+ Load Test Report Generator
// Converts k6 JSON summary files into a rich HTML report

const fs   = require('fs');
const path = require('path');

const REPORTS_DIR = path.join(__dirname, '..', 'reports');

// Read all k6 JSON summaries
function readSummaries() {
  const files = fs.readdirSync(REPORTS_DIR)
    .filter(f => f.startsWith('load_') && f.endsWith('_summary.json'));

  return files.map(file => {
    try {
      const raw  = fs.readFileSync(path.join(REPORTS_DIR, file), 'utf8');
      const data = JSON.parse(raw);
      return { file, data };
    } catch (e) {
      return { file, data: null, error: e.message };
    }
  });
}

function extractMetrics(data) {
  if (!data) return null;
  // Handle wrapped stress report
  const metrics = data.raw ? data.raw.metrics : data.metrics;
  if (!metrics) return null;

  const dur     = metrics.http_req_duration;
  const failed  = metrics.http_req_failed;
  const reqs    = metrics.http_reqs;
  const vus     = metrics.vus_max;

  return {
    totalRequests : reqs   ? reqs.values.count               : 'N/A',
    failureRate   : failed ? (failed.values.rate * 100).toFixed(2) + '%' : 'N/A',
    avgMs         : dur    ? dur.values.avg.toFixed(1)        : 'N/A',
    medianMs      : dur    ? dur.values['med'].toFixed(1)     : 'N/A',
    p90Ms         : dur    ? dur.values['p(90)'].toFixed(1)   : 'N/A',
    p95Ms         : dur    ? dur.values['p(95)'].toFixed(1)   : 'N/A',
    p99Ms         : dur    ? dur.values['p(99)'].toFixed(1)   : 'N/A',
    maxMs         : dur    ? dur.values.max.toFixed(1)        : 'N/A',
    maxVUs        : vus    ? vus.values.max                   : 'N/A',
  };
}

function testTypeLabel(file) {
  if (file.includes('smoke'))  return { label: 'Smoke Test',    icon: '🔥', color: '#3b82f6' };
  if (file.includes('load'))   return { label: 'Load Test',     icon: '⚡', color: '#8b5cf6' };
  if (file.includes('stress')) return { label: 'Stress Test',   icon: '💥', color: '#ef4444' };
  if (file.includes('soak'))   return { label: 'Soak Test',     icon: '⏳', color: '#f59e0b' };
  return { label: 'Unknown',   icon: '📊', color: '#6b7280' };
}

function statusBadge(value, threshold, lowIsGood = true) {
  const num = parseFloat(value);
  if (isNaN(num)) return `<span class="badge neutral">${value}</span>`;
  const pass = lowIsGood ? num < threshold : num >= threshold;
  return `<span class="badge ${pass ? 'pass' : 'fail'}">${value}</span>`;
}

function generateHTML(summaries) {
  const cards = summaries.map(({ file, data, error }) => {
    const { label, icon, color } = testTypeLabel(file);
    if (error || !data) {
      return `
        <div class="card" style="--accent:${color}">
          <div class="card-header"><span class="icon">${icon}</span>${label}</div>
          <p class="error-msg">⚠ Could not parse report: ${error || 'No data'}</p>
        </div>`;
    }
    const m = extractMetrics(data);
    if (!m) {
      return `
        <div class="card" style="--accent:${color}">
          <div class="card-header"><span class="icon">${icon}</span>${label}</div>
          <p class="error-msg">⚠ No metrics found in report</p>
        </div>`;
    }

    return `
      <div class="card" style="--accent:${color}">
        <div class="card-header"><span class="icon">${icon}</span>${label}</div>
        <table class="metrics-table">
          <tr><td>Total Requests</td><td>${m.totalRequests}</td></tr>
          <tr><td>Failure Rate</td><td>${statusBadge(m.failureRate, 5)}</td></tr>
          <tr><td>Avg Response</td><td>${statusBadge(m.avgMs, 1000)} ms</td></tr>
          <tr><td>Median</td><td>${m.medianMs} ms</td></tr>
          <tr><td>p90 Response</td><td>${statusBadge(m.p90Ms, 2000)} ms</td></tr>
          <tr><td>p95 Response</td><td>${statusBadge(m.p95Ms, 3000)} ms</td></tr>
          <tr><td>p99 Response</td><td>${statusBadge(m.p99Ms, 5000)} ms</td></tr>
          <tr><td>Max Response</td><td>${m.maxMs} ms</td></tr>
          <tr><td>Max VUs</td><td>${m.maxVUs}</td></tr>
        </table>
      </div>`;
  }).join('\n');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>MedCare+ Load Test Report</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:'Inter',sans-serif;background:#0f172a;color:#e2e8f0;min-height:100vh;padding:2rem}
    header{text-align:center;margin-bottom:2.5rem}
    header h1{font-size:2rem;font-weight:700;background:linear-gradient(135deg,#60a5fa,#a78bfa);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:.5rem}
    header p{color:#94a3b8;font-size:.95rem}
    .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:1.5rem;max-width:1200px;margin:0 auto}
    .card{background:#1e293b;border-radius:12px;border:1px solid rgba(255,255,255,.07);padding:1.5rem;border-top:3px solid var(--accent)}
    .card-header{font-size:1.1rem;font-weight:600;margin-bottom:1rem;display:flex;align-items:center;gap:.5rem;color:#f1f5f9}
    .icon{font-size:1.3rem}
    .metrics-table{width:100%;border-collapse:collapse}
    .metrics-table tr{border-bottom:1px solid rgba(255,255,255,.05)}
    .metrics-table tr:last-child{border-bottom:none}
    .metrics-table td{padding:.45rem .25rem;font-size:.875rem}
    .metrics-table td:first-child{color:#94a3b8}
    .metrics-table td:last-child{text-align:right;font-weight:500;color:#e2e8f0}
    .badge{display:inline-block;padding:.15rem .5rem;border-radius:4px;font-size:.8rem;font-weight:600}
    .badge.pass{background:#166534;color:#86efac}
    .badge.fail{background:#7f1d1d;color:#fca5a5}
    .badge.neutral{background:#1e3a5f;color:#93c5fd}
    .error-msg{color:#f87171;font-size:.875rem;padding:.5rem 0}
    footer{text-align:center;margin-top:3rem;color:#475569;font-size:.8rem}
  </style>
</head>
<body>
  <header>
    <h1>⚡ MedCare+ Load Test Report</h1>
    <p>Generated: ${new Date().toISOString().replace('T', ' ').slice(0, 19)} UTC</p>
  </header>
  <div class="grid">
    ${cards || '<p style="text-align:center;color:#94a3b8">No load test reports found. Run k6 tests first.</p>'}
  </div>
  <footer>MedCare+ Automated Testing Suite · k6 Load Testing</footer>
</body>
</html>`;
}

// ── Main ─────────────────────────────────────────────────────────────────────
if (!fs.existsSync(REPORTS_DIR)) {
  fs.mkdirSync(REPORTS_DIR, { recursive: true });
}

const summaries = readSummaries();
const html      = generateHTML(summaries);
const outFile   = path.join(REPORTS_DIR, 'load_test_report.html');

fs.writeFileSync(outFile, html, 'utf8');
console.log(`✨ Load test HTML report generated: ${outFile}`);
