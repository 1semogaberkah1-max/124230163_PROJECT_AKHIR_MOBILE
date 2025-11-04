

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/video_model.dart';

class YoutubeService {
  final String _baseUrl = 'https:

  Future<List<VideoModel>> searchVideos(String query) async {
    
    final String searchQuery = 'tutorial $query';

    final Uri uri = Uri.parse(
      '$_baseUrl?part=snippet&q=$searchQuery&key=$youtubeApiKey&maxResults=5&type=video',
    );

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'];

        return items.map((item) => VideoModel.fromJson(item)).toList();
      } else {
        
        debugPrint('YouTube API Error: ${response.body}');
        return [];
      }
    } catch (e) {
      
      debugPrint('Exception saat memanggil YouTube API: $e');
      return [];
    }
  }
}
