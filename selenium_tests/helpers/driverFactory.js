const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const config = require('../config/testConfig');

class DriverFactory {
  /**
   * Create and return a configured Selenium WebDriver instance
   * @param {Object} options Options for driver creation
   * @param {string} options.viewport Viewport name from config.viewports
   * @param {boolean} options.headless Override default headless mode
   * @param {Object} options.mobileEmulation Mobile device emulation settings
   */
  static async createDriver(options = {}) {
    const isHeadless = options.headless !== undefined ? options.headless : config.headless;
    const viewport = options.viewport ? config.viewports[options.viewport] : config.viewports.desktop;

    const chromeOptions = new chrome.Options();
    
    // Core Chrome options for stable test execution
    chromeOptions.addArguments('--no-sandbox');
    chromeOptions.addArguments('--disable-dev-shm-usage');
    chromeOptions.addArguments('--disable-gpu');
    chromeOptions.addArguments('--disable-extensions');
    chromeOptions.addArguments('--ignore-certificate-errors');
    chromeOptions.addArguments('--allow-insecure-localhost');
    chromeOptions.addArguments(`--window-size=${viewport.width},${viewport.height}`);

    if (isHeadless) {
      chromeOptions.addArguments('--headless=new');
    }

    if (options.mobileEmulation) {
      chromeOptions.setMobileEmulation(options.mobileEmulation);
    }

    const driver = await new Builder()
      .forBrowser('chrome')
      .setChromeOptions(chromeOptions)
      .build();

    // Set implicit and page load timeouts
    await driver.manage().setTimeouts({
      implicit: config.timeouts.implicit,
      pageLoad: config.timeouts.pageLoad,
      script: config.timeouts.script
    });

    return driver;
  }
}

module.exports = DriverFactory;
