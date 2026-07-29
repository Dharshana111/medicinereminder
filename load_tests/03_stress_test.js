// MedCare+ Load Test: k6 — Stress Test (beyond normal capacity)
// Find the breaking point of the application

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

export const errorRate    = new Rate('errors');
export const pageLoadTime = new Trend('page_load_time', true);
export const requestCount = new Counter('total_requests');

export const options = {
  stages: [
    { duration: '2m',  target: 100  },  // Ramp to normal load
    { duration: '5m',  target: 100  },  // Hold normal
    { duration: '2m',  target: 300  },  // Stress: 3x normal
    { duration: '5m',  target: 300  },  // Hold stress
    { duration: '2m',  target: 500  },  // Extreme stress
    { duration: '3m',  target: 500  },  // Hold extreme
    { duration: '2m',  target: 0    },  // Recovery
  ],
  thresholds: {
    // More lenient thresholds under stress
    http_req_duration: ['p(95)<10000'],  // 10s max at stress
    http_req_failed:   ['rate<0.10'],    // Accept up to 10% failures at stress
    errors:            ['rate<0.10'],
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export default function () {
  group('Stress: Home Page', () => {
    const start = Date.now();
    const res = http.get(BASE_URL, {
      tags: { name: 'StressHomePage' },
      timeout: '15s',
    });
    pageLoadTime.add(Date.now() - start);
    requestCount.add(1);

    const ok = check(res, {
      'status 200 or 503': (r) => r.status === 200 || r.status === 503,
      'not timed out':     (r) => r.timings.duration < 15000,
    });
    errorRate.add(!ok);
  });

  sleep(Math.random() * 0.5 + 0.1);
}

export function handleSummary(data) {
  const metrics = data.metrics;
  const reqDur = metrics.http_req_duration;
  const failed = metrics.http_req_failed;

  const stressReport = {
    testType: 'Stress Test',
    timestamp: new Date().toISOString(),
    summary: {
      totalRequests: metrics.http_reqs ? metrics.http_reqs.values.count : 0,
      failureRate: failed ? (failed.values.rate * 100).toFixed(2) + '%' : 'N/A',
      avgResponseMs: reqDur ? reqDur.values.avg.toFixed(2) : 'N/A',
      p95ResponseMs: reqDur ? reqDur.values['p(95)'].toFixed(2) : 'N/A',
      p99ResponseMs: reqDur ? reqDur.values['p(99)'].toFixed(2) : 'N/A',
      maxResponseMs: reqDur ? reqDur.values.max.toFixed(2) : 'N/A',
    },
    raw: data,
  };

  return {
    'reports/load_stress_test_summary.json': JSON.stringify(stressReport, null, 2),
  };
}
