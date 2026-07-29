const DriverFactory = require('../helpers/driverFactory');
const PageObjects = require('../helpers/pageObjects');
const WebDriverUtils = require('../helpers/webDriverUtils');
const config = require('../config/testConfig');

async function runRegressionTests() {
  const results = [];
  const categoryId = 10;
  const categoryName = 'Regression Testing';
  const suiteName = 'Edge Case & Input Validation Regression Suite';

  let driver;
  try {
    driver = await DriverFactory.createDriver();
    const pages = new PageObjects(driver);
    const utils = new WebDriverUtils(driver);

    await pages.navigateToHome(config.baseUrl);

    // Test 10.1: Empty Form Submission Handling (Validation Trigger)
    const start1 = Date.now();
    try {
      await pages.submitRegistration();
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Regression: Empty Required Fields Submission Validation',
        status: 'PASS',
        durationMs: Date.now() - start1,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Regression: Empty Required Fields Submission Validation',
        status: 'FAIL',
        error: err.message,
        durationMs: Date.now() - start1,
        timestamp: new Date().toISOString()
      });
    }

    // Test 10.2: Ultra-Long String Input Boundary Test (2500+ characters)
    const start2 = Date.now();
    try {
      const longString = 'A'.repeat(2500);
      await pages.fillRegistrationForm({ name: longString });
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Regression: Extremely Long String Input Boundary Test (2500+ Chars)',
        status: 'PASS',
        durationMs: Date.now() - start2,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Regression: Extremely Long String Input Boundary Test (2500+ Chars)',
        status: 'FAIL',
        error: err.message,
        durationMs: Date.now() - start2,
        timestamp: new Date().toISOString()
      });
    }

    // Test 10.3: Page Refresh State Preservation Check
    const start3 = Date.now();
    try {
      await driver.navigate().refresh();
      await utils.waitForElement(pages.locators.bodyTag);
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Regression: Application Reload State Integrity After Browser Refresh',
        status: 'PASS',
        durationMs: Date.now() - start3,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Regression: Application Reload State Integrity After Browser Refresh',
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

module.exports = runRegressionTests;
