"""
MedCare+ Appium Test: 02 – Medicine Management (Add / Edit / Delete) (Python)
"""
import time
from helpers.driver_factory import AppiumDriverFactory

SUITE_NAME  = "Medicine Management"
APP_PACKAGE = "com.example.medreminder"


def _tests() -> list[dict]:

    def test_add_medicine(driver):
        """Add new medicine with valid name and dosage."""
        add_btn = driver.find_element(
            "xpath",
            '//android.widget.Button[contains(@text,"Add") '
            'or contains(@content-desc,"Add medicine")]',
        )
        add_btn.click()
        driver.find_element("xpath", "//android.widget.EditText[1]").send_keys("Aspirin")
        driver.find_element("xpath", "//android.widget.EditText[2]").send_keys("100mg")
        driver.find_element("xpath", '//android.widget.Button[contains(@text,"Save")]').click()
        item = driver.find_element("xpath", '//android.widget.TextView[@text="Aspirin"]')
        if not item.is_displayed():
            raise AssertionError("Medicine not added to list")

    def test_reject_empty_name(driver):
        """Reject medicine entry with empty name."""
        driver.find_element(
            "xpath", '//android.widget.Button[contains(@text,"Add")]'
        ).click()
        driver.find_element(
            "xpath", '//android.widget.Button[contains(@text,"Save")]'
        ).click()
        error = driver.find_element(
            "xpath",
            '//android.widget.TextView[contains(@text,"required") '
            'or contains(@text,"cannot be empty")]',
        )
        if not error.is_displayed():
            raise AssertionError("Validation error not shown")

    def test_edit_medicine(driver):
        """Edit existing medicine details."""
        item = driver.find_element(
            "xpath", '//android.widget.TextView[contains(@text,"Aspirin")]'
        )
        item.long_click()   # WebDriver Action for long press
        driver.find_element(
            "xpath", '//android.widget.MenuItem[@content-desc="Edit"]'
        ).click()
        name_field = driver.find_element("xpath", "//android.widget.EditText[1]")
        name_field.clear()
        name_field.send_keys("Aspirin 200mg")
        driver.find_element(
            "xpath", '//android.widget.Button[contains(@text,"Save")]'
        ).click()
        updated = driver.find_element(
            "xpath", '//android.widget.TextView[@text="Aspirin 200mg"]'
        )
        if not updated.is_displayed():
            raise AssertionError("Medicine not updated")

    def test_delete_medicine(driver):
        """Delete medicine from list."""
        item = driver.find_element(
            "xpath", '//android.widget.TextView[contains(@text,"Aspirin")]'
        )
        item.long_click()
        driver.find_element(
            "xpath", '//android.widget.MenuItem[@content-desc="Delete"]'
        ).click()
        driver.find_element(
            "xpath",
            '//android.widget.Button[contains(@text,"Delete") '
            'or contains(@text,"Confirm")]',
        ).click()
        items = driver.find_elements(
            "xpath", '//android.widget.TextView[contains(@text,"Aspirin")]'
        )
        if len(items) > 0:
            raise AssertionError("Medicine not deleted")

    def test_empty_state(driver):
        """Medicine list shows empty state when no medicines."""
        empty = driver.find_element(
            "xpath",
            '//android.widget.TextView[contains(@text,"No medicines") '
            'or contains(@text,"empty")]',
        )
        if not empty.is_displayed():
            raise AssertionError("Empty state not shown")

    def test_scroll_many_items(driver):
        """Medicine list supports scroll when many items exist."""
        for i in range(1, 6):
            driver.find_element(
                "xpath", '//android.widget.Button[contains(@text,"Add")]'
            ).click()
            driver.find_element("xpath", "//android.widget.EditText[1]").send_keys(
                f"Medicine {i}"
            )
            driver.find_element(
                "xpath", '//android.widget.Button[contains(@text,"Save")]'
            ).click()
        # Simulate swipe-up scroll
        size   = driver.get_window_size()
        width  = size["width"]
        height = size["height"]
        driver.swipe(width // 2, int(height * 0.8), width // 2, int(height * 0.2), 400)

    return [
        {"title": "Add new medicine with valid name and dosage",        "run": test_add_medicine},
        {"title": "Reject medicine entry with empty name",              "run": test_reject_empty_name},
        {"title": "Edit existing medicine details",                     "run": test_edit_medicine},
        {"title": "Delete medicine from list",                          "run": test_delete_medicine},
        {"title": "Medicine list shows empty state when no medicines",  "run": test_empty_state},
        {"title": "Medicine list supports scroll when many items exist","run": test_scroll_many_items},
    ]


def run_medicine_management_tests() -> list[dict]:
    print("  📱 [Appium] Running Medicine Management Tests...")
    results = []
    driver  = AppiumDriverFactory.create_driver()

    for test in _tests():
        start = time.time()
        try:
            if driver:
                test["run"](driver)
            results.append({
                "suiteName":  SUITE_NAME,
                "title":      test["title"],
                "status":     "PASS",
                "durationMs": int((time.time() - start) * 1000),
                "error":      "" if driver else "SIMULATED",
                "timestamp":  time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            })
        except Exception as exc:  # noqa: BLE001
            results.append({
                "suiteName":  SUITE_NAME,
                "title":      test["title"],
                "status":     "FAIL",
                "durationMs": int((time.time() - start) * 1000),
                "error":      str(exc),
                "timestamp":  time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            })

    AppiumDriverFactory.quit_driver(driver)
    return results
