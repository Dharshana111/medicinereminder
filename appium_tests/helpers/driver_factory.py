"""
MedCare+ Appium Driver Factory (Python)
Creates and destroys Appium WebDriver sessions.
In CI or simulation mode, instantly returns None to execute fast simulated tests.
"""
import os
import warnings
from config.appium_config import APPIUM_HOST, APPIUM_PORT, CAPS, IMPLICIT_WAIT

try:
    from appium import webdriver
    try:
        from appium.options.common.base import AppiumOptions
    except ImportError:
        try:
            from appium.options import AppiumOptions
        except ImportError:
            AppiumOptions = None
except ImportError:
    webdriver = None
    AppiumOptions = None


class AppiumDriverFactory:
    """Factory for creating and quitting Appium WebDriver sessions."""

    @staticmethod
    def create_driver(caps: dict | None = None):
        """
        Create an Appium Remote driver.
        Returns a live driver instance, or None if unreachable / in simulation mode.
        """
        # Fast path for CI / simulation mode
        if os.environ.get("APPIUM_SIMULATE") == "true" or os.environ.get("CI") == "true":
            return None

        if webdriver is None or AppiumOptions is None:
            return None

        capabilities = caps or CAPS
        try:
            options = AppiumOptions().load_capabilities(capabilities)
            driver = webdriver.Remote(
                command_executor=f"http://{APPIUM_HOST}:{APPIUM_PORT}",
                options=options,
            )
            driver.implicitly_wait(IMPLICIT_WAIT)
            return driver
        except Exception as exc:  # noqa: BLE001
            warnings.warn(
                f"⚠ Appium server not running. Running in SIMULATION mode: {exc}",
                stacklevel=2,
            )
            return None

    @staticmethod
    def quit_driver(driver) -> None:
        """Safely terminate an Appium session."""
        if driver is not None:
            try:
                driver.quit()
            except Exception as exc:  # noqa: BLE001
                print(f"  ⚠ Warning: Could not cleanly close Appium session: {exc}")
