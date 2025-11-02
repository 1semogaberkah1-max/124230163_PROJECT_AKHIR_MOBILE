// File: lib/services/theme_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  final String key = "theme_mode";
  SharedPreferences? _prefs;
  late ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  ThemeNotifier() {
    _themeMode = ThemeMode.system; // Default
    _loadFromPrefs();
  }

  // Ganti tema dan simpan pilihan
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners(); // Beri tahu UI untuk update
    await _saveToPrefs(mode);
  }

  // Inisialisasi SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Muat pilihan dari memori
  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    final int? themeIndex = _prefs!.getInt(key);

    if (themeIndex == null) {
      _themeMode = ThemeMode.system;
    } else {
      _themeMode = ThemeMode.values[themeIndex];
    }
    notifyListeners();
  }

  // Simpan pilihan ke memori
  Future<void> _saveToPrefs(ThemeMode mode) async {
    await _initPrefs();
    _prefs!.setInt(key, mode.index);
  }
}
