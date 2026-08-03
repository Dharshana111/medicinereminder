const { By } = require('selenium-webdriver');
const WebDriverUtils = require('./webDriverUtils');

class PageObjects {
  constructor(driver) {
    this.driver = driver;
    this.utils = new WebDriverUtils(driver);
  }

  // ── Locators ──
  get locators() {
    return {
      // General App Locators
      appTitle: By.css('title, head title'),
      bodyTag: By.tagName('body'),
      fltSemantics: By.css('flt-semantics, flt-glass-pane, body'),

      // Registration Screen Locators
      regNameInput: By.xpath("//input[contains(@aria-label, 'Name') or contains(@placeholder, 'Name')] | //input[1]"),
      regAgeInput: By.xpath("//input[contains(@aria-label, 'Age') or contains(@placeholder, 'Age')] | //input[2]"),
      regPhoneInput: By.xpath("//input[contains(@aria-label, 'Phone') or contains(@placeholder, 'Phone')] | //input[3]"),
      regEmailInput: By.xpath("//input[contains(@aria-label, 'Email') or contains(@placeholder, 'Email')] | //input[4]"),
      regAddressInput: By.xpath("//input[contains(@aria-label, 'Address') or contains(@placeholder, 'Address')] | //input[5]"),
      regSubmitBtn: By.xpath("//button[contains(., 'Save Profile') or contains(., 'Get Started') or contains(., 'Submit')] | //*[contains(@role, 'button')]"),

      // Navigation Bar Locators
      navHome: By.xpath("//*[contains(@aria-label, 'Home') or contains(., 'Home')]"),
      navHistory: By.xpath("//*[contains(@aria-label, 'History') or contains(., 'History')]"),
      navProfile: By.xpath("//*[contains(@aria-label, 'Profile') or contains(., 'Profile')]"),
      navAddFab: By.xpath("//*[contains(@aria-label, 'Add') or contains(., 'Add')] | //button[contains(@class, 'fab')]"),

      // Add Medicine Screen Locators
      medNameInput: By.xpath("//input[contains(@aria-label, 'Medicine Name') or contains(@placeholder, 'Name')] | //input[1]"),
      medDosageInput: By.xpath("//input[contains(@aria-label, 'Dosage') or contains(@placeholder, 'Dosage')] | //input[2]"),
      medDescInput: By.xpath("//input[contains(@aria-label, 'Description') or contains(@placeholder, 'Description')] | //input[3]"),
      medSaveBtn: By.xpath("//button[contains(., 'Save') or contains(., 'Add Medicine')] | //*[contains(@role, 'button')]"),

      // Dashboard Items
      medicationCard: By.css('.medication-card, flt-semantics-node'),
      takeMedicationBtn: By.xpath("//button[contains(., 'Take') or contains(., 'Mark Taken')]"),
      skipMedicationBtn: By.xpath("//button[contains(., 'Skip')]")
    };
  }

  // ── High-Level Page Actions ──

  async navigateToHome(baseUrl) {
    if (!this.driver) return;
    await this.driver.get(baseUrl);
    await this.utils.waitForElement(this.locators.bodyTag);
  }

  async fillRegistrationForm(profileData) {
    if (!this.driver) return;
    if (await this.utils.isElementPresent(this.locators.regNameInput)) {
      if (profileData.name) await this.utils.typeText(this.locators.regNameInput, profileData.name);
      if (profileData.age) await this.utils.typeText(this.locators.regAgeInput, profileData.age);
      if (profileData.phone) await this.utils.typeText(this.locators.regPhoneInput, profileData.phone);
      if (profileData.email) await this.utils.typeText(this.locators.regEmailInput, profileData.email);
    }
  }

  async submitRegistration() {
    if (!this.driver) return;
    if (await this.utils.isElementPresent(this.locators.regSubmitBtn)) {
      await this.utils.clickElement(this.locators.regSubmitBtn);
    }
  }

  async openAddMedicineScreen() {
    if (!this.driver) return;
    if (await this.utils.isElementPresent(this.locators.navAddFab)) {
      await this.utils.clickElement(this.locators.navAddFab);
    }
  }

  async fillAddMedicineForm(medData) {
    if (!this.driver) return;
    if (await this.utils.isElementPresent(this.locators.medNameInput)) {
      if (medData.name) await this.utils.typeText(this.locators.medNameInput, medData.name);
      if (medData.dosage) await this.utils.typeText(this.locators.medDosageInput, medData.dosage);
      if (medData.description) await this.utils.typeText(this.locators.medDescInput, medData.description);
    }
  }

  async saveMedicine() {
    if (!this.driver) return;
    if (await this.utils.isElementPresent(this.locators.medSaveBtn)) {
      await this.utils.clickElement(this.locators.medSaveBtn);
    }
  }
}

module.exports = PageObjects;
