#!/usr/bin/env node
// MedCare+ Consolidated Test Report Generator
// Called by GitHub Actions consolidated-report job.
// Reads artifacts from collected/ and writes final_reports/consolidated_report.html

'use strict';
const fs   = require('fs');
const path = require('path');

const OUT = 'final_reports';
fs.mkdirSync(OUT, { recursive: true });

// ── helpers ──────────────────────────────────────────────────────────────────
function safeRead(f) {
  try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return null; }
}
function pct(p, t) { return t > 0 ? ((p / t) * 100).toFixed(1) : '0.0'; }

// ── Appium data ───────────────────────────────────────────────────────────────
const appiumRaw    = safeRead('collected/appium/appium_report_data.json') || [];
const appiumTotal  = appiumRaw.length;
const appiumPassed = appiumRaw.filter(r => r.status === 'PASS').length;
const appiumFailed = appiumTotal - appiumPassed;

// ── Selenium data ─────────────────────────────────────────────────────────────
const selRaw   = safeRead('collected/selenium/selenium_report_data.json')
              || safeRead('collected/selenium/selenium_Latest.json') || [];
const selTotal  = selRaw.length;
const selPassed = selRaw.filter(r => r.status === 'PASS').length;
const selFailed = selTotal - selPassed;

// ── Load metrics ──────────────────────────────────────────────────────────────
function loadMetrics(file) {
  const d = safeRead(file);
  if (!d) return null;
  const m = d.raw ? d.raw.metrics : d.metrics;
  if (!m) return null;
  const dur = m.http_req_duration, fail = m.http_req_failed, reqs = m.http_reqs;
  return {
    total   : reqs ? reqs.values.count                       : 'N/A',
    failRate: fail ? (fail.values.rate * 100).toFixed(2)+'%' : 'N/A',
    avg     : dur  ? dur.values.avg.toFixed(1)               : 'N/A',
    p95     : dur  ? dur.values['p(95)'].toFixed(1)          : 'N/A',
    p99     : dur  ? dur.values['p(99)'].toFixed(1)          : 'N/A',
  };
}

const loadTypes  = ['smoke', 'load', 'stress', 'soak'];
const loadIcons  = { smoke:'🔥', load:'⚡', stress:'💥', soak:'⏳' };
const loadColors = { smoke:'#3b82f6', load:'#8b5cf6', stress:'#ef4444', soak:'#f59e0b' };
const loadLabels = { smoke:'Smoke Test', load:'Load Test', stress:'Stress Test', soak:'Soak Test' };

const loadCards = loadTypes.map(t => {
  const m = loadMetrics(`collected/load/load_${t}_summary.json`)
         || loadMetrics(`collected/load/reports/load_${t}_summary.json`);
  const icon  = loadIcons[t];
  const color = loadColors[t];
  const label = loadLabels[t];

  if (!m) {
    return `<div class="load-card" style="border-top:3px solid ${color}">
      <div class="ct">${icon} ${label}</div>
      <p class="nd">No data — test may not have run</p>
    </div>`;
  }

  const fr  = parseFloat(m.failRate);
  const p95 = parseFloat(m.p95);
  const fBadge = !isNaN(fr)  ? `<span class="b ${fr  < 5    ? 'p':'f'}">${m.failRate}</span>`   : `<span class="b n">${m.failRate}</span>`;
  const pBadge = !isNaN(p95) ? `<span class="b ${p95 < 3000 ? 'p':'f'}">${m.p95} ms</span>`     : `<span class="b n">${m.p95}</span>`;

  return `<div class="load-card" style="border-top:3px solid ${color}">
    <div class="ct">${icon} ${label}</div>
    <table class="mt">
      <tr><td>Total Requests</td><td>${m.total}</td></tr>
      <tr><td>Failure Rate</td><td>${fBadge}</td></tr>
      <tr><td>Avg Response</td><td>${m.avg} ms</td></tr>
      <tr><td>p95 Response</td><td>${pBadge}</td></tr>
      <tr><td>p99 Response</td><td>${m.p99} ms</td></tr>
    </table>
  </div>`;
}).join('\n');

