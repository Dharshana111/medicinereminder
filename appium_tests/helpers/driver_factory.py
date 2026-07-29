"""
MedCare+ Appium Driver Factory (Python)
Creates and destroys Appium WebDriver sessions.
"""
import warnings
from appium import webdriver
from appium.options import AppiumOptions
from config.appium_config import APPIUM_HOST, APPIUM_PORT, CAPS, IMPLICIT_WAIT


class AppiumDriverFactory:
    """Factory for creating and quitting Appium WebDriver sessions."""

    @staticmethod
    def create_driver(caps: dict | None = None) -> webdriver.Remote | None:
        """
        Create an Appium Remote driver.

        Parameters
        ----------
        caps : dict | None
            Override capabilities; defaults to the platform caps from config.

        Returns
        -------
        webdriver.Remote | None
            A live driver instance, or None if the server is unreachable.
        """
        capabilities = caps or CAPS
        options = AppiumOptions().load_capabilities(capabilities)
        try:
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
    def quit_driver(driver: webdriver.Remote | None) -> None:
        """
        Safely terminate an Appium session.

        Parameters
        ----------
        driver : webdriver.Remote | None
            The driver to quit. Safe to call with None.
        """
        if driver is not None:
            try:
                driver.quit()
            except Exception as exc:  # noqa: BLE001
                print(f"  ⚠ Warning: Could not cleanly close Appium session: {exc}")
