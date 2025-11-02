// File: lib/services/notification_service.dart

import 'package:flutter/material.dart'; // Untuk TimeOfDay
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/reminder_model.dart'; // Import model Reminder

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 1. Inisialisasi dan Konfigurasi
  Future<void> init() async {
    await _configureLocalTimeZone();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (payload) {
        // Aksi saat notifikasi diklik
      },
    );
  }

  // Helper untuk setup timezone
  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    try {
      // Ambil objek TimezoneInfo, lalu ambil properti .identifier
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;

      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Gagal mengambil timezone: $e');
    }
  }

  // 2. Meminta Izin
  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    bool? androidResult = await androidPlugin?.requestNotificationsPermission();
    bool? exactAlarmResult =
        await androidPlugin?.requestExactAlarmsPermission();

    return (androidResult ?? true) && (exactAlarmResult ?? true);
  }

  // 3. Menjadwalkan Notifikasi
  Future<void> scheduleWeeklyNotification(Reminder reminder) async {
    await cancelNotification(reminder.id);
    if (!reminder.isActive) {
      return;
    }

    final tz.TZDateTime scheduledDate = _nextInstanceOf(
      day: reminder.scheduleDay,
      time: reminder.scheduleTime,
    );

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'study_reminder_channel_id_01',
      'Study Reminders',
      channelDescription: 'Channel untuk pengingat belajar harian',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      reminder.id.hashCode,
      'Waktunya Belajar! ⏰',
      reminder.title,
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // 4. Membatalkan Notifikasi
  Future<void> cancelNotification(String reminderId) async {
    await _notificationsPlugin.cancel(reminderId.hashCode);
  }

  // 5. Helper untuk Menghitung Jadwal Berikutnya
  tz.TZDateTime _nextInstanceOf(
      {required String day, required TimeOfDay time}) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (day == 'Setiap Hari') {
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      return scheduledDate;
    }

    final int targetWeekday = _dayToWeekday(day);

    if (scheduledDate.isBefore(now) && scheduledDate.weekday == targetWeekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    while (scheduledDate.weekday != targetWeekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  int _dayToWeekday(String day) {
    switch (day) {
      case 'Senin':
        return DateTime.monday;
      case 'Selasa':
        return DateTime.tuesday;
      case 'Rabu':
        return DateTime.wednesday;
      case 'Kamis':
        return DateTime.thursday;
      case 'Jumat':
        return DateTime.friday;
      case 'Sabtu':
        return DateTime.saturday;
      case 'Minggu':
        return DateTime.sunday;
      default:
        return DateTime.monday; // Default
    }
  }
}
