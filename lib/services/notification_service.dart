import 'dart:async';
import 'package:universal_io/io.dart' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:medreminder/models/medicine.dart';
import 'package:medreminder/models/medicine_history.dart';
import 'package:medreminder/services/storage_service.dart';
import 'package:medreminder/utils/constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static final List<Timer> _activeTimers = [];

  /// Initialize notifications and TTS
  static Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone data
    tzdata.initializeTimeZones();
    try {
      // DateTime.timeZoneName works on all platforms including web without plugins
      final String timeZoneName = DateTime.now().timeZoneName;
      // timeZoneName may be an abbreviation (e.g. 'IST') so try to find it,
      // fall back to UTC if not found in the timezone database
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('Local timezone initialized to: $timeZoneName');
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
        debugPrint('Timezone "$timeZoneName" not in database, using UTC.');
      }
    } catch (e) {
      debugPrint('Failed to get local timezone: $e. Falling back to UTC.');
      tz.setLocalLocation(tz.UTC);
    }

    try {
      if (!kIsWeb) {
        // Android initialization settings
        const androidSettings = AndroidInitializationSettings(
          'ic_notification',
        );

        const initSettings = InitializationSettings(
          android: androidSettings,
        );

        await _notifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );

        if (Platform.isAndroid) {
          // Create notification channel for Android
          const androidChannel = AndroidNotificationChannel(
            AppConstants.notificationChannelId,
            AppConstants.notificationChannelName,
            description: AppConstants.notificationChannelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          );

          await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(androidChannel);

          // Request notification permissions
          await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission();

          // Request exact alarm permissions for Android 12+
          if (await Permission.scheduleExactAlarm.isDenied) {
            await Permission.scheduleExactAlarm.request();
          }
        }
      }
    } catch (e) {
      debugPrint('Notification initialization skipped/failed: $e');
    }

    // Initialize TTS
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
    } catch (e) {
      debugPrint('TTS initialization skipped/failed: $e');
    }

    _initialized = true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) async {
    debugPrint(
      'Notification tapped: ${response.id} - ${response.payload} - Action: ${response.actionId}',
    );

    if (kIsWeb) return;

    // Dismiss the notification upon tapping any action button or background response
    if (response.id != null) {
      try {
        await _notifications.cancel(response.id!);
      } catch (e) {
        debugPrint('Failed to cancel notification on tap: $e');
      }
    }

    if (response.actionId == 'action_take') {
      // Mark the medicine as taken!
      if (response.payload != null) {
        final medicine = StorageService.getMedicineById(response.payload!);
        if (medicine != null) {
          final now = DateTime.now();
          final history = MedicineHistory(
            medicineId: medicine.id,
            medicineName: medicine.name,
            scheduledTime: now,
            takenTime: now,
            status: 'taken',
          );
          await StorageService.saveHistory(history);
          await speakTakeMedicineNow(medicine.name);
        }
      }
    } else if (response.actionId == 'action_snooze') {
      // Snooze: schedule another notification in 10 minutes!
      if (response.payload != null) {
        final medicine = StorageService.getMedicineById(response.payload!);
        if (medicine != null) {
          final snoozeTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 10)));
          await scheduleMedicineNotification(medicine, snoozeTime);
        }
      }
    }
  }

  /// Schedule a notification for a medicine at a specific time.
  /// Uses zonedSchedule with daily repeat for recurring reminders.
  static Future<void> scheduleMedicineNotification(
    Medicine medicine,
    TimeOfDay time,
  ) async {
    if (kIsWeb) {
      debugPrint('Notification scheduling is not supported on Web.');
      return;
    }

    try {
      final notificationId =
          (medicine.id.hashCode + time.hour * 60 + time.minute) & 0x7FFFFFFF;

      final androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
        playSound: true,
        enableVibration: true,
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            'action_take',
            '💊 Take',
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'action_snooze',
            '⏰ Snooze',
            showsUserInterface: true,
          ),
        ],
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      // Calculate the next occurrence of this time using device-local timezone calculations
      final scheduledDate = _nextInstanceOfTime(time);

      // Ensure we have exact alarm permission before using exact modes to avoid crashes or failures on Android 13/14+
      bool hasExactAlarmPermission = false;
      if (Platform.isAndroid) {
        hasExactAlarmPermission = await Permission.scheduleExactAlarm.isGranted;
      }
      final scheduleMode = hasExactAlarmPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _notifications.zonedSchedule(
        notificationId,
        '💊 Medicine Reminder',
        'Time to take ${medicine.name} - ${medicine.dosage}',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: medicine.id,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Calculate the next occurrence of a given TimeOfDay as a TZDateTime.
  /// Uses device local time and safely maps to the timezone location to guarantee absolute exact correctness.
  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final nowLocal = DateTime.now();
    var scheduledLocal = DateTime(
      nowLocal.year,
      nowLocal.month,
      nowLocal.day,
      time.hour,
      time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledLocal.isBefore(nowLocal)) {
      scheduledLocal = scheduledLocal.add(const Duration(days: 1));
    }

    return tz.TZDateTime.from(scheduledLocal, tz.local);
  }

  /// Cancel all notifications for a specific medicine.
  /// Optimally cancels only the scheduled times for the medicine to run instantly on all platforms.
  static Future<void> cancelMedicineNotifications(Medicine medicine) async {
    if (kIsWeb) return;
    try {
      for (final time in medicine.scheduleTimes) {
        final notificationId = (medicine.id.hashCode + time.hour * 60 + time.minute) & 0x7FFFFFFF;
        await _notifications.cancel(notificationId);
      }
    } catch (e) {
      debugPrint('Failed to cancel notifications: $e');
    }
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    try {
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Failed to cancel all notifications: $e');
    }
  }

  /// Use TTS to speak a medicine reminder aloud
  static Future<void> speakReminder(String medicineName) async {
    await _tts.speak(
      'It is time to take your medicine: $medicineName',
    );
  }

  /// Use TTS to say "Take your medicine now: [medicineName]"
  static Future<void> speakTakeMedicineNow(String medicineName) async {
    await _tts.speak(
      'Take your medicine now: $medicineName',
    );
  }

  /// Schedule voice alerts using Timers for all active medicines' schedule times today
  static void scheduleVoiceAlerts() {
    // Cancel existing active timers
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();

    final medicines = StorageService.getMedicines().where((m) => m.isActive);
    final now = DateTime.now();

    for (final medicine in medicines) {
      for (final time in medicine.scheduleTimes) {
        final scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        if (scheduledDateTime.isBefore(now)) {
          // Skip times that have already passed today
          continue;
        }

        final delay = scheduledDateTime.difference(now);
        final timer = Timer(delay, () {
          speakTakeMedicineNow(medicine.name);
        });
        _activeTimers.add(timer);
      }
    }
  }
}
