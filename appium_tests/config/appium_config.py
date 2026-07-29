"""
MedCare+ Appium Mobile Test Configuration (Python)
"""
import os

# ── Platform ──────────────────────────────────────────────────────────────────
PLATFORM = os.environ.get("PLATFORM", "android")

# ── Appium Server ─────────────────────────────────────────────────────────────
APPIUM_HOST = os.environ.get("APPIUM_HOST", "127.0.0.1")
APPIUM_PORT = int(os.environ.get("APPIUM_PORT", "4723"))

# ── Base APK / App Paths ──────────────────────────────────────────────────────
_base = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))

ANDROID_APK = os.environ.get(
    "ANDROID_APK_PATH",
    os.path.join(_base, "build", "app", "outputs", "apk", "debug", "app-debug.apk"),
)

IOS_APP = os.environ.get(
    "IOS_APP_PATH",
    os.path.join(_base, "build", "ios", "iphonesimulator", "Runner.app"),
)

# ── Android Capabilities ──────────────────────────────────────────────────────
ANDROID_CAPS = {
    "platformName": "Android",
    "appium:platformVersion": os.environ.get("ANDROID_VERSION", "13.0"),
    "appium:deviceName": os.environ.get("ANDROID_DEVICE", "emulator-5554"),
    "appium:app": ANDROID_APK,
    "appium:appPackage": "com.example.medreminder",
    "appium:appActivity": "com.example.medreminder.MainActivity",
    "appium:automationName": "UiAutomator2",
    "appium:noReset": False,
    "appium:fullReset": False,
    "appium:newCommandTimeout": 60,
}

# ── iOS Capabilities ──────────────────────────────────────────────────────────
IOS_CAPS = {
    "platformName": "iOS",
    "appium:platformVersion": os.environ.get("IOS_VERSION", "17.0"),
    "appium:deviceName": os.environ.get("IOS_DEVICE", "iPhone 15"),
    "appium:app": IOS_APP,
    "appium:bundleId": "com.example.medreminder",
    "appium:automationName": "XCUITest",
    "appium:noReset": False,
    "appium:newCommandTimeout": 60,
}

CAPS = ANDROID_CAPS if PLATFORM == "android" else IOS_CAPS

# ── Timeouts (seconds) ────────────────────────────────────────────────────────
IMPLICIT_WAIT  = 8
EXPLICIT_WAIT  = 15
COMMAND_TIMEOUT = 30

# ── Reports ───────────────────────────────────────────────────────────────────
REPORTS_DIR = os.path.join(os.path.dirname(__file__), "..", "reports")
