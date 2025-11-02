// File: lib/services/feedback_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../main.dart'; // Akses supabase
import '../models/feedback_model.dart';

class FeedbackService {
  // 1. Ambil feedback yang sudah ada (jika ada)
  Future<FeedbackModel?> getFeedback(String userId) async {
    try {
      final response = await supabase
          .from('user_feedback')
          .select()
          .eq('user_id', userId)
          .maybeSingle(); // Ambil satu atau null

      if (response == null) {
        return null; // Pengguna belum pernah input
      }
      return FeedbackModel.fromSupabaseJson(response);
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR getFeedback: ${e.message}');
      return null;
    }
  }

  // 2. Simpan atau Update feedback (UPSERT)
  Future<bool> saveFeedback(FeedbackModel feedback) async {
    try {
      // --- PERUBAHAN DI SINI ---
      // Panggil method baru yang tidak mengirim 'id' atau 'created_at'
      await supabase.from('user_feedback').upsert(
            feedback.toSupabaseUpsertJson(), // <-- Ganti ke method baru
            onConflict: 'user_id', // Jika user_id sudah ada, update
          );
      // -------------------------
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR saveFeedback: ${e.message}');
      return false;
    }
  }
}
