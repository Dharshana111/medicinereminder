const path = require('path');

module.exports = {
  // Target Application Settings
  baseUrl: process.env.TEST_BASE_URL || 'http://localhost:8080',
  
  // Timeout Configurations (in milliseconds)
  timeouts: {
    implicit: 5000,
    explicit: 10000,
    pageLoad: 30000,
    script: 10000
  },

  // Browser & Driver Configurations
  browser: process.env.TEST_BROWSER || 'chrome',
  headless: process.env.HEADLESS !== 'false',


  // Viewport Dimensions for Compatibility & Responsiveness Testing
  viewports: {
    desktop: { width: 1920, height: 1080, name: 'Desktop Full HD (1920x1080)' },
    laptop: { width: 1366, height: 768, name: 'Laptop Standard (1366x768)' },
    tablet: { width: 768, height: 1024, name: 'Tablet iPad (768x1024)' },
    mobilePortrait: { width: 375, height: 812, name: 'Mobile iPhone X/12/13 (375x812)' },
    mobileLandscape: { width: 812, height: 375, name: 'Mobile Landscape (812x375)' }
  },

  // Mobile Device Emulation Capabilities
  mobileDevices: {
    iPhoneX: {
      deviceName: 'iPhone X',
      width: 375,
      height: 812,
      pixelRatio: 3.0,
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1'
    },
    pixel5: {
      deviceName: 'Pixel 5',
      width: 393,
      height: 851,
      pixelRatio: 2.75,
      userAgent: 'Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36'
    }
  },

  // Report Directories
  reportsDir: path.join(__dirname, '..', 'reports')
};
