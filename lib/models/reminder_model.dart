// File: lib/models/reminder_model.dart

import 'package:flutter/material.dart'; // Untuk TimeOfDay

class Reminder {
  final String id;
  final String userId;
  final String title;
  final String scheduleDay; // Misal: "Senin", "Selasa"
  final TimeOfDay scheduleTime; // Menggunakan TimeOfDay untuk kemudahan
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

  // Helper untuk mengubah 'HH:mm:ss' dari Supabase ke TimeOfDay
  static TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Dari Supabase JSON (READ)
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

  // Helper untuk mengubah TimeOfDay ke format 'HH:mm:ss'
  String _formatTime() {
    return '${scheduleTime.hour.toString().padLeft(2, '0')}:${scheduleTime.minute.toString().padLeft(2, '0')}:00';
  }

  // Untuk INSERT/UPDATE ke Supabase
  Map<String, dynamic> toSupabaseJson() {
    // Kita butuh 'user_id' saat INSERT, tapi tidak saat UPDATE
    // 'id' dan 'created_at' tidak pernah di-insert/update
    return {
      'user_id': userId,
      'title': title,
      'schedule_day': scheduleDay,
      'schedule_time': _formatTime(),
      'timezone': timezone,
      'is_active': isActive,
    };
  }

  // Map khusus untuk UPDATE (tanpa user_id)
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