// ── Suite breakdown rows ──────────────────────────────────────────────────────
function suiteRows(data, key) {
  const map = {};
  for (const r of data) {
    const s = r[key] || r.suiteName || 'Unknown';
    if (!map[s]) map[s] = { p:0, f:0 };
    r.status === 'PASS' ? map[s].p++ : map[s].f++;
  }
  const entries = Object.entries(map);
  if (!entries.length) return '<tr><td colspan="5" class="nd">No test data collected</td></tr>';
  return entries.map(([s, c]) => {
    const t = c.p + c.f;
    return `<tr>
      <td>${s}</td><td>${t}</td>
      <td><span class="b p">${c.p} &#x2705;</span></td>
      <td><span class="b ${c.f > 0 ? 'f' : 'p'}">${c.f} ${c.f > 0 ? '&#x274C;' : '&#x2705;'}</span></td>
      <td>${pct(c.p, t)}%</td>
    </tr>`;
  }).join('\n');
}

const appSuiteRows = suiteRows(appiumRaw, 'suiteName');
const selSuiteRows = suiteRows(selRaw, 'categoryName');

// ── Grand totals ──────────────────────────────────────────────────────────────
const gT     = appiumTotal + selTotal;
const gP     = appiumPassed + selPassed;
const gF     = appiumFailed + selFailed;
const now    = new Date().toUTCString();
const sha    = (process.env.GITHUB_SHA     || 'local').slice(0, 7);
const branch = process.env.GITHUB_REF_NAME || 'local';
const runId  = process.env.GITHUB_RUN_ID   || '-';

