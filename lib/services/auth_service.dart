// File: lib/services/auth_service.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../pages/main_screen.dart'; // Menggunakan MainScreen (Bottom Nav)
import '../pages/login_screen.dart';
import 'user_service.dart';

class AuthService {
  final UserService _userService = UserService();

  // --- FUNGSI BARU: signUpUser ---
  Future<void> signUpUser({
    required String fullName, // Menerima Nama Lengkap
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // PENTING: Buat profil di tabel 'users', mengirimkan fullName
        final userProfile = await _userService.getOrCreateUserProfile(
          response.user!,
          fullName: fullName, // Meneruskan Nama
        );

        if (userProfile == null) {
          throw Exception('Gagal membuat profil pengguna setelah sign up.');
        }

        if (context.mounted) {
          _showSnackbar(
            context,
            'Pendaftaran berhasil! Silakan login.',
            Colors.green,
          );
          // Kembali ke halaman Login
          Navigator.of(context).pop();
        }
      }
    } on AuthException catch (e) {
      _showSnackbar(context, e.message, Colors.red);
    } catch (e) {
      _showSnackbar(context, 'Terjadi Kesalahan: ${e.toString()}', Colors.red);
    }
  }
  // ------------------------------

  // FUNGSI signInUser (Diarahkan ke MainScreen)
  Future<void> signInUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final AuthResponse response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userProfile = await _userService.getOrCreateUserProfile(
          response.user!,
        );

        if (userProfile == null) {
          throw Exception('Gagal membuat/mengambil profil pengguna.');
        }

        if (context.mounted) {
          // --- Diarahkan ke MainScreen (Bottom Navigation) ---
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
          _showSnackbar(
            context,
            'Login Berhasil!',
            Colors.green,
          );
        }
      }
    } on AuthException catch (e) {
      _showSnackbar(context, e.message, Colors.red);
    } catch (e) {
      _showSnackbar(context, 'Terjadi Kesalahan: ${e.toString()}', Colors.red);
    }
  }

  // FUNGSI signOutUser
  Future<void> signOutUser(BuildContext context) async {
    try {
      await supabase.auth.signOut();

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        _showSnackbar(context, 'Anda telah keluar.', Colors.orange);
      }
    } on AuthException catch (e) {
      _showSnackbar(context, e.message, Colors.red);
    } catch (e) {
      _showSnackbar(context, 'Gagal Logout: ${e.toString()}', Colors.red);
    }
  }

  // METHOD _showSnackbar
  void _showSnackbar(BuildContext context, String message, Color color) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
