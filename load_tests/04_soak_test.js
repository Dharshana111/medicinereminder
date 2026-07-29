// MedCare+ Load Test: k6 — Soak / Endurance Test
// Runs sustained load for a long period to detect memory leaks & degradation

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

export const errorRate    = new Rate('errors');
export const pageLoadTime = new Trend('page_load_time', true);
export const requestCount = new Counter('total_requests');

export const options = {
  stages: [
    { duration: '5m',  target: 50  },  // Ramp up
    { duration: '60m', target: 50  },  // Soak for 1 hour at 50 VUs
    { duration: '5m',  target: 0   },  // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<3000'],  // Must stay < 3s throughout
    http_req_failed:   ['rate<0.02'],
    errors:            ['rate<0.02'],
    // Ensure performance doesn't degrade: avg should stay under 1.5s
    'http_req_duration{phase:soak}': ['avg<1500'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  group('Soak: Normal User Workflow', () => {
    const homeRes = http.get(BASE_URL, {
      tags: { name: 'SoakHome', phase: 'soak' }
    });
    requestCount.add(1);
    pageLoadTime.add(homeRes.timings.duration);
    const ok = check(homeRes, {
      'Home responds': (r) => r.status === 200,
      'Home fast':     (r) => r.timings.duration < 3000,
    });
    errorRate.add(!ok);

    sleep(Math.random() * 3 + 1);

    const manifestRes = http.get(`${BASE_URL}/manifest.json`, {
      tags: { name: 'SoakManifest', phase: 'soak' }
    });
    requestCount.add(1);
    check(manifestRes, { 'Manifest loads': (r) => r.status === 200 });

    sleep(Math.random() * 2 + 0.5);
  });
}

export function handleSummary(data) {
  return {
    'reports/load_soak_test_summary.json': JSON.stringify(data, null, 2),
  };
}
