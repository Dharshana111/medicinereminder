# Reports Directory

This directory is used by the MedCare+ test suites to store generated reports.

## Contents

| Directory | Purpose |
|-----------|---------|
| `selenium_tests/reports/` | Selenium Excel test reports (`.xlsx`, `.csv`) |
| `appium_tests/reports/` | Appium mobile test Excel reports (`.xlsx`) |
| `load_tests/reports/` | k6 load test JSON summaries + HTML report |

## CI Artifacts

All reports are automatically uploaded as **GitHub Actions Artifacts** and are available
for 30 days after each workflow run.

### Where to find reports

1. Go to your repository on GitHub
2. Click **Actions** tab
3. Select a workflow run
4. Scroll down to **Artifacts**
5. Download the relevant report archive

### Report types

- **Selenium**: `selenium-all-reports` — Excel files with all 11 test categories
- **Appium Android**: `appium-android-reports` — Excel with 5 mobile test suites
- **Appium iOS**: `appium-ios-reports` — Excel with 5 mobile test suites
- **Load Tests**: `load-test-final-report` — HTML dashboard + JSON summaries
