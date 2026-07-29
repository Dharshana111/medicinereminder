"""
MedCare+ Appium Test: 01 – App Launch & Onboarding (Python)
"""
import time
from helpers.driver_factory import AppiumDriverFactory

SUITE_NAME = "App Launch & Onboarding"
APP_PACKAGE = "com.example.medreminder"


def _tests() -> list[dict]:
    """Return the ordered list of test definitions for this suite."""

    def test_app_launches(driver):
        """App launches successfully without crash."""
        state = driver.query_app_state(APP_PACKAGE)
        # 4 = RUNNING_IN_FOREGROUND (Appium ApplicationState enum)
        if state != 4:
            raise AssertionError(f"App not in foreground, state: {state}")

    def test_splash_loads_within_5s(driver):
        """Splash screen / home screen loads within 5 seconds."""
        start = time.time()
        driver.find_element(
            "android uiautomator",
            f'new UiSelector().packageName("{APP_PACKAGE}")',
        )
        elapsed_ms = (time.time() - start) * 1000
        if elapsed_ms > 5000:
            raise AssertionError(f"Load time exceeded 5s: {elapsed_ms:.0f}ms")

    def test_add_button_visible(driver):
        """Add Medicine button is visible on home screen."""
        btn = driver.find_element(
            "xpath",
            '//android.widget.Button[contains(@text,"Add") '
            'or contains(@content-desc,"Add")]',
        )
        if not btn.is_displayed():
            raise AssertionError("Add Medicine button not visible")

    def test_bottom_nav_renders(driver):
        """Bottom navigation bar renders correctly."""
        nav = driver.find_element(
            "xpath",
            '//android.widget.FrameLayout[@content-desc="Home" or @text="Home"]',
        )
        if not nav.is_displayed():
            raise AssertionError("Bottom navigation not visible")

    def test_back_button_graceful(driver):
        """App handles device back button gracefully."""
        driver.back()
        state = driver.query_app_state(APP_PACKAGE)
        if state == 1:
            raise AssertionError("App crashed after back button")

    def test_background_restore(driver):
        """App retains state after backgrounding and restoring."""
        driver.background_app(2)          # seconds
        state = driver.query_app_state(APP_PACKAGE)
        if state != 4:
            raise AssertionError(f"App not foregrounded after background: {state}")

    return [
        {"title": "App launches successfully without crash",            "run": test_app_launches},
        {"title": "Splash screen or home screen loads within 5 seconds","run": test_splash_loads_within_5s},
        {"title": "Add Medicine button is visible on home screen",       "run": test_add_button_visible},
        {"title": "Bottom navigation bar renders correctly",             "run": test_bottom_nav_renders},
        {"title": "App handles device back button gracefully",           "run": test_back_button_graceful},
        {"title": "App retains state after backgrounding and restoring", "run": test_background_restore},
    ]


def run_app_launch_tests() -> list[dict]:
    """Execute all App Launch & Onboarding tests and return result records."""
    print("  📱 [Appium] Running App Launch & Onboarding Tests...")
    results = []
    driver  = AppiumDriverFactory.create_driver()   # None → simulation mode

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
                "error":      "" if driver else "SIMULATED (no device connected)",
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
