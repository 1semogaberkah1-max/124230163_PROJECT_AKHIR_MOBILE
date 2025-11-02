// File: lib/services/reminder_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../main.dart'; // Akses supabase
import '../models/reminder_model.dart';
import 'notification_service.dart'; // <-- IMPORT BARU

class ReminderService {
  // --- SERVICE NOTIFIKASI ---
  final NotificationService _notificationService = NotificationService();
  // --------------------------

  // 1. CREATE
  Future<bool> addReminder({
    required Reminder reminder,
    required String currentUserId,
  }) async {
    try {
      final insertMap = reminder.toSupabaseJson();
      insertMap['user_id'] = currentUserId;

      final response = await supabase
          .from('reminders')
          .insert(insertMap)
          .select() // Ambil data yang baru dibuat
          .single();

      // Buat objek Reminder lengkap dengan ID baru
      final newReminder = Reminder.fromSupabaseJson(response);

      // --- Jadwalkan Notifikasi ---
      await _notificationService.scheduleWeeklyNotification(newReminder);
      // ----------------------------
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR addReminder: ${e.message}');
      return false;
    }
  }

  // 2. READ
  Future<List<Reminder>> getReminders() async {
    try {
      final List<dynamic> response = await supabase
          .from('reminders')
          .select()
          .order('schedule_time', ascending: true);

      return response
          .map(
            (data) => Reminder.fromSupabaseJson(data as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR getReminders: ${e.message}');
      return [];
    }
  }

  // 3. UPDATE
  Future<bool> updateReminder(Reminder reminder) async {
    try {
      await supabase
          .from('reminders')
          .update(reminder.toSupabaseUpdateJson())
          .eq('id', reminder.id);

      // --- Perbarui Notifikasi ---
      // Jika 'isActive' = true, schedule ulang.
      // Jika 'isActive' = false, schedule ulang akan otomatis membatalkannya.
      await _notificationService.scheduleWeeklyNotification(reminder);
      // --------------------------
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR updateReminder: ${e.message}');
      return false;
    }
  }

  // 4. DELETE
  Future<bool> deleteReminder(String id) async {
    try {
      await supabase.from('reminders').delete().eq('id', id);

      // --- Batalkan Notifikasi ---
      await _notificationService.cancelNotification(id);
      // --------------------------
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR deleteReminder: ${e.message}');
      return false;
    }
  }
}
