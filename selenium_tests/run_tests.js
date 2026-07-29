const path = require('path');
const fs = require('fs');

const runFunctionalTests = require('./tests/01_functional.test');
const runUiUxTests = require('./tests/02_ui_ux.test');
const runCompatibilityTests = require('./tests/03_compatibility.test');
const runPerformanceTests = require('./tests/04_performance.test');
const runSecurityTests = require('./tests/05_security.test');
const runApiTests = require('./tests/06_api.test');
const runDatabaseTests = require('./tests/07_database.test');
const runAccessibilityTests = require('./tests/08_accessibility.test');
const runMobileSpecificTests = require('./tests/09_mobile_specific.test');
const runRegressionTests = require('./tests/10_regression.test');
const runEndToEndTests = require('./tests/11_e2e.test');

const ExcelReporter = require('./helpers/excelReporter');
const config = require('./config/testConfig');
const startServer = require('./helpers/webServer');

async function executeAllTests() {
  console.log('\n===============================================================');
  console.log('🚀 MEDCARE+ END-TO-END AUTOMATED SELENIUM TEST FRAMEWORK');
  console.log('===============================================================\n');

  const server = await startServer(8080);
  const globalStart = Date.now();
  let allResults = [];
  let performanceMetrics = [];


  const suites = [
    { id: 1, name: 'Functional Testing', runner: runFunctionalTests },
    { id: 2, name: 'UI/UX Testing', runner: runUiUxTests },
    { id: 3, name: 'Compatibility Testing', runner: runCompatibilityTests },
    { id: 4, name: 'Performance Testing', runner: runPerformanceTests },
    { id: 5, name: 'Security Testing', runner: runSecurityTests },
    { id: 6, name: 'API Testing', runner: runApiTests },
    { id: 7, name: 'Database Testing', runner: runDatabaseTests },
    { id: 8, name: 'Accessibility Testing', runner: runAccessibilityTests },
    { id: 9, name: 'Mobile-Specific Testing', runner: runMobileSpecificTests },
    { id: 10, name: 'Regression Testing', runner: runRegressionTests },
    { id: 11, name: 'End-to-End (E2E) Testing', runner: runEndToEndTests }
  ];

  for (const suite of suites) {
    console.log(`▶ Executing [Category ${suite.id}/11]: ${suite.name}...`);
    try {
      const res = await suite.runner();
      if (res && res.results) {
        allResults.push(...res.results);
        if (res.performanceMetrics) performanceMetrics.push(...res.performanceMetrics);
      } else if (Array.isArray(res)) {
        allResults.push(...res);
      }
      console.log(`  ✔ Completed ${suite.name}`);
    } catch (err) {
      console.error(`  ✖ Failed executing ${suite.name}:`, err.message);
      allResults.push({
        categoryId: suite.id,
        categoryName: suite.name,
        suiteName: suite.name,
        title: `Category ${suite.id} Execution Suite`,
        status: 'FAIL',
        error: err.message,
        durationMs: 0,
        timestamp: new Date().toISOString()
      });
    }
  }

  const globalDuration = Date.now() - globalStart;
  const totalPassed = allResults.filter(r => r.status === 'PASS').length;
  const totalFailed = allResults.filter(r => r.status === 'FAIL').length;
  const totalTests = allResults.length;

  console.log('\n===============================================================');
  console.log('📊 TEST EXECUTION SUMMARY RESULTS');
  console.log('===============================================================');
  console.log(` Total Test Cases Executed : ${totalTests}`);
  console.log(` Total Passed              : ${totalPassed} ✅`);
  console.log(` Total Failed              : ${totalFailed} ❌`);
  console.log(` Pass Rate (%)             : ${totalTests > 0 ? ((totalPassed / totalTests) * 100).toFixed(1) : 0}%`);
  console.log(` Total Time Duration       : ${(globalDuration / 1000).toFixed(2)} seconds`);
  console.log('===============================================================\n');

  // Generate Excel Analysis Report
  console.log('📝 Generating Excel Analysis Report...');
  const reporter = new ExcelReporter();
  const reportSummary = {
    total: totalTests,
    passed: totalPassed,
    failed: totalFailed,
    durationMs: globalDuration,
    baseUrl: config.baseUrl
  };

  const { reportPath, latestReportPath } = await reporter.generateReport(
    allResults,
    reportSummary,
    performanceMetrics
  );

  console.log(`✨ Excel Analysis Report successfully generated:`);
  console.log(`   📄 Timestamped Report: ${reportPath}`);
  console.log(`   📄 Latest Report Copy: ${latestReportPath}\n`);

  if (server) {
    server.close();
  }
}


// Execute test run
executeAllTests().catch(err => {
  console.error('Fatal Test Execution Error:', err);
  process.exit(1);
});
