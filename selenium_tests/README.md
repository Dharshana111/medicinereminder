# MedCare+ End-to-End Selenium Testing & Excel Analysis Suite

Automated Selenium WebDriver testing framework in **Node.js** for the **MedCare+ — Smart Medicine Reminder System** web application. Generates comprehensive `.xlsx` analysis reports covering all 11 testing categories.

---

## 📋 Overview of 11 Test Categories Covered

1. **Functional Testing** (`tests/01_functional.test.js`)
   - Page load title verification
   - Registration form submission & validation
   - Adding new medication records
   - Navigation menu routing
2. **UI/UX Testing** (`tests/02_ui_ux.test.js`)
   - Root elements & DOM tree rendering
   - Typography, font family & CSS box model
   - Layout paddings and element alignments
3. **Compatibility Testing** (`tests/03_compatibility.test.js`)
   - Desktop Full HD (1920x1080)
   - Laptop Standard (1366x768)
   - Tablet iPad (768x1024)
   - Mobile Portrait & Landscape (375x812 / 812x375)
4. **Performance Testing** (`tests/04_performance.test.js`)
   - Page Navigation Load Time (< 5000 ms)
   - DOMContentLoaded timing benchmark (< 2000 ms)
   - Resource payload size & memory footprint
5. **Security Testing** (`tests/05_security.test.js`)
   - XSS Script Injection payload defense
   - Plaintext LocalStorage key security audit
   - HTML Tag & Iframe injection sanitization
6. **API Testing** (`tests/06_api.test.js`)
   - Browser Window `Fetch` API availability
   - LocalStorage API Read/Write operations
   - Web Notification Permission API integration
7. **Database Testing** (`tests/07_database.test.js`)
   - User Profile entity schema validation
   - Medication collection CRUD data integrity
   - Storage clear & transaction rollback cleanliness
8. **Accessibility Testing** (`tests/08_accessibility.test.js`)
   - Interactive DOM element accessibility snapshot
   - Root document HTML language attribute specification
   - Keyboard focusability & tab navigation structure
9. **Mobile-Specific Testing** (`tests/09_mobile_specific.test.js`)
   - iPhone X emulation & touch viewport behavior
   - Pixel 5 device emulation & User-Agent verification
   - Mobile landscape orientation scaling
10. **Regression Testing** (`tests/10_regression.test.js`)
    - Empty required form field validation
    - Boundary test with ultra-long strings (2500+ chars)
    - Browser refresh reload state preservation
11. **End-to-End (E2E) Testing** (`tests/11_e2e.test.js`)
    - Full user lifecycle (Launch -> Register Profile -> Add Medication -> Track Schedule -> E2E Validation)

---

## 📊 Excel Analysis Report Features (`exceljs`)

Generated reports are saved in `selenium_tests/reports/`:
- `Test_Execution_Report_<timestamp>.xlsx`
- `Latest_Test_Report.xlsx`

Worksheet structure:
1. **Executive Dashboard**: Key KPI summary cards, pass rate %, overall duration, and target app specs.
2. **Detailed Test Log**: Row-by-row log of every test case, category, status (`PASS`/`FAIL`), execution time (ms), and error traces.
3. **Category Analysis**: Aggregated pass/fail counts and pass percentages across all 11 test types.
4. **Performance & Metrics**: Page load benchmarks, DOM readiness metrics, and viewport scaling results.

---

## 🛠 Setup & Execution Instructions

### Prerequisites
- Node.js (v14+)
- Google Chrome browser installed
- Web server running MedCare+ web app (default: `http://localhost:8080`)

### Installation
Navigating into the `selenium_tests` directory and installing dependencies:
```bash
cd selenium_tests
npm install
```

### Running the Test Suite
```bash
npm test
```
Or directly running with Node:
```bash
node run_tests.js
```

### Configuration Options
Edit `config/testConfig.js` or set environment variables:
```bash
TEST_BASE_URL=http://localhost:8080 HEADLESS=true node run_tests.js
```
