class AppConstants {
  // App Info
  static const String appName = 'MedCare+';
  static const String appTagline = 'Your Health, On Time';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String keyUserProfile = 'user_profile';
  static const String keyMedicines = 'medicines';
  static const String keyMedicineHistory = 'medicine_history';
  static const String keyIsRegistered = 'is_registered';
  static const String keyNotificationSettings = 'notification_settings';

  // Notification
  static const String notificationChannelId = 'medcare_reminders';
  static const String notificationChannelName = 'Medicine Reminders';
  static const String notificationChannelDesc = 'Notifications for medicine reminders';
  static const int notificationBaseId = 1000;

  // Frequency
  static const String frequencyDaily = 'daily';
  static const String frequencyWeekly = 'weekly';
  static const String frequencyOneTime = 'one_time';

  // Status
  static const String statusTaken = 'taken';
  static const String statusMissed = 'missed';
  static const String statusLate = 'late';
  static const String statusPending = 'pending';

  // Threshold Logic Weights
  static const double weightTimeDelta = 0.4;
  static const double weightMissedCount = 0.35;
  static const double weightPriority = 0.25;
  static const double notificationThreshold = 0.5;

  // Blood Group Options
  static const List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  // Gender Options
  static const List<String> genders = ['Male', 'Female', 'Other'];

  // Splash Duration
  static const Duration splashDuration = Duration(milliseconds: 2500);
}
