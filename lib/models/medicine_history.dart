import 'dart:convert';
import 'package:uuid/uuid.dart';

class MedicineHistory {
  final String id;
  final String medicineId;
  final String medicineName;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final String status; // taken, missed, late, pending

  MedicineHistory({
    String? id,
    required this.medicineId,
    required this.medicineName,
    required this.scheduledTime,
    this.takenTime,
    this.status = 'pending',
  }) : id = id ?? const Uuid().v4();

  MedicineHistory copyWith({
    DateTime? takenTime,
    String? status,
  }) {
    return MedicineHistory(
      id: id,
      medicineId: medicineId,
      medicineName: medicineName,
      scheduledTime: scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'scheduledTime': scheduledTime.toIso8601String(),
      'takenTime': takenTime?.toIso8601String(),
      'status': status,
    };
  }

  factory MedicineHistory.fromJson(Map<String, dynamic> json) {
    return MedicineHistory(
      id: json['id'] as String,
      medicineId: json['medicineId'] as String,
      medicineName: json['medicineName'] as String,
      scheduledTime: DateTime.parse(json['scheduledTime'] as String),
      takenTime: json['takenTime'] != null
          ? DateTime.parse(json['takenTime'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory MedicineHistory.fromJsonString(String jsonString) {
    return MedicineHistory.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }

  bool get isTaken => status == 'taken';
  bool get isMissed => status == 'missed';
  bool get isLate => status == 'late';
  bool get isPending => status == 'pending';

  /// Check if the scheduled time has passed (with 30 min grace period)
  bool get isOverdue {
    if (status != 'pending') return false;
    return DateTime.now().difference(scheduledTime).inMinutes > 30;
  }
}
