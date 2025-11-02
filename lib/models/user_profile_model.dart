// File: lib/models/user_profile_model.dart

class UserProfile {
  final String id; // users.id (UUID)
  final String authUid; // auth.uid()
  final String email;
  final String? fullName;
  final String? photoUrl;
  final String defaultTz;
  final DateTime createdAt;
  final List<String> aiReminderPrefs; // List of selected reminder types

  UserProfile({
    required this.id,
    required this.authUid,
    required this.email,
    this.fullName,
    this.photoUrl,
    required this.defaultTz,
    required this.createdAt,
    required this.aiReminderPrefs,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Default categories jika data di Supabase null/kosong
    final List<String> defaultCategories = [
      'Reminder Belajar',
      'Saran Materi',
      'Fakta Menarik',
      'Tips Belajar'
    ];

    final List<dynamic>? rawPrefs = json['ai_reminder_prefs'];
    final List<String> prefs = (rawPrefs != null && rawPrefs.isNotEmpty)
        ? List<String>.from(rawPrefs.where((e) => e != null))
        : defaultCategories; // Fallback ke default

    return UserProfile(
      id: json['id'] as String,
      authUid: json['auth_uid'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      defaultTz: json['default_tz'] as String,
      createdAt: DateTime.parse(json['created_at']),
      aiReminderPrefs: prefs.toSet().toList(),
    );
  }

  // Digunakan oleh profile_screen.dart (copyWith)
  UserProfile copyWith({
    String? fullName,
    String? photoUrl,
    String? defaultTz,
  }) {
    return UserProfile(
      id: this.id,
      authUid: this.authUid,
      email: this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      defaultTz: defaultTz ?? this.defaultTz,
      createdAt: this.createdAt,
      aiReminderPrefs: this.aiReminderPrefs,
    );
  }

  // Digunakan oleh user_service.dart (untuk update ke Supabase)
  Map<String, dynamic> toJsonForUpdate() {
    return {
      'full_name': fullName,
      'photo_url': photoUrl,
      'default_tz': defaultTz,
      'ai_reminder_prefs': aiReminderPrefs,
    };
  }
}
