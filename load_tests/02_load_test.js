// MedCare+ Load Test: k6 — Load Test (normal traffic simulation)
// Simulates realistic concurrent user load

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ── Custom Metrics ───────────────────────────────────────────────────────────
export const errorRate      = new Rate('errors');
export const pageLoadTime   = new Trend('page_load_time', true);
export const ttfb           = new Trend('time_to_first_byte', true);
export const requestCount   = new Counter('total_requests');

// ── Test Options — Ramping VUs ────────────────────────────────────────────────
export const options = {
  stages: [
    { duration: '1m',  target: 10 },   // Ramp up to 10 users
    { duration: '3m',  target: 50 },   // Hold at 50 users (normal load)
    { duration: '1m',  target: 100 },  // Peak: 100 concurrent users
    { duration: '2m',  target: 100 },  // Hold at peak
    { duration: '1m',  target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration:            ['p(50)<1000', 'p(95)<3000', 'p(99)<5000'],
    http_req_failed:              ['rate<0.02'],   // < 2% error rate
    errors:                       ['rate<0.02'],
    time_to_first_byte:           ['p(95)<1500'],
    'http_req_duration{name:HomePage}': ['p(95)<2000'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  // Simulate a user browsing the MedCare+ web app

  group('Home Page', () => {
    const res = http.get(BASE_URL, { tags: { name: 'HomePage' } });
    ttfb.add(res.timings.waiting);
    requestCount.add(1);
    const ok = check(res, {
      'Home: status 200':    (r) => r.status === 200,
      'Home: loads < 2s':    (r) => r.timings.duration < 2000,
      'Home: has content':   (r) => r.body.length > 100,
    });
    errorRate.add(!ok);
    sleep(Math.random() * 2 + 0.5); // Think time: 0.5–2.5s
  });

  group('App Shell Assets', () => {
    const reqs = [
      { url: `${BASE_URL}/flutter.js`,        name: 'FlutterJS' },
      { url: `${BASE_URL}/main.dart.js`,       name: 'MainDartJS' },
      { url: `${BASE_URL}/manifest.json`,      name: 'Manifest' },
      { url: `${BASE_URL}/favicon.png`,        name: 'Favicon' },
    ];

    const responses = http.batch(reqs.map(r => [
      'GET', r.url, null, { tags: { name: r.name } }
    ]));

    for (const res of responses) {
      requestCount.add(1);
      const ok = check(res, {
        'Asset: loaded': (r) => r.status === 200 || r.status === 304,
        'Asset: < 5s':   (r) => r.timings.duration < 5000,
      });
      errorRate.add(!ok);
    }
    sleep(Math.random() * 1 + 0.3);
  });

  group('Icons & PWA Resources', () => {
    const icons = [
      `${BASE_URL}/icons/Icon-192.png`,
      `${BASE_URL}/icons/Icon-512.png`,
    ];
    const responses = http.batch(icons.map(url => ['GET', url]));
    for (const res of responses) {
      requestCount.add(1);
      check(res, { 'Icon: loaded': (r) => r.status === 200 || r.status === 304 });
    }
    sleep(0.5);
  });
}

export function handleSummary(data) {
  return {
    'reports/load_load_test_summary.json': JSON.stringify(data, null, 2),
  };
}
