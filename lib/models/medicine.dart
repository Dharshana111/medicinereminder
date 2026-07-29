import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Medicine {
  final String id;
  final String name;
  final String description;
  final String dosage;
  final String? imagePath;
  final List<TimeOfDay> scheduleTimes;
  final String frequency; // daily, weekly, one_time
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  Medicine({
    String? id,
    required this.name,
    required this.description,
    required this.dosage,
    this.imagePath,
    required this.scheduleTimes,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Medicine copyWith({
    String? name,
    String? description,
    String? dosage,
    String? imagePath,
    List<TimeOfDay>? scheduleTimes,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Medicine(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      dosage: dosage ?? this.dosage,
      imagePath: imagePath ?? this.imagePath,
      scheduleTimes: scheduleTimes ?? this.scheduleTimes,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dosage': dosage,
      'imagePath': imagePath,
      'scheduleTimes': scheduleTimes
          .map((t) => {'hour': t.hour, 'minute': t.minute})
          .toList(),
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      dosage: json['dosage'] as String,
      imagePath: json['imagePath'] as String?,
      scheduleTimes: (json['scheduleTimes'] as List)
          .map((t) => TimeOfDay(
                hour: t['hour'] as int,
                minute: t['minute'] as int,
              ))
          .toList(),
      frequency: json['frequency'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory Medicine.fromJsonString(String jsonString) {
    return Medicine.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Get the next upcoming schedule time from now
  TimeOfDay? getNextScheduleTime() {
    final now = TimeOfDay.now();
    final upcoming = scheduleTimes.where((t) {
      return t.hour > now.hour || (t.hour == now.hour && t.minute > now.minute);
    }).toList();

    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });

    return upcoming.first;
  }

  /// Format schedule times as readable string
  String get formattedSchedule {
    return scheduleTimes.map((t) {
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final minute = t.minute.toString().padLeft(2, '0');
      final period = t.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }).join(', ');
  }

  /// Get frequency display text
  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'one_time':
        return 'One Time';
      default:
        return frequency;
    }
  }
}
