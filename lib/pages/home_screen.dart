// File: lib/pages/home_screen.dart
// VERSI GABUNGAN (Grid Menu + AI Reminder Harian)

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../services/gemini_service.dart';
import '../services/user_service.dart';
import '../models/user_profile_model.dart';

// --- IMPOR UNTUK SEMUA LAYAR DI GRID ---
import '../screens/chatbot_screen.dart';
import '../screens/log_list_screen.dart';
import '../screens/ai_settings_screen.dart';
import '../screens/manual_log_screen.dart';
import '../screens/recap_screen.dart';
import '../screens/reminder_screen.dart';
import '../screens/time_converter_screen.dart';
import '../services/auth_service.dart'; // Impor untuk Logout

// --- Class data untuk menu grid ---
class _MenuItem {
  final String title;
  final IconData icon;
  final Widget route;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GeminiService _geminiService = GeminiService();
  final UserService _userService = UserService();

  // MENGGUNAKAN LOGIKA BARU (getDailyReminder)
  late Future<String> _reminderFuture;

  UserProfile? _userProfile;
  bool _isLoadingProfile = true;

  // --- Daftar menu untuk GridView (DARI VERSI LAMA) ---
  final List<_MenuItem> _menuItems = [
    _MenuItem(
        title: 'Catat (AI)',
        icon: Icons.psychology_outlined,
        route: const ChatbotScreen()),
    _MenuItem(
        title: 'Catat (Manual)',
        icon: Icons.edit_document,
        route: const ManualLogScreen()),
    _MenuItem(
        title: 'Riwayat Laporan',
        icon: Icons.history_toggle_off,
        route: const LogListScreen()),
    _MenuItem(
        title: 'Rekap Statistik',
        icon: Icons.bar_chart,
        route: const RecapScreen()),
    _MenuItem(
        title: 'Atur Reminder',
        icon: Icons.alarm,
        route: const ReminderScreen()),
    _MenuItem(
        title: 'Konversi Waktu',
        icon: Icons.schedule,
        route: const TimeConverterScreen()),
  ];
  // ----------------------------------------------------

  @override
  void initState() {
    super.initState();
    // MENGGUNAKAN LOGIKA BARU
    _reminderFuture = Future.value('Memuat pengingat harian...');
    _fetchProfileAndMotivation();
  }

  // MENGGUNAKAN LOGIKA BARU
  Future<void> _fetchProfileAndMotivation() async {
    final user = supabase.auth.currentUser;

    if (mounted) {
      setState(() {
        _isLoadingProfile = true;
      });
    }

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _reminderFuture =
              Future.value('Yuk, mulai catat perjalanan belajarmu hari ini!');
        });
      }
      return;
    }

    final profile = await _userService.getOrCreateUserProfile(user);

    final name = profile?.fullName;
    final prefs = profile?.aiReminderPrefs;

    // Panggil getDailyReminder (BUKAN getMotivation)
    final reminderFuture = _geminiService.getDailyReminder(
      userName: name,
      aiReminderPrefs: prefs,
    );

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _reminderFuture = reminderFuture;
        _isLoadingProfile = false;
      });
    }
  }

  // MENGGUNAKAN LOGIKA BARU
  void _navigateToSettings() async {
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil pengguna belum dimuat, coba lagi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiSettingsScreen(userProfile: _userProfile!),
      ),
    );

    if (result == true) {
      await _fetchProfileAndMotivation();
    }
  }

  // MENGGUNAKAN LOGIKA BARU
  String get _displayName {
    if (_userProfile?.fullName != null && _userProfile!.fullName!.isNotEmpty) {
      return _userProfile!.fullName!;
    }
    return supabase.auth.currentUser?.email ?? 'Pengguna';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _displayName;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Belajar'),
        // Tombol Settings AI (DARI VERSI BARU)
        actions: [
          if (!_isLoadingProfile && _userProfile != null)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _navigateToSettings,
              tooltip: 'Pengaturan AI Reminder',
            ),
        ],
      ),
      // MENGGUNAKAN SingleChildScrollView AGAR RESPONSIF
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sapaan (DARI VERSI BARU)
              Text(
                'Halo, $displayName!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Selamat datang kembali di aplikasi pencatatan belajar Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Kotak Pengingat/Tips Harian (DARI VERSI BARU)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.primary.withOpacity(0.3)),
                ),
                child: FutureBuilder<String>(
                  future: _reminderFuture,
                  builder: (context, snapshot) {
                    if (_isLoadingProfile ||
                        snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Text(
                          'Memuat pengingat harian...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      );
                    } else if (snapshot.hasData) {
                      return Text(
                        '💡 ${snapshot.data!}',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                      );
                    } else {
                      return const Text('Gagal memuat tips harian.',
                          textAlign: TextAlign.center);
                    }
                  },
                ),
              ),

              const SizedBox(height: 40),

              // --- GridView Menu (DARI VERSI LAMA) ---
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12.0,
                crossAxisSpacing: 12.0,
                childAspectRatio: 1.1, // Rasio kartu menu
                children: _menuItems.map((item) {
                  return _buildMenuCard(context, item);
                }).toList(),
              ),
              // ----------------------------------------

              const SizedBox(height: 40),

              // Tombol Logout (DARI VERSI BARU)
              TextButton.icon(
                onPressed: () {
                  AuthService().signOutUser(context);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Kartu Menu (DARI VERSI LAMA, disesuaikan) ---
  Widget _buildMenuCard(BuildContext context, _MenuItem item) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    // Tentukan warna ikon
    final Color iconColor;
    if (item.title == 'Rekap Statistik') {
      iconColor = colors.secondary; // Warna aksen (Oranye)
    } else if (item.title == 'Catat (AI)') {
      iconColor = colors.primary; // Warna utama (Biru)
    } else {
      iconColor = colors.primary.withOpacity(0.8); // Sedikit beda
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => item.route),
        );
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        // CardTheme dari main.dart akan otomatis diterapkan
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(item.icon, size: 40.0, color: iconColor),
              const SizedBox(height: 12.0),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface, // Teks di atas card
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
