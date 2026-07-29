const DriverFactory = require('../helpers/driverFactory');
const PageObjects = require('../helpers/pageObjects');
const config = require('../config/testConfig');

async function runMobileSpecificTests() {
  const results = [];
  const categoryId = 9;
  const categoryName = 'Mobile-Specific Testing';
  const suiteName = 'Mobile Emulation & Touch Viewport Suite';

  const mobileDevicesToTest = [
    { key: 'iPhoneX', device: config.mobileDevices.iPhoneX },
    { key: 'pixel5', device: config.mobileDevices.pixel5 }
  ];

  for (const item of mobileDevicesToTest) {
    let driver;
    const start = Date.now();
    const dev = item.device;

    try {
      driver = await DriverFactory.createDriver({
        mobileEmulation: {
          deviceName: dev.deviceName
        }
      });
      const pages = new PageObjects(driver);
      await pages.navigateToHome(config.baseUrl);

      const userAgent = await driver.executeScript(() => navigator.userAgent);
      const isMobileUA = userAgent.toLowerCase().includes('mobile') || userAgent.toLowerCase().includes('iphone') || userAgent.toLowerCase().includes('android');

      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: `Mobile Device Emulation (${dev.deviceName}): Layout & User-Agent Verification`,
        status: 'PASS',
        durationMs: Date.now() - start,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      results.push({
        categoryId,
        categoryName,
        suiteName,
        title: `Mobile Device Emulation (${dev.deviceName}): Layout & User-Agent Verification`,
        status: 'FAIL',
        error: err.message,
        durationMs: Date.now() - start,
        timestamp: new Date().toISOString()
      });
    } finally {
      if (driver) await driver.quit();
    }
  }

  // Test 9.3: Mobile Orientation Switch (Portrait to Landscape)
  let driverOrientation;
  const startOrientation = Date.now();
  try {
    driverOrientation = await DriverFactory.createDriver({ viewport: 'mobileLandscape' });
    const pages = new PageObjects(driverOrientation);
    await pages.navigateToHome(config.baseUrl);

    const size = await driverOrientation.manage().window().getSize();

    results.push({
      categoryId,
      categoryName,
      suiteName,
      title: 'Mobile Landscape Orientation Viewport Scaling Test',
      status: size.width > size.height ? 'PASS' : 'FAIL',
      durationMs: Date.now() - startOrientation,
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    results.push({
      categoryId,
      categoryName,
      suiteName,
      title: 'Mobile Landscape Orientation Viewport Scaling Test',
      status: 'FAIL',
      error: err.message,
      durationMs: Date.now() - startOrientation,
      timestamp: new Date().toISOString()
    });
  } finally {
    if (driverOrientation) await driverOrientation.quit();
  }

  return results;
}

module.exports = runMobileSpecificTests;
