// File: lib/services/currency_service.dart

import 'dart:convert'; // Untuk jsonDecode
import 'package:http/http.dart' as http; // Untuk memanggil API
import 'package:flutter/foundation.dart'; // Untuk debugPrint
import '../core/constants.dart'; // Ambil API Key

class CurrencyService {
  // URL dasar API, kita minta kurs dengan basis IDR
  final String _baseUrl =
      'https://v6.exchangerate-api.com/v6/$exchangeRateApiKey/latest/IDR';

  // Map untuk cache sederhana agar tidak memanggil API setiap saat
  static Map<String, dynamic>? _cachedRates;
  static DateTime? _lastCacheTime;

  Future<Map<String, dynamic>?> getExchangeRates() async {
    // 1. Cek Cache
    // Jika data cache ada dan umurnya kurang dari 1 jam, gunakan cache
    if (_cachedRates != null &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!).inHours < 1) {
      debugPrint('Menggunakan kurs dari cache.');
      return _cachedRates;
    }

    // 2. Panggil API jika cache tidak valid
    try {
      debugPrint('Mengambil kurs baru dari API...');
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Cek jika API merespons dengan sukses
        if (data['result'] == 'success') {
          // Ambil bagian 'conversion_rates'
          final rates = data['conversion_rates'] as Map<String, dynamic>;

          // Simpan ke cache
          _cachedRates = rates;
          _lastCacheTime = DateTime.now();

          return rates;
        } else {
          // Tangani jika API key salah atau error lain dari API
          debugPrint('API Error: ${data['error-type']}');
          return null;
        }
      } else {
        // Tangani error server (404, 500, dll)
        debugPrint('Server Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Tangani error koneksi (timeout, tidak ada internet)
      debugPrint('Exception saat memanggil API: $e');
      return null;
    }
  }
}
