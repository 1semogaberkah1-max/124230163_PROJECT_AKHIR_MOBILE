class FeedbackModel {
  final String id;
  final String userId;
  final String? kesan;
  final String? saran;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    this.kesan,
    this.saran,
    required this.createdAt,
  });

  factory FeedbackModel.fromSupabaseJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      kesan: json['kesan'] as String?,
      saran: json['saran'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'user_id': userId,
      'kesan': kesan,
      'saran': saran,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseUpsertJson() {
    return {
      'user_id': userId,
      'kesan': kesan,
      'saran': saran,
    };
  }
}
