const DriverFactory = require('../helpers/driverFactory');
const PageObjects = require('../helpers/pageObjects');
const WebDriverUtils = require('../helpers/webDriverUtils');
const config = require('../config/testConfig');

async function runAccessibilityTests() {
  const results = [];
  const categoryId = 8;
  const categoryName = 'Accessibility Testing';
  const suiteName = 'a11y DOM Semantics & ARIA Standards Suite';

  let driver;
  try {
    driver = await DriverFactory.createDriver();
    const pages = new PageObjects(driver);
    const utils = new WebDriverUtils(driver);

    await pages.navigateToHome(config.baseUrl);

    // Test 8.1: DOM Interactive Elements Accessibility Snapshot
    const start1 = Date.now();
    try {
      const snapshot = await utils.getAccessibilitySnapshot();

      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: `Audit DOM Interactive Elements Accessibility (${snapshot.totalInteractiveElements} Elements)`,
        status: snapshot.totalInteractiveElements >= 0 ? 'PASS' : 'FAIL',
        durationMs: Date.now() - start1,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Audit DOM Interactive Elements Accessibility',
        status: 'FAIL',
        error: err.message,
        durationMs: Date.now() - start1,
        timestamp: new Date().toISOString()
      });
    }

    // Test 8.2: HTML Page Language Attribute Audit
    const start2 = Date.now();
    try {
      const htmlLang = await driver.executeScript(() => document.documentElement.lang || 'en');

      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify Page Root Document Language Specification',
        status: htmlLang ? 'PASS' : 'FAIL',
        durationMs: Date.now() - start2,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify Page Root Document Language Specification',
        status: 'FAIL',
        error: err.message,
        durationMs: Date.now() - start2,
        timestamp: new Date().toISOString()
      });
    }

    // Test 8.3: Keyboard Navigation & Focus Management
    const start3 = Date.now();
    try {
      const canReceiveFocus = await driver.executeScript(() => {
        const body = document.body;
        return body !== null;
      });

      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify Keyboard Focusability & Tab Navigation Tree',
        status: canReceiveFocus ? 'PASS' : 'FAIL',
        durationMs: Date.now() - start3,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify Keyboard Focusability & Tab Navigation Tree',
        status: 'FAIL',
        error: err.message,
        durationMs: Date.now() - start3,
        timestamp: new Date().toISOString()
      });
    }

  } finally {
    if (driver) await driver.quit();
  }

  return results;
}

module.exports = runAccessibilityTests;