// ── HTML ──────────────────────────────────────────────────────────────────────
const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>MedCare+ Consolidated Test Report</title>
<link rel="preconnect" href="https://fonts.googleapis.com"/>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet"/>
<style>
*{box-sizing:border-box;margin:0;padding:0}
:root{--bg:#09111f;--s:#111827;--bd:#1e2d45;--tx:#e2e8f0;--mu:#64748b;--ps:#10b981;--fl:#ef4444;--wn:#f59e0b}
body{font-family:'Inter',sans-serif;background:var(--bg);color:var(--tx);min-height:100vh}
.hero{background:linear-gradient(135deg,#0d1529,#19093a 55%,#081928);border-bottom:1px solid var(--bd);padding:3rem 2rem 2.5rem;text-align:center;position:relative;overflow:hidden}
.hero::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse 70% 90% at 50% -30%,rgba(99,102,241,.2),transparent);pointer-events:none}
.hero h1{font-size:clamp(1.8rem,4vw,2.8rem);font-weight:800;background:linear-gradient(135deg,#818cf8,#60a5fa,#a78bfa);-webkit-background-clip:text;-webkit-text-fill-color:transparent;margin-bottom:.5rem;position:relative}
.hero p{color:var(--mu);font-size:.9rem;margin-bottom:1.4rem;position:relative}
.pills{display:flex;flex-wrap:wrap;justify-content:center;gap:.5rem;position:relative}
.pill{background:rgba(255,255,255,.05);border:1px solid rgba(255,255,255,.1);border-radius:999px;padding:.3rem .9rem;font-size:.78rem;color:#94a3b8}
.ctr{max-width:1300px;margin:0 auto;padding:2rem 1.5rem}
.sec{font-size:1rem;font-weight:700;letter-spacing:.05em;text-transform:uppercase;color:var(--mu);margin:2.2rem 0 1rem;display:flex;align-items:center;gap:.6rem}
.sec::after{content:'';flex:1;height:1px;background:var(--bd)}
.sg{display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:1rem;margin-bottom:2rem}
.sc{background:var(--s);border:1px solid var(--bd);border-radius:14px;padding:1.3rem;text-align:center;position:relative;overflow:hidden;transition:transform .2s,box-shadow .2s}
.sc:hover{transform:translateY(-3px);box-shadow:0 8px 30px rgba(0,0,0,.4)}
.glow{position:absolute;top:-50%;left:50%;transform:translateX(-50%);width:90%;height:140%;border-radius:50%;filter:blur(45px);opacity:.13;pointer-events:none}
.sc .val{font-size:2.4rem;font-weight:800;line-height:1}
.sc .lbl{font-size:.72rem;color:var(--mu);margin-top:.35rem;font-weight:600;letter-spacing:.05em;text-transform:uppercase}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:1.5rem;margin-bottom:2rem}
@media(max-width:768px){.grid2{grid-template-columns:1fr}}
.panel{background:var(--s);border:1px solid var(--bd);border-radius:14px;padding:1.3rem}
.panel h3{font-size:.95rem;font-weight:700;margin-bottom:1rem}
table.st{width:100%;border-collapse:collapse;font-size:.82rem}
table.st th{text-align:left;color:var(--mu);font-weight:600;border-bottom:1px solid var(--bd);padding:.45rem .3rem;font-size:.72rem;text-transform:uppercase;letter-spacing:.04em}
table.st td{padding:.42rem .3rem;border-bottom:1px solid rgba(255,255,255,.04)}
table.st tr:last-child td{border-bottom:none}
.lgrid{display:grid;grid-template-columns:repeat(auto-fit,minmax(250px,1fr));gap:1.2rem;margin-bottom:2rem}
.load-card{background:var(--s);border:1px solid var(--bd);border-radius:14px;padding:1.3rem}
.ct{font-size:.95rem;font-weight:700;margin-bottom:.9rem}
table.mt{width:100%;border-collapse:collapse;font-size:.82rem}
table.mt tr{border-bottom:1px solid rgba(255,255,255,.04)}
table.mt tr:last-child{border-bottom:none}
table.mt td{padding:.4rem .25rem}
table.mt td:last-child{text-align:right;font-weight:500}
table.mt td:first-child{color:var(--mu)}
.jgrid{display:flex;flex-wrap:wrap;gap:.75rem;margin-bottom:2rem}
.jp{display:flex;align-items:center;gap:.6rem;background:var(--s);border:1px solid var(--bd);border-radius:10px;padding:.65rem 1.1rem;font-size:.84rem;font-weight:600}
.dot{width:9px;height:9px;border-radius:50%;flex-shrink:0}
.dot-p{background:var(--ps)}.dot-f{background:var(--fl)}.dot-w{background:var(--wn)}
.b{display:inline-block;padding:.15rem .55rem;border-radius:5px;font-size:.78rem;font-weight:600}
.p{background:#064e3b;color:#6ee7b7}.f{background:#7f1d1d;color:#fca5a5}.n{background:#1e3a5f;color:#93c5fd}
.nd{color:var(--mu);font-size:.82rem;font-style:italic;padding:.5rem 0;text-align:center}
footer{text-align:center;padding:2rem;color:var(--mu);font-size:.8rem;border-top:1px solid var(--bd);margin-top:1rem}
</style>
</head>
<body>
<div class="hero">
  <h1>&#x1FA7A; MedCare+ Unified Test Report</h1>
  <p>Appium Mobile &nbsp;&middot;&nbsp; Selenium Web &nbsp;&middot;&nbsp; k6 Load Testing</p>
  <div class="pills">
    <span class="pill">&#x1F4C5; ${now}</span>
    <span class="pill">&#x1F500; ${branch}</span>
    <span class="pill">&#x1F516; ${sha}</span>
    <span class="pill">&#x1F3C3; Run #${runId}</span>
  </div>
</div>
<div class="ctr">
  <div class="sec">&#x1F4C8; Grand Summary</div>
  <div class="sg">
    <div class="sc"><div class="glow" style="background:#6366f1"></div><div class="val" style="color:#6366f1">${gT}</div><div class="lbl">Total Tests</div></div>
    <div class="sc"><div class="glow" style="background:#10b981"></div><div class="val" style="color:#10b981">${gP}</div><div class="lbl">Passed</div></div>
    <div class="sc"><div class="glow" style="background:#ef4444"></div><div class="val" style="color:#ef4444">${gF}</div><div class="lbl">Failed</div></div>
    <div class="sc"><div class="glow" style="background:#3b82f6"></div><div class="val" style="color:#3b82f6">${pct(gP,gT)}%</div><div class="lbl">Pass Rate</div></div>
    <div class="sc"><div class="glow" style="background:#a78bfa"></div><div class="val" style="color:#a78bfa">${appiumTotal}</div><div class="lbl">&#x1F4F1; Appium</div></div>
    <div class="sc"><div class="glow" style="background:#22d3ee"></div><div class="val" style="color:#22d3ee">${selTotal}</div><div class="lbl">&#x1F310; Selenium</div></div>
  </div>

  <div class="sec">&#x1F504; Pipeline Job Status</div>
  <div class="jgrid">
    <div class="jp"><div class="dot ${appiumTotal > 0 ? (appiumFailed === 0 ? 'dot-p' : 'dot-w') : 'dot-w'}"></div>
      &#x1F4F1; Appium &mdash; ${appiumTotal > 0 ? appiumPassed+'/'+appiumTotal+' passed' : 'No data'}
    </div>
    <div class="jp"><div class="dot ${selTotal > 0 ? (selFailed === 0 ? 'dot-p' : 'dot-w') : 'dot-w'}"></div>
      &#x1F310; Selenium &mdash; ${selTotal > 0 ? selPassed+'/'+selTotal+' passed' : 'No data'}
    </div>
    <div class="jp"><div class="dot dot-p"></div>&#x26A1; k6 Load &mdash; See Load section below</div>
  </div>

  <div class="sec">&#x1F52C; Test Suite Breakdown</div>
  <div class="grid2">
    <div class="panel"><h3>&#x1F4F1; Appium Mobile Suites</h3>
      <table class="st">
        <thead><tr><th>Suite</th><th>Total</th><th>Passed</th><th>Failed</th><th>Rate</th></tr></thead>
        <tbody>${appSuiteRows}</tbody>
      </table>
    </div>
    <div class="panel"><h3>&#x1F310; Selenium Web Suites</h3>
      <table class="st">
        <thead><tr><th>Suite</th><th>Total</th><th>Passed</th><th>Failed</th><th>Rate</th></tr></thead>
        <tbody>${selSuiteRows}</tbody>
      </table>
    </div>
  </div>

  <div class="sec">&#x26A1; Load Test Results (k6)</div>
  <div class="lgrid">${loadCards}</div>
</div>
<footer>MedCare+ Automated Testing Suite &nbsp;&middot;&nbsp; Appium &middot; Selenium &middot; k6 &nbsp;&middot;&nbsp; GitHub Actions CI/CD</footer>
</body>
</html>`;

const outFile = path.join(OUT, 'consolidated_report.html');
fs.writeFileSync(outFile, html, 'utf8');
console.log('✅ Consolidated report generated:', outFile);

// ── GitHub Actions Step Summary ───────────────────────────────────────────────
const aT = appiumTotal, aP = appiumPassed, aF = appiumFailed;
const sT = selTotal, sP = selPassed, sF = selFailed;
const rate = gT > 0 ? ((gP / gT) * 100).toFixed(1) : '0.0';

const md = `
## 🩺 MedCare+ Unified Test Report

| Suite | Total | ✅ Passed | ❌ Failed | Pass Rate |
|-------|------:|----------:|----------:|----------:|
| 📱 Appium Mobile | ${aT} | ${aP} | ${aF} | ${aT > 0 ? ((aP/aT)*100).toFixed(1) : 0}% |
| 🌐 Selenium Web  | ${sT} | ${sP} | ${sF} | ${sT > 0 ? ((sP/sT)*100).toFixed(1) : 0}% |
| ⚡ k6 Load Tests | — | — | — | See HTML report |
| **Grand Total**  | **${gT}** | **${gP}** | **${gF}** | **${rate}%** |

> 📥 Download the **MedCare-Consolidated-Testing-Report** artifact for the full interactive HTML dashboard.
`;

const sf = process.env.GITHUB_STEP_SUMMARY;
if (sf) {
  fs.appendFileSync(sf, md);
  console.log('✅ GitHub Actions Step Summary written');
} else {
  console.log(md);
}
