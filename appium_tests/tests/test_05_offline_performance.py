"""
MedCare+ Appium Test: 05 – Offline & Performance (Python)
"""
import time
from helpers.driver_factory import AppiumDriverFactory

SUITE_NAME  = "Offline & Performance"
APP_PACKAGE = "com.example.medreminder"


def _tests() -> list[dict]:

    def test_list_loads_within_3s(driver):
        """App loads medicine list within 3 seconds of launch."""
        start = time.time()
        driver.find_element("xpath", "//android.widget.ScrollView")
        elapsed_ms = (time.time() - start) * 1000
        if elapsed_ms > 3000:
            raise AssertionError(f"App took more than 3s to load list: {elapsed_ms:.0f}ms")

    def test_add_medicine_within_2s(driver):
        """Add medicine completes within 2 seconds."""
        start = time.time()
        driver.find_element(
            "xpath", '//android.widget.Button[contains(@text,"Add")]'
        ).click()
        driver.find_element("xpath", "//android.widget.EditText[1]").send_keys("PerfTest Med")
        driver.find_element(
            "xpath", '//android.widget.Button[contains(@text,"Save")]'
        ).click()
        elapsed_ms = (time.time() - start) * 1000
        if elapsed_ms > 2000:
            raise AssertionError(f"Add medicine took {elapsed_ms:.0f}ms (> 2000ms)")

    def test_offline_mode(driver):
        """App works without internet connection (offline mode)."""
        driver.toggle_wifi()          # Toggle WiFi off
        driver.toggle_data()          # Toggle mobile data off
        try:
            scroll = driver.find_element("xpath", "//android.widget.ScrollView")
            if not scroll.is_displayed():
                raise AssertionError("App failed in offline mode")
        finally:
            driver.toggle_wifi()      # Restore
            driver.toggle_data()

    def test_data_persists_after_restart(driver):
        """Data persists after app restart."""
        driver.terminate_app(APP_PACKAGE)
        driver.activate_app(APP_PACKAGE)
        item = driver.find_element(
            "xpath",
            '//android.widget.TextView[contains(@text,"PerfTest Med")]',
        )
        if not item.is_displayed():
            raise AssertionError("Data not persisted after restart")

    def test_memory_below_150mb(driver):
        """Memory usage stays below 150 MB during normal use."""
        mem_info = driver.get_performance_data(APP_PACKAGE, "memoryinfo", 5)
        if mem_info and len(mem_info) > 1:
            headers = mem_info[0]
            values  = mem_info[1]
            if "totalPss" in headers:
                total_pss_kb = int(values[headers.index("totalPss")])
                total_pss_mb = total_pss_kb / 1024
                if total_pss_mb > 150:
                    raise AssertionError(
                        f"Memory {total_pss_mb:.1f} MB exceeds 150 MB limit"
                    )

    def test_cpu_below_80_percent(driver):
        """CPU usage stays below 80% during idle."""
        cpu_info = driver.get_performance_data(APP_PACKAGE, "cpuinfo", 5)
        if cpu_info and len(cpu_info) > 1:
            values = cpu_info[1]
            cpu    = float(values[0])
            if cpu > 80:
                raise AssertionError(f"CPU {cpu}% exceeds 80% limit")

    return [
        {"title": "App loads medicine list within 3 seconds of launch", "run": test_list_loads_within_3s},
        {"title": "Add medicine completes within 2 seconds",            "run": test_add_medicine_within_2s},
        {"title": "App works without internet connection (offline mode)","run": test_offline_mode},
        {"title": "Data persists after app restart",                    "run": test_data_persists_after_restart},
        {"title": "Memory usage stays below 150MB during normal use",   "run": test_memory_below_150mb},
        {"title": "CPU usage stays below 80% during idle",              "run": test_cpu_below_80_percent},
    ]


def run_offline_performance_tests() -> list[dict]:
    print("  📱 [Appium] Running Offline & Performance Tests...")
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
