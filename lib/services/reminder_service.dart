import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/reminder_model.dart';
import 'notification_service.dart';

class ReminderService {
  final NotificationService _notificationService = NotificationService();

  Future<bool> addReminder({
    required Reminder reminder,
    required String currentUserId,
  }) async {
    try {
      final insertMap = reminder.toSupabaseJson();
      insertMap['user_id'] = currentUserId;

      final response =
          await supabase.from('reminders').insert(insertMap).select().single();

      final newReminder = Reminder.fromSupabaseJson(response);

      await _notificationService.scheduleWeeklyNotification(newReminder);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR addReminder: ${e.message}');
      return false;
    }
  }

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

  Future<bool> updateReminder(Reminder reminder) async {
    try {
      await supabase
          .from('reminders')
          .update(reminder.toSupabaseUpdateJson())
          .eq('id', reminder.id);

      await _notificationService.scheduleWeeklyNotification(reminder);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR updateReminder: ${e.message}');
      return false;
    }
  }

  Future<bool> deleteReminder(String id) async {
    try {
      await supabase.from('reminders').delete().eq('id', id);

      await _notificationService.cancelNotification(id);

      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR deleteReminder: ${e.message}');
      return false;
    }
  }
}
