import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/user_profile_model.dart';

class UserService {
  final List<String> _defaultCategories = [
    'Reminder Belajar',
    'Saran Materi',
    'Fakta Menarik',
    'Tips Belajar'
  ];

  Future<UserProfile?> getOrCreateUserProfile(
    User user, {
    String? fullName,
  }) async {
    try {
      final response = await supabase
          .from('users')
          .select()
          .eq('auth_uid', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST116') {
        final nameToUse = fullName ?? user.email?.split('@').first;

        final newProfileData = {
          'auth_uid': user.id,
          'email': user.email ?? 'no-email@fintrack.com',
          'full_name': nameToUse,
          'default_tz': 'WIB',
          'ai_reminder_prefs': _defaultCategories,
        };

        try {
          final newResponse = await supabase
              .from('users')
              .insert(newProfileData)
              .select()
              .single();

          return UserProfile.fromJson(newResponse);
        } catch (insertError) {
          debugPrint('Fatal Error inserting new user profile: $insertError');
          return null;
        }
      }

      debugPrint('General Error fetching user profile: $e');
      return null;
    }
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      await supabase
          .from('users')
          .update(profile.toJsonForUpdate())
          .eq('id', profile.id);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST UPDATE PROFILE ERROR: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('General Error updating profile: $e');
      return false;
    }
  }

  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      final fileExtension = imageFile.path.split('.').last;
      final filePath = '$userId/profile.$fileExtension';

      await supabase.storage.from('profiles').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicUrl =
          supabase.storage.from('profiles').getPublicUrl(filePath);

      return '$publicUrl?t=$timestamp';
    } on StorageException catch (e) {
      debugPrint('🚨 STORAGE UPLOAD PROFILE ERROR: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('General Error uploading profile picture: $e');
      return null;
    }
  }

  Future<bool> updateAiReminderPrefs({
    required String userId,
    required List<String> prefs,
  }) async {
    try {
      await supabase
          .from('users')
          .update({'ai_reminder_prefs': prefs}).eq('id', userId);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('🚨 POSTGREST UPDATE AI PREFS ERROR: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('General Error updating AI prefs: $e');
      return false;
    }
  }
}
