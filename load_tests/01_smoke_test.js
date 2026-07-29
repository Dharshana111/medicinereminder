// MedCare+ Load Test: k6 — Smoke Test (baseline check)
// Runs 1 VU for 30s to verify the app responds at all

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ── Custom Metrics ───────────────────────────────────────────────────────────
export const errorRate     = new Rate('errors');
export const pageLoadTime  = new Trend('page_load_time', true);
export const requestCount  = new Counter('total_requests');

// ── Test Options ─────────────────────────────────────────────────────────────
export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<3000'],   // 95% of requests < 3s
    http_req_failed:   ['rate<0.05'],    // < 5% failure rate
    errors:            ['rate<0.05'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  group('Home Page Load', () => {
    const start = Date.now();
    const res = http.get(`${BASE_URL}/`, { tags: { name: 'HomePage' } });
    pageLoadTime.add(Date.now() - start);
    requestCount.add(1);

    const ok = check(res, {
      'status 200': (r) => r.status === 200,
      'body not empty': (r) => r.body && r.body.length > 0,
      'response time < 3s': (r) => r.timings.duration < 3000,
    });
    errorRate.add(!ok);
  });

  group('Static Assets', () => {
    const assets = [
      '/main.dart.js',
      '/flutter.js',
      '/manifest.json',
    ];
    for (const asset of assets) {
      const res = http.get(`${BASE_URL}${asset}`, { tags: { name: 'StaticAsset' } });
      requestCount.add(1);
      const ok = check(res, {
        'asset loads': (r) => r.status === 200 || r.status === 304,
      });
      errorRate.add(!ok);
    }
  });

  sleep(1);
}

export function handleSummary(data) {
  return {
    'reports/load_smoke_summary.json': JSON.stringify(data, null, 2),
  };
}
