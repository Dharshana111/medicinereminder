import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medreminder/models/user_profile.dart';
import 'package:medreminder/models/medicine.dart';
import 'package:medreminder/models/medicine_history.dart';
import 'package:medreminder/utils/constants.dart';
import 'package:intl/intl.dart';

class StorageService {
  static late SharedPreferences _prefs;

  /// Initialize SharedPreferences instance
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── User Profile ──────────────────────────────────────────────────────

  /// Save user profile and mark registration as complete
  static Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setString(
      AppConstants.keyUserProfile,
      profile.toJsonString(),
    );
    await _prefs.setBool(AppConstants.keyIsRegistered, true);
  }

  /// Get the saved user profile, or null if none exists
  static UserProfile? getUserProfile() {
    final jsonString = _prefs.getString(AppConstants.keyUserProfile);
    if (jsonString == null) return null;
    try {
      return UserProfile.fromJsonString(jsonString);
    } catch (_) {
      return null;
    }
  }

  /// Whether the user has completed registration
  static bool get isRegistered =>
      _prefs.getBool(AppConstants.keyIsRegistered) ?? false;

  // ─── Medicines ─────────────────────────────────────────────────────────

  /// Get all saved medicines
  static List<Medicine> getMedicines() {
    final jsonString = _prefs.getString(AppConstants.keyMedicines);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => Medicine.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a new medicine to the stored list
  static Future<void> saveMedicine(Medicine medicine) async {
    final medicines = getMedicines();
    medicines.add(medicine);
    await _saveMedicineList(medicines);
  }

  /// Update an existing medicine by its ID
  static Future<void> updateMedicine(Medicine medicine) async {
    final medicines = getMedicines();
    final index = medicines.indexWhere((m) => m.id == medicine.id);
    if (index != -1) {
      medicines[index] = medicine;
      await _saveMedicineList(medicines);
    }
  }

  /// Delete a medicine by its ID
  static Future<void> deleteMedicine(String id) async {
    final medicines = getMedicines();
    medicines.removeWhere((m) => m.id == id);
    await _saveMedicineList(medicines);
  }

  /// Get a single medicine by ID, or null if not found
  static Medicine? getMedicineById(String id) {
    final medicines = getMedicines();
    try {
      return medicines.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Internal helper to persist the full medicine list
  static Future<void> _saveMedicineList(List<Medicine> medicines) async {
    final jsonList = medicines.map((m) => m.toJson()).toList();
    await _prefs.setString(AppConstants.keyMedicines, jsonEncode(jsonList));
  }

  // ─── Medicine History ──────────────────────────────────────────────────

  /// Get all history records
  static List<MedicineHistory> getHistory() {
    final jsonString = _prefs.getString(AppConstants.keyMedicineHistory);
    if (jsonString == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((e) => MedicineHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Add a new history entry
  static Future<void> saveHistory(MedicineHistory history) async {
    final historyList = getHistory();
    historyList.add(history);
    await _saveHistoryList(historyList);
  }

  /// Update an existing history entry by its ID
  static Future<void> updateHistory(MedicineHistory history) async {
    final historyList = getHistory();
    final index = historyList.indexWhere((h) => h.id == history.id);
    if (index != -1) {
      historyList[index] = history;
      await _saveHistoryList(historyList);
    }
  }

  /// Get history records for a specific date (same day)
  static List<MedicineHistory> getHistoryByDate(DateTime date) {
    return getHistory().where((h) {
      return h.scheduledTime.year == date.year &&
          h.scheduledTime.month == date.month &&
          h.scheduledTime.day == date.day;
    }).toList();
  }

  /// Get history records for a specific medicine
  static List<MedicineHistory> getHistoryForMedicine(String medicineId) {
    return getHistory().where((h) => h.medicineId == medicineId).toList();
  }

  /// Clear all history records
  static Future<void> clearHistory() async {
    await _prefs.remove(AppConstants.keyMedicineHistory);
  }

  /// Internal helper to persist the full history list
  static Future<void> _saveHistoryList(List<MedicineHistory> historyList) async {
    final jsonList = historyList.map((h) => h.toJson()).toList();
    await _prefs.setString(
      AppConstants.keyMedicineHistory,
      jsonEncode(jsonList),
    );
  }

  // ─── Statistics ────────────────────────────────────────────────────────

  /// Calculate adherence rate as a percentage over the last [days] days.
  /// Returns 0.0–100.0 (percentage of taken vs total non-pending entries).
  static double getAdherenceRate({int days = 7}) {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days));

    final recentHistory = getHistory().where((h) {
      return h.scheduledTime.isAfter(cutoff) &&
          h.status != AppConstants.statusPending;
    }).toList();

    if (recentHistory.isEmpty) return 0.0;

    final takenCount = recentHistory
        .where((h) =>
            h.status == AppConstants.statusTaken ||
            h.status == AppConstants.statusLate)
        .length;

    return (takenCount / recentHistory.length) * 100.0;
  }

  /// Get weekly stats: map of day abbreviations (Mon–Sun) to taken counts
  /// for the current week (last 7 days).
  static Map<String, int> getWeeklyStats() {
    final now = DateTime.now();
    final dayFormat = DateFormat('E'); // Mon, Tue, Wed, etc.
    final Map<String, int> stats = {};

    // Initialize all 7 days with 0
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = dayFormat.format(day);
      stats[label] = 0;
    }

    // Count taken entries per day
    final history = getHistory();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final label = dayFormat.format(day);

      final dayEntries = history.where((h) {
        return h.scheduledTime.year == day.year &&
            h.scheduledTime.month == day.month &&
            h.scheduledTime.day == day.day &&
            (h.status == AppConstants.statusTaken ||
                h.status == AppConstants.statusLate);
      });

      stats[label] = dayEntries.length;
    }

    return stats;
  }

  /// Count of medicines taken today
  static int getTodayTakenCount() {
    final today = DateTime.now();
    return getHistoryByDate(today)
        .where((h) =>
            h.status == AppConstants.statusTaken ||
            h.status == AppConstants.statusLate)
        .length;
  }

  /// Count of medicines missed today
  static int getTodayMissedCount() {
    final today = DateTime.now();
    return getHistoryByDate(today)
        .where((h) => h.status == AppConstants.statusMissed)
        .length;
  }

  /// Count of medicines still pending today
  static int getTodayPendingCount() {
    final today = DateTime.now();
    return getHistoryByDate(today)
        .where((h) => h.status == AppConstants.statusPending)
        .length;
  }
}
