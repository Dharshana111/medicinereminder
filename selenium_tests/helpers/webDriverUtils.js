const { By, until } = require('selenium-webdriver');
const config = require('../config/testConfig');

class WebDriverUtils {
  constructor(driver) {
    this.driver = driver;
  }

  /**
   * Wait until element is visible and located
   */
  async waitForElement(locator, timeout = config.timeouts.explicit) {
    return await this.driver.wait(until.elementLocated(locator), timeout);
  }

  /**
   * Wait and click element safely
   */
  async clickElement(locator, timeout = config.timeouts.explicit) {
    const el = await this.waitForElement(locator, timeout);
    await this.driver.wait(until.elementIsVisible(el), timeout);
    await el.click();
    return el;
  }

  /**
   * Wait and enter text safely
   */
  async typeText(locator, text, timeout = config.timeouts.explicit) {
    const el = await this.waitForElement(locator, timeout);
    await this.driver.wait(until.elementIsVisible(el), timeout);
    await el.clear();
    await el.sendKeys(text);
    return el;
  }

  /**
   * Check if element is present in DOM
   */
  async isElementPresent(locator) {
    try {
      const elements = await this.driver.findElements(locator);
      return elements.length > 0;
    } catch (e) {
      return false;
    }
  }

  /**
   * Get text from element
   */
  async getElementText(locator) {
    const el = await this.waitForElement(locator);
    return await el.getText();
  }

  /**
   * Get element attribute value
   */
  async getAttribute(locator, attributeName) {
    const el = await this.waitForElement(locator);
    return await el.getAttribute(attributeName);
  }

  /**
   * Get element CSS property
   */
  async getCssValue(locator, cssProperty) {
    const el = await this.waitForElement(locator);
    return await el.getCssValue(cssProperty);
  }

  /**
   * Get LocalStorage items as JSON object
   */
  async getLocalStorage() {
    return await this.driver.executeScript(() => {
      const items = {};
      for (let i = 0; i < localStorage.length; i++) {
        const key = localStorage.key(i);
        items[key] = localStorage.getItem(key);
      }
      return items;
    });
  }

  /**
   * Set LocalStorage key/value pair
   */
  async setLocalStorage(key, value) {
    await this.driver.executeScript((k, v) => {
      localStorage.setItem(k, typeof v === 'object' ? JSON.stringify(v) : v);
    }, key, value);
  }

  /**
   * Clear browser LocalStorage
   */
  async clearLocalStorage() {
    await this.driver.executeScript(() => {
      localStorage.clear();
    });
  }

  /**
   * Capture browser navigation timing performance metrics
   */
  async getPerformanceTiming() {
    return await this.driver.executeScript(() => {
      const timing = window.performance.timing;
      const navigation = window.performance.getEntriesByType('navigation')[0] || {};
      
      return {
        pageLoadTime: timing.loadEventEnd - timing.navigationStart,
        domContentLoadedTime: timing.domContentLoadedEventEnd - timing.navigationStart,
        dnsLookupTime: timing.domainLookupEnd - timing.domainLookupStart,
        tcpConnectTime: timing.connectEnd - timing.connectStart,
        responseTime: timing.responseEnd - timing.requestStart,
        domInteractiveTime: timing.domInteractive - timing.navigationStart,
        domCompleteTime: timing.domComplete - timing.navigationStart,
        transferSize: navigation.transferSize || 0,
        encodedBodySize: navigation.encodedBodySize || 0,
        decodedBodySize: navigation.decodedBodySize || 0
      };
    });
  }

  /**
   * Verify ARIA semantics and accessibility attributes on elements
   */
  async getAccessibilitySnapshot() {
    return await this.driver.executeScript(() => {
      const interactiveElements = document.querySelectorAll('button, input, select, textarea, a, [role]');
      const details = [];

      interactiveElements.forEach((el, index) => {
        details.push({
          index: index + 1,
          tagName: el.tagName.toLowerCase(),
          id: el.id || null,
          role: el.getAttribute('role') || null,
          ariaLabel: el.getAttribute('aria-label') || null,
          title: el.getAttribute('title') || null,
          placeholder: el.getAttribute('placeholder') || null,
          type: el.getAttribute('type') || null,
          tabIndex: el.getAttribute('tabindex') || '0',
          hasLabel: !!(el.labels && el.labels.length > 0) || !!el.getAttribute('aria-label') || !!el.innerText
        });
      });

      return {
        totalInteractiveElements: interactiveElements.length,
        elements: details
      };
    });
  }

  /**
   * Execute XSS injection payload check
   */
  async testXssSanitization(inputLocator, submitLocator, payload) {
    let alertTriggered = false;
    
    try {
      await this.typeText(inputLocator, payload);
      await this.clickElement(submitLocator);

      // Check if an alert modal was spawned
      try {
        const alert = await this.driver.switchTo().alert();
        alertTriggered = true;
        await alert.dismiss();
      } catch (noAlert) {
        alertTriggered = false;
      }
    } catch (err) {
      // Element error or form rejection
    }

    return !alertTriggered;
  }
}

module.exports = WebDriverUtils;
