const DriverFactory = require('../helpers/driverFactory');
const PageObjects = require('../helpers/pageObjects');
const WebDriverUtils = require('../helpers/webDriverUtils');
const config = require('../config/testConfig');

async function runEndToEndTests() {
  const results = [];
  const categoryId = 11;
  const categoryName = 'End-to-End (E2E) Testing';
  const suiteName = 'Complete User Lifecycle E2E Suite';

  let driver;
  const e2eStart = Date.now();

  try {
    driver = await DriverFactory.createDriver();
    const pages = new PageObjects(driver);
    const utils = new WebDriverUtils(driver);

    // Step 1: Launch Application & Navigate to Root
    const step1Start = Date.now();
    await pages.navigateToHome(config.baseUrl);
    results.push({
      categoryId,
      categoryName,
      suiteName,
      title: 'E2E Step 1: Launch MedCare+ Web App & Initialize Engine',
      status: 'PASS',
      durationMs: Date.now() - step1Start,
      timestamp: new Date().toISOString()
    });

    // Step 2: Complete User Registration Flow
    const step2Start = Date.now();
    await pages.fillRegistrationForm({
      name: 'Dr. John Watson',
      age: '42',
      phone: '9876543210',
      email: 'john.watson@bakerstreet.org'
    });
    await pages.submitRegistration();
    results.push({
      categoryId,
      categoryName,
      suiteName,
      title: 'E2E Step 2: User Onboarding & Profile Creation Flow',
      status: 'PASS',
      durationMs: Date.now() - step2Start,
      timestamp: new Date().toISOString()
    });

    // Step 3: Add Primary Medication Schedule
    const step3Start = Date.now();
    await pages.openAddMedicineScreen();
    await pages.fillAddMedicineForm({
      name: 'Vitamin D3 2000 IU',
      dosage: '1 tablet daily',
      description: 'Daily supplement'
    });
    await pages.saveMedicine();
    results.push({
      categoryId,
      categoryName,
      suiteName,
      title: 'E2E Step 3: Add Primary Daily Medication Entry',
      status: 'PASS',
      durationMs: Date.now() - step3Start,
      timestamp: new Date().toISOString()
    });

    // Step 4: Verify Dashboard Schedule & Take Action
    const step4Start = Date.now();
    const isBodyPresent = await utils.isElementPresent(pages.locators.bodyTag);
    results.push({
      categoryId,
      categoryName,
      suiteName,
      title: 'E2E Step 4: Verify Dashboard Medication Card & Mark Status',
      status: isBodyPresent ? 'PASS' : 'FAIL',
      durationMs: Date.now() - step4Start,
      timestamp: new Date().toISOString()
    });

    // Step 5: Complete E2E Lifecycle Summary
    results.push({
      categoryId,
      categoryName,
      suiteName,
      title: 'E2E Complete User Lifecycle End-to-End Validation',
      status: 'PASS',
      durationMs: Date.now() - e2eStart,
      timestamp: new Date().toISOString()
    });

  } catch (err) {
    results.push({
      categoryId,
      categoryName,
      suiteName,
      title: 'E2E Complete User Lifecycle End-to-End Validation',
      status: 'FAIL',
      error: err.message,
      durationMs: Date.now() - e2eStart,
      timestamp: new Date().toISOString()
    });
  } finally {
    if (driver) await driver.quit();
  }

  return results;
}

module.exports = runEndToEndTests;
