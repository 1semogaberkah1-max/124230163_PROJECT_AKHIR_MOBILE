// File: lib/services/gemini_service.dart
// (VERSI LENGKAP DAN DIPERBAIKI)

import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../core/constants.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
      : _model =
            GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);

  // --- SEMUA PROMPT DIDEFINISIKAN DI SINI ---

  // 1. PROMPT PARSING (Dipindahkan ke atas)
  static const String _parsingPromptTemplate = '''
  Anda adalah parser data yang sangat akurat. Tugas Anda adalah mengubah teks laporan belajar pengguna menjadi format JSON.
  Jika informasi tidak tersedia, gunakan nilai null atau default yang relevan (misalnya 0 untuk biaya).
  Durasi harus diubah menjadi total menit (misal: "1 jam 30 menit" menjadi 90).

  FORMAT OUTPUT WAJIB JSON, TIDAK ADA TEKS TAMBAHAN APAPUN DI LUAR OBJEK JSON.
  
  Format JSON:
  {
    "material": "[Judul materi/kegiatan belajar]",
    "duration_min": [Durasi total dalam menit (int)],
    "location": "[Nama lokasi belajar, misal: Perpustakaan UI]",
    "cost_idr": [Biaya dalam IDR (int), 0 jika tidak ada],
    "notes": "[Catatan tambahan atau ringkasan]",
    "timezone": "[Zona waktu pengguna saat ini, gunakan WIB/WITA/WIT/London jika tidak disebut]",
    "timestamp": "[Waktu belajar, format YYYY-MM-DD HH:mm:ss Z]"
  }

  Teks Pengguna: 
  ''';

  // 2. PROMPT DETEKSI MAKSUD (Dipindahkan ke atas)
  static const String _intentPromptTemplate = '''
  Anda adalah AI klasifikasi. Tentukan maksud dari teks pengguna.
  Apakah teks tersebut adalah (A) Laporan input data belajar, atau (B) Pertanyaan tentang data.
  
  Contoh (A): "Tadi belajar 1 jam materi web", "Input: 2 jam flutter 50rb di kos", "catat belajar masak 30 menit"
  Contoh (B): "Berapa total biayaku?", "Aku belajar apa saja minggu ini?", "total durasi?"

  Jawab HANYA dengan kata "input" atau "pertanyaan".

  Teks Pengguna: 
  ''';

  // 3. PROMPT Q&A (Dipindahkan ke atas)
  static const String _qnaPromptTemplate = '''
  Anda adalah asisten belajar yang ramah. Berdasarkan data JSON berikut, jawab pertanyaan pengguna dalam Bahasa Indonesia yang singkat dan jelas.

  Data Rekap:
  {
    "recap": [RECAP_JSON],
    "top_materials": [TOP_MATERIALS_JSON]
  }

  Pertanyaan Pengguna:
  "[USER_QUESTION]"
  
  Jawaban Anda:
  ''';

  // 4. PROMPT ANALISIS REKAP (Sudah benar)
  static const String _analysisPromptTemplate = '''
  Anda adalah asisten analisis pembelajaran yang tugasnya menganalisis data rekap belajar pengguna dan memberikan saran yang konstruktif dan memotivasi.

  Analisis Anda harus mencakup:
  1. KESIMPULAN: Ringkasan singkat total durasi dan biaya.
  2. ANALISIS: Identifikasi tren (misal: Apakah biaya tinggi untuk durasi rendah? Apakah fokus hanya pada satu materi?).
  3. SARAN: Berikan 1-2 saran spesifik untuk meningkatkan efisiensi atau disiplin di minggu/bulan berikutnya.

  Gunakan Bahasa Indonesia yang ramah, profesional, dan memotivasi.

  Data Analisis:
  {
    "recap_total": [RECAP_TOTAL_JSON],
    "top_materials": [TOP_MATERIALS_JSON],
    "start_date": "[START_DATE]",
    "end_date": "[END_DATE]"
  }

  Jawaban Anda:
  ''';

  // --- FUNGSI HILANG: _getDefaultInstruction (DITAMBAHKAN) ---
  // (Dibutuhkan oleh getDailyReminder)
  String _getDefaultInstruction(String category) {
    switch (category) {
      case 'Reminder Belajar':
        return 'Ingatkan untuk mencatat atau menjadwalkan waktu belajar berikutnya.';
      case 'Saran Materi':
        return 'Berikan ide materi umum yang menarik untuk dipelajari.';
      case 'Fakta Menarik':
        return 'Berikan fakta ilmiah singkat tentang memori atau fokus.';
      case 'Tips Belajar':
        return 'Berikan satu tips praktis untuk meningkatkan sesi belajar.';
      default:
        // Kategori kustom akan menggunakan ini
        return 'Berikan pesan motivasi singkat terkait: $category';
    }
  }

  // --- FUNGSI HILANG: getDailyReminder (DITAMBAHKAN) ---
  // (Dibutuhkan oleh home_screen.dart)
  Future<String> getDailyReminder({
    String? userName,
    List<String>? aiReminderPrefs,
  }) async {
    final namePart = userName != null && userName.isNotEmpty
        ? 'Sebutkan nama pengguna ("$userName") di awal pesan Anda, seolah Anda adalah asisten pribadi yang akrab.'
        : 'Sapa pengguna dengan ramah tanpa menyebut nama.';

    final List<String> defaultCategories = [
      'Reminder Belajar',
      'Saran Materi',
      'Fakta Menarik',
      'Tips Belajar'
    ];
    final List<String> selectedCategories =
        (aiReminderPrefs != null && aiReminderPrefs.isNotEmpty)
            ? aiReminderPrefs.toSet().toList()
            : defaultCategories;

    final String categoryInstructions =
        selectedCategories.asMap().entries.map((entry) {
      final category = entry.value;
      final instruction = _getDefaultInstruction(category);
      return '${entry.key + 1}. $category: $instruction';
    }).join('\n');

    final categoryList = selectedCategories.join(', ');
    final categoryCount = selectedCategories.length;

    final prompt = '''
        Anda adalah asisten belajar yang akrab, komunikatif, dan harus mengikuti instruksi ini dengan ketat. Tugas Anda adalah memberikan pesan harian kepada pengguna.
        Pesan Anda harus memilih secara acak **satu** dari ${categoryCount} kategori yang telah diaktifkan berikut: ${categoryList}.
        
        Daftar Kategori yang Diaktifkan (Pilih 1 secara Acak):
        ${categoryInstructions}

        Format jawaban WAJIB: Sapaan akrab (hanya satu baris), diikuti dengan pesan inti dari kategori yang terpilih. Gunakan emoji yang relevan. ${namePart} Maksimal 30 kata.
        ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ??
          'Hai! Jangan lupa, istirahat yang cukup adalah bagian dari proses belajar lho! 😉';
    } catch (e) {
      debugPrint('Gemini Daily Reminder Error: $e');
      return 'Hai! Ada baiknya cek lagi log belajar hari ini. Terus semangat ya! 💪';
    }
  }

  // --- METHOD 1: handleDataInput (Optimized) ---
  Future<Map<String, dynamic>?> handleDataInput(
    String rawText,
    String userTimezone,
  ) async {
    // Prompt sudah dipindah ke atas
    final fullPrompt = _parsingPromptTemplate + rawText;

    try {
      final response = await _model.generateContent([Content.text(fullPrompt)]);

      if (response.text == null || response.text!.isEmpty) {
        debugPrint('Gemini Error: Response was null or empty.');
        return null;
      }

      String cleanJson =
          response.text!.replaceAll('```json', '').replaceAll('```', '').trim();

      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("Gemini Parsing Error (Catch Block): $e");
      return null;
    }
  }

  // --- METHOD 2: Motivasi (Tidak Berubah) ---
  Future<String> getMotivation() async {
    // (Fungsi ini tetap ada jika Anda ingin menggunakannya di tempat lain)
    const prompt =
        'Berikan satu kalimat singkat, padat, dan sangat memotivasi tentang pentingnya disiplin belajar dan mencapai tujuan. Sertakan satu emoji. Maksimal 15 kata.';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      }
      return 'Disiplin adalah jembatan antara tujuan dan pencapaian. ✨';
    } catch (e) {
      debugPrint('Gemini Motivation Error: $e');
      return 'Setiap langkah kecil membawamu lebih dekat ke tujuan. Semangat! 💪';
    }
  }

  // --- METHOD 3: detectIntent (Optimized) ---
  Future<String> detectIntent(String rawText) async {
    // Prompt sudah dipindah ke atas
    final fullPrompt = _intentPromptTemplate + rawText;
    try {
      final response = await _model.generateContent([Content.text(fullPrompt)]);
      final intent = response.text?.trim().toLowerCase() ?? 'input';

      if (intent == 'pertanyaan') {
        return 'pertanyaan';
      }
      return 'input';
    } catch (e) {
      debugPrint("Gemini Intent Error: $e");
      return 'input';
    }
  }

  // --- METHOD 4: answerQuestion (Optimized) ---
  Future<String> answerQuestion({
    required String userQuestion,
    required Map<String, dynamic>? recapData,
    required List<Map<String, dynamic>>? topMaterialsData,
  }) async {
    final String recapJson = jsonEncode(recapData ?? {});
    final String topMaterialsJson = jsonEncode(topMaterialsData ?? []);

    // Prompt sudah dipindah ke atas
    String fullPrompt = _qnaPromptTemplate
        .replaceAll('[RECAP_JSON]', recapJson)
        .replaceAll('[TOP_MATERIALS_JSON]', topMaterialsJson)
        .replaceAll('[USER_QUESTION]', userQuestion);

    try {
      final response = await _model.generateContent([Content.text(fullPrompt)]);
      return response.text ?? 'Maaf, saya tidak bisa memproses jawaban.';
    } catch (e) {
      debugPrint("Gemini Q&A Error: $e");
      return 'Terjadi kesalahan saat memproses jawaban: $e';
    }
  }

  // --- METHOD BARU: ANALISIS REKAP (getRecapAnalysis) ---
  // --- (LOGIKA DIPERBAIKI) ---
  Future<String?> getRecapAnalysis({
    required Map<String, dynamic>? recapTotal,
    required List<Map<String, dynamic>>? topMaterials,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // --- PERBAIKAN DI SINI ---
    // Ganti placeholder satu per satu, BUKAN menimpa semuanya
    String fullPrompt = _analysisPromptTemplate
        .replaceAll('[RECAP_TOTAL_JSON]', jsonEncode(recapTotal ?? {}))
        .replaceAll('[TOP_MATERIALS_JSON]', jsonEncode(topMaterials ?? []))
        .replaceAll('[START_DATE]', startDate.toIso8601String())
        .replaceAll('[END_DATE]', endDate.toIso8601String());
    // ------------------------

    try {
      final response = await _model.generateContent([Content.text(fullPrompt)]);
      return response.text;
    } catch (e) {
      debugPrint("Gemini Analysis Error: $e");
      return null; // Kembalikan null jika gagal
    }
  }
}
