// File: lib/screens/chatbot_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/gemini_service.dart';
import '../services/log_service.dart';
import '../services/user_service.dart';
import '../main.dart';
import '../models/learning_log_model.dart';
import '../models/user_profile_model.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _inputController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final LogService _logService = LogService();
  final UserService _userService = UserService();

  UserProfile? _currentUserProfile;
  bool _isLoading = true; // Set true saat loading profile
  String _parsedResult = 'Memuat data pengguna...';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _parsedResult =
            'Error: Sesi pengguna tidak ditemukan. Mohon Login ulang.';
        _isLoading = false;
      });
      return;
    }

    final profile = await _userService.getOrCreateUserProfile(user);

    setState(() {
      _currentUserProfile = profile;
      if (profile != null) {
        _parsedResult =
            'Masukkan laporan belajar ATAU ajukan pertanyaan...\n\nContoh pertanyaan:\n"Berapa total belajarku minggu ini?"\n"Materi apa yang paling sering kupelajari?"';
      } else {
        _parsedResult = 'Error: Gagal memuat ID Profil.';
      }
      _isLoading = false;
    });
  }

  // --- Fungsi Utama ---
  Future<void> _handleSubmission() async {
    final rawText = _inputController.text.trim();
    if (rawText.isEmpty || _currentUserProfile == null) return;

    setState(() {
      _isLoading = true;
      _parsedResult = 'Menganalisis maksud Anda...';
    });

    try {
      final String intent = await _geminiService.detectIntent(rawText);

      if (intent == 'input') {
        await _handleDataInput(rawText);
      } else {
        await _handleQuestion(rawText);
      }
    } catch (e) {
      debugPrint('Runtime Error saat handle submission: $e');
      _parsedResult = 'Terjadi kesalahan sistem: $e';
    } finally {
      setState(() {
        _isLoading = false;
        _inputController.clear();
      });
    }
  }

  // --- Logika Input Data ---
  Future<void> _handleDataInput(String rawText) async {
    setState(() {
      _parsedResult = 'Memahami laporan dan menyimpan data...';
    });

    final Map<String, dynamic>? parsedData =
        await _geminiService.handleDataInput(
      rawText,
      _currentUserProfile!.defaultTz,
    );

    if (parsedData != null) {
      final newLog = LearningLog.fromGeminiJson(
        json: parsedData,
        userId: _currentUserProfile!.id,
        defaultTimezone: _currentUserProfile!.defaultTz,
        currentTimestamp: DateTime.now(),
      );

      final isSuccess = await _logService.addLog(newLog);

      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final formattedJson = encoder.convert(parsedData);

      if (isSuccess) {
        _parsedResult = '✅ Log Berhasil Disimpan!\n\n${formattedJson}';
      } else {
        _parsedResult = '❌ Gagal Simpan Log.\n\n${formattedJson}';
      }
    } else {
      _parsedResult = 'Gagal memproses AI. Coba lagi.';
    }
  }

  // --- Logika Q&A ---
  Future<void> _handleQuestion(String userQuestion) async {
    setState(() {
      _parsedResult = 'Mengambil data rekap Anda...';
    });

    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 6));
    final endOfDay =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final recapData = await _logService.getRecap(
      startDate: startDate,
      endDate: endOfDay,
    );
    final topMaterialsData = await _logService.getTopMaterials(
      startDate: startDate,
      endDate: endOfDay,
    );

    setState(() {
      _parsedResult = 'Data rekap didapat. Menyiapkan jawaban...';
    });

    final String answer = await _geminiService.answerQuestion(
      userQuestion: userQuestion,
      recapData: recapData,
      topMaterialsData: topMaterialsData,
    );

    _parsedResult = answer;
  }

  @override
  Widget build(BuildContext context) {
    // --- AMBIL TEMA WARNA YANG AKTIF ---
    final ColorScheme colors = Theme.of(context).colorScheme;
    // ----------------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chatbot Laporan Belajar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  // --- PERBAIKAN UI DI SINI ---
                  decoration: BoxDecoration(
                    color: colors.surface, // Warna Card (Putih/Gelap)
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.primary.withOpacity(0.3)),
                  ),
                  child: SelectableText(
                    _parsedResult,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: colors.onSurface, // Warna Teks (Terang/Gelap)
                    ),
                  ),
                  // ---------------------------
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              enabled: !_isLoading && _currentUserProfile != null,
              decoration: InputDecoration(
                labelText: 'Tulis laporan atau pertanyaan...',
                // Style diambil dari tema
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : IconButton(
                        icon: Icon(Icons.send, color: colors.primary),
                        onPressed: (_currentUserProfile != null)
                            ? _handleSubmission
                            : null,
                      ),
              ),
              onSubmitted: (_) =>
                  (_currentUserProfile != null) ? _handleSubmission : null,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
