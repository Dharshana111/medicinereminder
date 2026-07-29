"""
MedCare+ Appium Test Runner (Python)
Mirrors run_appium_tests.js – orchestrates all five suites and saves an Excel report.

Usage
-----
    # From the appium_tests/ directory:
    python run_appium_tests.py                    # uses PLATFORM env var (default: android)
    PLATFORM=ios python run_appium_tests.py
"""
import sys
import time

# ── Make helper / config importable from any CWD ─────────────────────────────
import os
sys.path.insert(0, os.path.dirname(__file__))

from tests.test_01_app_launch          import run_app_launch_tests
from tests.test_02_medicine_management import run_medicine_management_tests
from tests.test_03_notifications       import run_notification_tests
from tests.test_04_ui_navigation       import run_ui_navigation_tests
from tests.test_05_offline_performance import run_offline_performance_tests

from helpers.appium_reporter           import AppiumExcelReporter
from config.appium_config              import PLATFORM


def execute_all_appium_tests() -> None:
    print()
    print("═══════════════════════════════════════════════════════════════════")
    print(f"📱 MEDCARE+ APPIUM MOBILE TEST FRAMEWORK  |  Platform: {PLATFORM.upper()}")
    print("═══════════════════════════════════════════════════════════════════\n")

    global_start = time.time()
    all_results: list[dict] = []

    suites = [
        {"id": 1, "name": "App Launch & Onboarding",  "runner": run_app_launch_tests},
        {"id": 2, "name": "Medicine Management",       "runner": run_medicine_management_tests},
        {"id": 3, "name": "Notifications & Reminders", "runner": run_notification_tests},
        {"id": 4, "name": "UI Navigation",             "runner": run_ui_navigation_tests},
        {"id": 5, "name": "Offline & Performance",     "runner": run_offline_performance_tests},
    ]

    for suite in suites:
        print(f"▶ [{suite['id']}/{len(suites)}] {suite['name']}")
        try:
            results = suite["runner"]()
            if isinstance(results, list):
                all_results.extend(results)
            print(f"  ✔ Completed {suite['name']}")
        except Exception as exc:  # noqa: BLE001
            print(f"  ✖ Suite failed: {exc}")
            all_results.append({
                "suiteName":  suite["name"],
                "title":      f"Suite {suite['id']} Execution",
                "status":     "FAIL",
                "durationMs": 0,
                "error":      str(exc),
                "timestamp":  time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            })

    # ── Summary ───────────────────────────────────────────────────────────────
    global_duration_ms = int((time.time() - global_start) * 1000)
    total   = len(all_results)
    passed  = sum(1 for r in all_results if r["status"] == "PASS")
    failed  = sum(1 for r in all_results if r["status"] == "FAIL")
    pass_rate = f"{(passed / total * 100):.1f}" if total > 0 else "0"

    print()
    print("═══════════════════════════════════════════════════════════════════")
    print("📊 APPIUM TEST SUMMARY")
    print("═══════════════════════════════════════════════════════════════════")
    print(f" Platform          : {PLATFORM.upper()}")
    print(f" Total Tests       : {total}")
    print(f" Passed            : {passed} ✅")
    print(f" Failed            : {failed} ❌")
    print(f" Pass Rate         : {pass_rate}%")
    print(f" Duration          : {global_duration_ms / 1000:.2f}s")
    print("═══════════════════════════════════════════════════════════════════\n")

    # ── Excel Report ──────────────────────────────────────────────────────────
    print("📝 Generating Appium Excel Report...")
    reporter = AppiumExcelReporter()
    paths = reporter.generate_report(
        all_results,
        {"total": total, "passed": passed, "failed": failed, "durationMs": global_duration_ms},
        PLATFORM,
    )

    print("✨ Report saved:")
    print(f"   📄 {paths['report_path']}")
    print(f"   📄 {paths['latest_report_path']}\n")


if __name__ == "__main__":
    try:
        execute_all_appium_tests()
    except Exception as exc:  # noqa: BLE001
        print(f"Fatal Appium Test Error: {exc}", file=sys.stderr)
        sys.exit(1)
