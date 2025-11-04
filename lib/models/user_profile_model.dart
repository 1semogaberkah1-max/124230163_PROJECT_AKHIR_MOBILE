class UserProfile {
  final String id;
  final String authUid;
  final String email;
  final String? fullName;
  final String? photoUrl;
  final String defaultTz;
  final DateTime createdAt;
  final List<String> aiReminderPrefs;

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
    final List<String> defaultCategories = [
      'Reminder Belajar',
      'Saran Materi',
      'Fakta Menarik',
      'Tips Belajar'
    ];

    final List<dynamic>? rawPrefs = json['ai_reminder_prefs'];
    final List<String> prefs = (rawPrefs != null && rawPrefs.isNotEmpty)
        ? List<String>.from(rawPrefs.where((e) => e != null))
        : defaultCategories;

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

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'full_name': fullName,
      'photo_url': photoUrl,
      'default_tz': defaultTz,
      'ai_reminder_prefs': aiReminderPrefs,
    };
  }
}
