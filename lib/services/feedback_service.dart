import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  Future<FeedbackModel?> getFeedback(String userId) async {
    try {
      final response = await supabase
          .from('user_feedback')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }
      return FeedbackModel.fromSupabaseJson(response);
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR getFeedback: ${e.message}');
      return null;
    }
  }

  Future<bool> saveFeedback(FeedbackModel feedback) async {
    try {
      await supabase.from('user_feedback').upsert(
            feedback.toSupabaseUpsertJson(),
            onConflict: 'user_id',
          );

      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR saveFeedback: ${e.message}');
      return false;
    }
  }
}
