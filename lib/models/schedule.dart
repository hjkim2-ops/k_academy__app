import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'schedule.g.dart';

@HiveType(typeId: 1)
class Schedule extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String childName;

  @HiveField(2)
  final String academyName;

  @HiveField(3)
  final String subject;

  @HiveField(4)
  final String instructor;

  @HiveField(5)
  final int dayOfWeek; // 1=월, 2=화, 3=수, 4=목, 5=금, 6=토, 7=일

  @HiveField(6)
  final int startHour;

  @HiveField(7)
  final int startMinute;

  @HiveField(8)
  final int endHour;

  @HiveField(9)
  final int endMinute;

  @HiveField(10)
  final int colorValue;

  @HiveField(11)
  final bool isActive;

  @HiveField(12)
  final String? memo;

  @HiveField(13)
  final List<String> cancelledDates; // format: "yyyy-MM-dd"

  Schedule({
    required this.id,
    required this.childName,
    required this.academyName,
    required this.subject,
    required this.instructor,
    required this.dayOfWeek,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.colorValue,
    required this.isActive,
    this.memo,
    this.cancelledDates = const [],
  });

  TimeOfDay get startTime => TimeOfDay(hour: startHour, minute: startMinute);
  TimeOfDay get endTime => TimeOfDay(hour: endHour, minute: endMinute);
  Color get color => Color(colorValue);
  String get dayName => ['월', '화', '수', '목', '금', '토', '일'][dayOfWeek - 1];

  int get durationMinutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);

  String get timeRange {
    final s =
        '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';
    final e =
        '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
    return '$s ~ $e';
  }

  bool isCancelledOn(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return cancelledDates.contains(dateStr);
  }

  Map<String, dynamic> toMap() => {
        'childName': childName,
        'academyName': academyName,
        'subject': subject,
        'instructor': instructor,
        'dayOfWeek': dayOfWeek,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'colorValue': colorValue,
        'isActive': isActive,
        'memo': memo,
        'cancelledDates': cancelledDates,
      };

  factory Schedule.fromMap(String id, Map<String, dynamic> map) => Schedule(
        id: id,
        childName: map['childName'] ?? '',
        academyName: map['academyName'] ?? '',
        subject: map['subject'] ?? '',
        instructor: map['instructor'] ?? '',
        dayOfWeek: map['dayOfWeek'] ?? 1,
        startHour: map['startHour'] ?? 9,
        startMinute: map['startMinute'] ?? 0,
        endHour: map['endHour'] ?? 10,
        endMinute: map['endMinute'] ?? 0,
        colorValue: map['colorValue'] ?? 0xFF2196F3,
        isActive: map['isActive'] ?? true,
        memo: map['memo'],
        cancelledDates: List<String>.from(map['cancelledDates'] ?? []),
      );

  Schedule copyWith({
    String? childName,
    String? academyName,
    String? subject,
    String? instructor,
    int? dayOfWeek,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    int? colorValue,
    bool? isActive,
    String? memo,
    List<String>? cancelledDates,
  }) =>
      Schedule(
        id: id,
        childName: childName ?? this.childName,
        academyName: academyName ?? this.academyName,
        subject: subject ?? this.subject,
        instructor: instructor ?? this.instructor,
        dayOfWeek: dayOfWeek ?? this.dayOfWeek,
        startHour: startHour ?? this.startHour,
        startMinute: startMinute ?? this.startMinute,
        endHour: endHour ?? this.endHour,
        endMinute: endMinute ?? this.endMinute,
        colorValue: colorValue ?? this.colorValue,
        isActive: isActive ?? this.isActive,
        memo: memo ?? this.memo,
        cancelledDates: cancelledDates ?? this.cancelledDates,
      );
}
