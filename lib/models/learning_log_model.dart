class LearningLog {
  final String id;
  final String userId;
  final String material;
  final int durationMin;
  final String? location;
  final int costIdr;
  final String? notes;
  final String timezone;
  final DateTime txnTimestamp;
  final String? photoUrl;

  LearningLog({
    required this.id,
    required this.userId,
    required this.material,
    required this.durationMin,
    this.location,
    required this.costIdr,
    this.notes,
    required this.timezone,
    required this.txnTimestamp,
    this.photoUrl,
  });

  factory LearningLog.fromSupabaseJson(Map<String, dynamic> json) {
    return LearningLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      material: json['material'] as String,
      durationMin: (json['duration_min'] as num).toInt(),
      location: json['location'] as String?,
      costIdr: (json['cost_idr'] as num).toInt(),
      notes: json['notes'] as String?,
      timezone: json['timezone'] as String,
      txnTimestamp: DateTime.parse(json['txn_timestamp']),
      photoUrl: json['photo_url'] as String?,
    );
  }

  static LearningLog fromGeminiJson({
    required Map<String, dynamic> json,
    required String userId,
    required String defaultTimezone,
    required DateTime currentTimestamp,
  }) {
    int duration =
        (json['duration_min'] ?? (json['duration_hours'] * 60) ?? 0).toInt();
    int cost = (json['food_cost_idr'] ?? json['cost_idr'] ?? 0).toInt();

    return LearningLog(
      id: '',
      userId: userId,
      material: json['activity'] ?? json['material'] ?? 'Belajar Tanpa Judul',
      durationMin: duration,
      location: json['location'],
      costIdr: cost,
      notes: json['notes'],
      timezone: json['timezone'] ?? defaultTimezone,
      txnTimestamp: currentTimestamp,
      photoUrl: null,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'user_id': userId,
      'material': material,
      'duration_min': durationMin,
      'location': location,
      'cost_idr': costIdr,
      'notes': notes,
      'timezone': timezone,
      'txn_timestamp': txnTimestamp.toIso8601String(),
      'photo_url': photoUrl,
    };
  }
}
