class VideoModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String channelTitle;

  VideoModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final snippet = json['snippet'];

    return VideoModel(
      id: json['id']['videoId'] as String,
      title: snippet['title'] as String,
      thumbnailUrl: snippet['thumbnails']['medium']['url'] as String,
      channelTitle: snippet['channelTitle'] as String,
    );
  }
}
