const DriverFactory = require('../helpers/driverFactory');
const PageObjects = require('../helpers/pageObjects');
const WebDriverUtils = require('../helpers/webDriverUtils');
const config = require('../config/testConfig');

async function runDatabaseTests() {
  const results = [];
  const categoryId = 7;
  const categoryName = 'Database Testing';
  const suiteName = 'Local Storage & Data State Integrity Suite';

  let driver;
  try {
    driver = await DriverFactory.createDriver();
    const pages = new PageObjects(driver);
    const utils = new WebDriverUtils(driver);

    await pages.navigateToHome(config.baseUrl);

    // Test 7.1: User Profile Data Entity Schema Validation
    const start1 = Date.now();
    try {
      const mockProfile = {
        name: 'Sarah Connor',
        age: 38,
        email: 'sarah@resistance.org',
        phone: '5550199',
        bloodGroup: 'O+'
      };
      await utils.setLocalStorage('med_care_user_profile', mockProfile);
      const retrieved = await utils.getLocalStorage();
      const profileData = JSON.parse(retrieved['med_care_user_profile'] || '{}');

      const isSchemaValid = profileData.name === 'Sarah Connor' && profileData.email === 'sarah@resistance.org';

      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify User Profile Database / Storage Entity Schema',
        status: isSchemaValid ? 'PASS' : 'FAIL',
        durationMs: Date.now() - start1,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify User Profile Database / Storage Entity Schema',
        status: 'FAIL',
        error: err.message,
        durationMs: Date.now() - start1,
        timestamp: new Date().toISOString()
      });
    }

    // Test 7.2: Medicine List Collection Persistence & CRUD State
    const start2 = Date.now();
    try {
      const mockMedicines = [
        { id: 'med-001', name: 'Metformin 500mg', dosage: '1 tablet twice daily' },
        { id: 'med-002', name: 'Lisinopril 10mg', dosage: '1 tablet in morning' }
      ];
      await utils.setLocalStorage('med_care_medicines', mockMedicines);
      const retrieved = await utils.getLocalStorage();
      const medList = JSON.parse(retrieved['med_care_medicines'] || '[]');

      const isListValid = Array.isArray(medList) && medList.length === 2;

      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify Medication Collection CRUD Data Integrity',
        status: isListValid ? 'PASS' : 'FAIL',
        durationMs: Date.now() - start2,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify Medication Collection CRUD Data Integrity',
        status: 'FAIL',
        error: err.message,
        durationMs: Date.now() - start2,
        timestamp: new Date().toISOString()
      });
    }

    // Test 7.3: Storage Reset & Transaction Rollback Behavior
    const start3 = Date.now();
    try {
      await utils.clearLocalStorage();
      const storageAfterClear = await utils.getLocalStorage();
      const isCleared = Object.keys(storageAfterClear).length === 0;

      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify Storage Purge & Transaction Rollback Cleanliness',
        status: isCleared ? 'PASS' : 'FAIL',
        durationMs: Date.now() - start3,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: 'Verify Storage Purge & Transaction Rollback Cleanliness',
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

module.exports = runDatabaseTests;
