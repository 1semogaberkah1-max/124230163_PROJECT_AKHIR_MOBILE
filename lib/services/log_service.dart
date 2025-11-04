import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/learning_log_model.dart';

class LogService {
  Future<bool> addLog(LearningLog log) async {
    try {
      await supabase.from('learning_logs').insert(log.toSupabaseJson());
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('General Error adding log: $e');
      return false;
    }
  }

  Future<List<LearningLog>> getLogs() async {
    try {
      final List<dynamic> response = await supabase
          .from('learning_logs')
          .select()
          .order('txn_timestamp', ascending: false);

      return response
          .map(
            (data) =>
                LearningLog.fromSupabaseJson(data as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST ERROR fetching logs: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('General Error fetching logs: $e');
      return [];
    }
  }

  Future<bool> updateLog(LearningLog log) async {
    try {
      await supabase
          .from('learning_logs')
          .update(log.toSupabaseJson())
          .eq('id', log.id!);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST UPDATE ERROR: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('General Error updating log: $e');
      return false;
    }
  }

  Future<bool> deleteLog(String logId) async {
    try {
      await supabase.from('learning_logs').delete().eq('id', logId);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST DELETE ERROR: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('General Error deleting log: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getRecap({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_recap',
        params: {
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
        },
      );
      if (response != null && response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }
      return null;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST RPC ERROR (get_recap): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('General Error fetching recap: $e');
      return null;
    }
  }

  Future<String?> uploadImageToStorage(File imageFile, String userId) async {
    try {
      final fileExtension = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().toIso8601String()}.$fileExtension';
      final filePath = '$userId/$fileName';

      await supabase.storage.from('study_docs').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl =
          supabase.storage.from('study_docs').getPublicUrl(filePath);

      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('🚨 STORAGE UPLOAD ERROR: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('General Error uploading image: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> getTopMaterials({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_top_materials',
        params: {
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
        },
      );

      return (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST RPC ERROR (get_top_materials): ${e.message}');
      return [];
    } catch (e) {
      debugPrint('General Error fetching top materials: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>?> getTopLocations({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_top_locations',
        params: {
          'p_start_date': startDate.toIso8601String(),
          'p_end_date': endDate.toIso8601String(),
        },
      );

      return (response as List)
          .map((item) => item as Map<String, dynamic>)
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST RPC ERROR (get_top_locations): ${e.message}');
      return [];
    } catch (e) {
      debugPrint('General Error fetching top locations: $e');
      return [];
    }
  }
}
