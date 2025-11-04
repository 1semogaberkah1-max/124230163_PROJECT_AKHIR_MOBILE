import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String userId;
  final String title;
  final String scheduleDay;
  final TimeOfDay scheduleTime;
  final String timezone;
  final bool isActive;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.scheduleDay,
    required this.scheduleTime,
    required this.timezone,
    required this.isActive,
    required this.createdAt,
  });

  static TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  factory Reminder.fromSupabaseJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      scheduleDay: json['schedule_day'] as String,
      scheduleTime: _parseTime(json['schedule_time'] as String),
      timezone: json['timezone'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String _formatTime() {
    return '${scheduleTime.hour.toString().padLeft(2, '0')}:${scheduleTime.minute.toString().padLeft(2, '0')}:00';
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'title': title,
      'schedule_day': scheduleDay,
      'schedule_time': _formatTime(),
      'timezone': timezone,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toSupabaseUpdateJson() {
    return {
      'title': title,
      'schedule_day': scheduleDay,
      'schedule_time': _formatTime(),
      'timezone': timezone,
      'is_active': isActive,
    };
  }
}
