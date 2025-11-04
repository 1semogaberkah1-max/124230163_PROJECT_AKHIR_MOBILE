import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/constants.dart';

class CurrencyService {
  final String _baseUrl =
      'https://v6.exchangerate-api.com/v6/$exchangeRateApiKey/latest/IDR';

  static Map<String, dynamic>? _cachedRates;
  static DateTime? _lastCacheTime;

  Future<Map<String, dynamic>?> getExchangeRates() async {
    if (_cachedRates != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!).inHours < 1) {
      debugPrint('Menggunakan kurs dari cache.');
      return _cachedRates;
    }

    try {
      debugPrint('Mengambil kurs baru dari API...');
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] == 'success') {
          final rates = data['conversion_rates'] as Map<String, dynamic>;

          _cachedRates = rates;
          _lastCacheTime = DateTime.now();

          return rates;
        } else {
          debugPrint('API Error: ${data['error-type']}');
          return null;
        }
      } else {
        debugPrint('Server Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception saat memanggil API: $e');
      return null;
    }
  }
}
