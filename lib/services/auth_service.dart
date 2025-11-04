import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../pages/main_screen.dart';
import '../pages/login_screen.dart';
import 'user_service.dart';

class AuthService {
  final UserService _userService = UserService();

  Future<void> signUpUser({
    required String fullName,
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
        final userProfile = await _userService.getOrCreateUserProfile(
          response.user!,
          fullName: fullName,
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

          Navigator.of(context).pop();
        }
      }
    } on AuthException catch (e) {
      _showSnackbar(context, e.message, Colors.red);
    } catch (e) {
      _showSnackbar(context, 'Terjadi Kesalahan: ${e.toString()}', Colors.red);
    }
  }

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
